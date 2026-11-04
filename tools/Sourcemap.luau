-- Writes sourcemap.json: the place's scripts as Script Sync mirrors src/ into Studio, so luau-lsp can follow instance
-- requires like require(ReplicatedStorage.Shared.Config). .claude/hooks/check.sh runs it before the type check.
-- Run from the repo root: lune run tools/Sourcemap
local fs = require("@lune/fs")
local serde = require("@lune/serde")

type Node = { name: string, className: string, filePaths: { string }?, children: { Node }? }

-- File names set the script type, as CLAUDE.md says. The longer endings are checked first.
local KINDS = { { ".server.luau", "Script" }, { ".local.luau", "LocalScript" }, { ".luau", "ModuleScript" } }

local function node(path: string, name: string): Node?
	if fs.isDir(path) then
		local children = {}
		local names = fs.readDir(path)
		table.sort(names)
		for _, child in names do
			local childNode = node(`{path}/{child}`, child)
			if childNode then
				table.insert(children, childNode)
			end
		end
		return { name = name, className = "Folder", children = children }
	end
	for _, kind in KINDS do
		local ending, className = kind[1], kind[2]
		if name:sub(-#ending) == ending then
			return { name = name:sub(1, -#ending - 1), className = className, filePaths = { path } }
		end
	end
	return nil
end

local function holder(className: string, child: Node?): Node
	return { name = className, className = className, children = { child :: Node } }
end

local tree: Node = {
	name = "Game",
	className = "DataModel",
	children = {
		holder("ReplicatedStorage", node("src/Shared", "Shared")),
		holder("ServerScriptService", node("src/Server", "Server")),
		holder("StarterPlayer", holder("StarterPlayerScripts", node("src/Client", "Client"))),
	},
}
fs.writeFile("sourcemap.json", serde.encode("json", tree))
