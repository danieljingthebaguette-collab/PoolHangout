#!/usr/bin/env python3
"""Makes Pool!'s ball textures: one PNG per ball, wrapped on its sphere mesh in Studio (docs/MODELS.md, Balls).

Run from the project root, with Pillow and numpy (macOS's /usr/bin/python3 has both) and Roboto Condensed:
    python3 tools/BallTextures.py OUT_DIR --font FONT              every ball: ball0.png to ball15.png
    python3 tools/BallTextures.py OUT_DIR --font FONT 12 0         only these balls
    python3 tools/BallTextures.py OUT_DIR --font FONT grid         the test grid that checks the sphere's layout
    python3 tools/BallTextures.py OUT_DIR mesh                     sphere.obj, the balls' mesh, for Studio's Import 3D
FONT is Roboto Condensed Bold, or Google Fonts' variable Roboto Condensed (set to Bold here). Colors and sizes come
from Theme.luau through tools/BallLook.luau, so after changing them, run this again and upload the changed balls.

Every texture pixel is worked out from the point on the ball it lands on, so circles come out round and numbers
undistorted wherever the layout stretches the picture. Each pixel averages SAMPLES x SAMPLES points, for smooth edges.
"""

import argparse
import json
import math
import os
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SAMPLES = 4
GLYPH = 1024  # the number's drawing, in pixels across its circle

# How sphere.obj lays a texture out: u runs once round the ball's Y axis, starting at U_START turns from +Z toward
# +X and going that way if U_SIGN is 1, and v runs from the +Y pole (the top row) to -Y.
U_START = 0.0
U_SIGN = 1
# Studio's Import 3D turned the mesh half a turn round Y (the grid test, 2026-11-17), so the textures turn with it.
# The uploaded mesh was written with the layout above; don't change it without importing the mesh again.
IMPORT_TURN = 0.5
SEGMENTS, RINGS = 32, 16  # the mesh's slices round the ball and from pole to pole: about 1,000 triangles


def directions(width, height):
    """The point on a ball of radius 1 under each sample, as arrays x, y, z."""
    u = (np.arange(width * SAMPLES) + 0.5) / (width * SAMPLES)
    v = (np.arange(height * SAMPLES) + 0.5) / (height * SAMPLES)
    lon = 2 * math.pi * (U_START + IMPORT_TURN + U_SIGN * u)[None, :]
    lat = math.pi * (0.5 - v)[:, None]
    return np.cos(lat) * np.sin(lon), np.sin(lat) * np.ones_like(lon), np.cos(lat) * np.cos(lon)


def glyph(text, font_path, height_share, inside_share):
    """The text centered on a GLYPH x GLYPH square that spans its circle, as a 0-1 mask: ink where it's 1."""
    font = ImageFont.truetype(font_path, GLYPH)
    if font.get_variation_names():
        font.set_variation_by_name("Bold")
    big = Image.new("L", (GLYPH * 3, GLYPH * 2), 0)
    ImageDraw.Draw(big).text((GLYPH // 2, GLYPH // 2), text, font=font, fill=255)
    ink = big.crop(big.getbbox())
    # At most height_share of the circle tall, and small enough that the text's corners stay inside a circle
    # inside_share of the circle across, so they never touch the ring
    scale = min(height_share * GLYPH / ink.height, inside_share * GLYPH / math.hypot(ink.width, ink.height))
    ink = ink.resize((max(1, round(ink.width * scale)), max(1, round(ink.height * scale))), Image.LANCZOS)
    square = Image.new("L", (GLYPH, GLYPH), 0)
    square.paste(ink, ((GLYPH - ink.width) // 2, (GLYPH - ink.height) // 2))
    return np.asarray(square, dtype=np.float32) / 255


def circle_coords(x, y, z, center, up, radius):
    """Each point's place on a flat circle of `radius` printed at `center`, seen from outside with `up` up: (across,
    up), 1 at the circle's edge, and whether the point is on the circle's side of the ball."""
    cx, cy, cz = center
    ux, uy, uz = up
    # Right, as seen from outside looking in: up x center
    rx, ry, rz = uy * cz - uz * cy, uz * cx - ux * cz, ux * cy - uy * cx
    facing = x * cx + y * cy + z * cz > 0
    return (x * rx + y * ry + z * rz) / radius, (x * ux + y * uy + z * uz) / radius, facing


def stamp(rgb, mask, x, y, z, center, up, radius, ring, fill, ink, glyph_mask):
    """Paints a circle at `center` onto rgb: `fill` inside, an `ring`-thick `ink` ring (a share of its radius), and
    the glyph in ink."""
    across, upward, facing = circle_coords(x, y, z, center, up, radius)
    r = np.sqrt(across**2 + upward**2)
    inside = facing & (r <= 1)
    rgb[inside & mask] = fill
    rgb[inside & mask & (r > 1 - ring)] = ink
    if glyph_mask is not None:
        col = np.clip(((across + 1) / 2 * (GLYPH - 1)).round().astype(int), 0, GLYPH - 1)
        row = np.clip(((1 - upward) / 2 * (GLYPH - 1)).round().astype(int), 0, GLYPH - 1)
        on = inside & mask & (glyph_mask[row, col] > 0.5)
        rgb[on] = ink


def shrink(rgb):
    """Averages each SAMPLES x SAMPLES block into one pixel."""
    h, w, _ = rgb.shape
    return rgb.reshape(h // SAMPLES, SAMPLES, w // SAMPLES, SAMPLES, 3).mean(axis=(1, 3))


def ball(look, ball_id, font_path):
    marks = look["marks"]
    width = int(marks["TextureWidth"])
    x, y, z = directions(width, width // 2)
    every = np.ones(x.shape, dtype=bool)
    color = np.array(look["colors"][str(ball_id)], dtype=np.float32)
    cream = np.array(look["cream"], dtype=np.float32)
    ink = np.array(look["ink"], dtype=np.float32)
    rgb = np.empty(x.shape + (3,), dtype=np.float32)
    if ball_id == 0:
        rgb[:] = cream
        # Two roll dots on the Y axis
        rgb[np.abs(y) > math.sqrt(1 - (marks["DotDiameter"] / 2) ** 2)] = np.array(look["dot"], dtype=np.float32)
    elif ball_id >= 9:
        rgb[:] = cream
        rgb[np.abs(z) < marks["BandWidth"] / 2] = color
    else:
        rgb[:] = color
    if ball_id != 0:
        radius = marks["CircleDiameter"] / 2
        inside = 1 - marks["CircleRing"] / radius - marks["NumeralGap"]
        number = glyph(str(ball_id), font_path, marks["NumeralSize"], inside)
        for center in ((1, 0, 0), (-1, 0, 0)):
            stamp(rgb, every, x, y, z, center, (0, 1, 0), radius, marks["CircleRing"] / radius, cream, ink, number)
    return shrink(rgb)


def grid(look, font_path):
    """Lines every 30 degrees, a magenta seam at the texture's left and right edges, and a labeled circle on each axis,
    each label upright in the test's views (MODELS.md)."""
    width = int(look["marks"]["TextureWidth"])
    x, y, z = directions(width, width // 2)
    rgb = np.empty(x.shape + (3,), dtype=np.float32)
    rgb[:] = (235, 228, 210)
    lat = np.degrees(np.arcsin(np.clip(y, -1, 1)))
    lon = np.degrees(np.arctan2(x, z))
    near = lambda angle: np.abs((angle + 15) % 30 - 15) < 0.8  # noqa: E731
    rgb[near(lat) | near(lon)] = (120, 112, 100)
    u = (np.arange(x.shape[1]) + 0.5) / x.shape[1]
    rgb[:, (u < 0.012) | (u > 0.988)] = (230, 0, 200)
    ink = np.array(look["ink"], dtype=np.float32)
    every = np.ones(x.shape, dtype=bool)
    axes = [
        ("+X", (1, 0, 0), (0, 1, 0), (220, 40, 40)),
        ("-X", (-1, 0, 0), (0, 1, 0), (240, 150, 170)),
        ("+Y", (0, 1, 0), (0, 0, -1), (40, 170, 60)),
        ("-Y", (0, -1, 0), (0, 0, 1), (150, 160, 40)),
        ("+Z", (0, 0, 1), (0, 1, 0), (40, 80, 220)),
        ("-Z", (0, 0, -1), (0, 1, 0), (60, 200, 220)),
    ]
    for label, center, up, fill in axes:
        mask = glyph(label, font_path, 0.5, 0.8)
        stamp(rgb, every, x, y, z, center, up, 0.5, 0.06, np.array(fill, dtype=np.float32), ink, mask)
    return shrink(rgb)


def mesh(path):
    """A sphere of radius 1 as an OBJ file, its texture coordinates in the layout above. The seam's vertices are
    doubled so the texture wraps without a smear."""
    lines = ["# Pool!'s ball: a sphere of radius 1, written by tools/BallTextures.py"]
    for j in range(RINGS + 1):
        lat = math.pi * (0.5 - j / RINGS)
        for i in range(SEGMENTS + 1):
            u = i / SEGMENTS
            lon = 2 * math.pi * (U_START + U_SIGN * u)
            x, y, z = math.cos(lat) * math.sin(lon), math.sin(lat), math.cos(lat) * math.cos(lon)
            lines.append(f"v {x:.6f} {y:.6f} {z:.6f}")
            lines.append(f"vn {x:.6f} {y:.6f} {z:.6f}")
            # An OBJ's v counts up from the image's bottom row
            lines.append(f"vt {u:.6f} {1 - j / RINGS:.6f}")
    row = SEGMENTS + 1
    for j in range(RINGS):
        for i in range(SEGMENTS):
            # Corners seen from outside, counter-clockwise: top left, bottom left, bottom right, top right
            tl, bl, br, tr = j * row + i + 1, (j + 1) * row + i + 1, (j + 1) * row + i + 2, j * row + i + 2
            # Skip the triangle that shrinks to a point at each pole
            if j != RINGS - 1:
                lines.append(f"f {tl}/{tl}/{tl} {bl}/{bl}/{bl} {br}/{br}/{br}")
            if j != 0:
                lines.append(f"f {tl}/{tl}/{tl} {br}/{br}/{br} {tr}/{tr}/{tr}")
    with open(path, "w") as file:
        file.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Makes Pool!'s ball textures.")
    parser.add_argument("out", help="folder for the PNGs")
    parser.add_argument("items", nargs="*", help="ball ids, or grid; every ball if none")
    parser.add_argument("--font", help="Roboto Condensed Bold, or the variable Roboto Condensed")
    args = parser.parse_intermixed_args()
    os.makedirs(args.out, exist_ok=True)
    if args.items == ["mesh"]:
        mesh(os.path.join(args.out, "sphere.obj"))
        print("wrote", os.path.join(args.out, "sphere.obj"))
        return
    if not args.font:
        parser.error("textures need --font")
    look = json.loads(subprocess.run(["lune", "run", "tools/BallLook"], capture_output=True, text=True, check=True).stdout)
    for item in args.items or [str(i) for i in range(16)]:
        pixels = grid(look, args.font) if item == "grid" else ball(look, int(item), args.font)
        name = "grid.png" if item == "grid" else f"ball{int(item)}.png"
        Image.fromarray(pixels.round().astype(np.uint8)).save(os.path.join(args.out, name))
        print("wrote", os.path.join(args.out, name))


if __name__ == "__main__":
    main()
