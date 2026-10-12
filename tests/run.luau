--!strict
-- Lune test runner. Run it from the project root:
--     lune run tests/run            every test
--     lune run tests/run physics    only spec files whose path contains "physics"
--
-- It runs every tests/**/*.spec.luau file. A spec file requires the module it
-- tests by relative path and returns a function that receives `test` and `check`:
--
--     local EightBall = require("../src/Shared/Rules/EightBall")
--
--     return function(test, check)
--         test("sinking the cue ball with the 8 loses", function()
--             local outcome = ... -- set up a game and resolve a shot
--             check.equal(outcome.winner, "B")
--         end)
--     end

local fs = require("@lune/fs")
local process = require("@lune/process")

local function label(message: string?): string
	return if message then message .. ": " else ""
end

local check = {}

function check.truthy(value: any, message: string?)
	if not value then
		error(label(message) .. "expected a truthy value, got " .. tostring(value), 2)
	end
end

function check.equal(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(label(message) .. "expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

function check.near(actual: number, expected: number, tolerance: number, message: string?)
	if math.abs(actual - expected) > tolerance then
		error(label(message) .. `expected {expected} ± {tolerance}, got {actual}`, 2)
	end
end

function check.errors(fn: () -> (), message: string?)
	if pcall(fn) then
		error(label(message) .. "expected an error, but none was raised", 2)
	end
end

type Test = { name: string, fn: () -> () }
type Spec = (test: (name: string, fn: () -> ()) -> (), check: typeof(check)) -> ()

local root = process.cwd
if string.sub(root, -1) ~= "/" and string.sub(root, -1) ~= "\\" then
	root ..= "/"
end

-- Turns absolute paths in an error line into project-relative ones.
local function stripRoot(line: string): string
	local start, finish = string.find(line, root, 1, true)
	while start do
		line = string.sub(line, 1, start - 1) .. string.sub(line, finish + 1)
		start, finish = string.find(line, root, 1, true)
	end
	return line
end

-- Keeps a failure's message and the spec lines that led to it, minus this
-- runner's own frames.
local function cleanTrace(trace: string): string
	local lines: { string } = {}
	for line in string.gmatch(trace, "[^\n]+") do
		line = stripRoot(line)
		if not string.find(line, "tests/run:", 1, true) and string.find(line, "%S") then
			table.insert(lines, "    " .. line)
		end
	end
	return table.concat(lines, "\n")
end

if not fs.isDir("tests") then
	print("Run this from the project root: lune run tests/run")
	process.exit(1)
end

local specPaths: { string } = {}

local function collect(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			collect(path)
		elseif string.sub(name, -10) == ".spec.luau" then
			table.insert(specPaths, path)
		end
	end
end

collect("tests")
table.sort(specPaths)

local filter: string? = process.args[1]
local passed, failed, files = 0, 0, 0
local failures: { string } = {}
local started = os.clock()

for _, path in specPaths do
	if filter and not string.find(path, filter, 1, true) then
		continue
	end
	files += 1

	-- "tests/physics.spec.luau" -> "./physics.spec", relative to this file
	local modulePath = "./" .. string.sub(path, #"tests/" + 1, -#".luau" - 1)
	local loaded, spec = pcall(function()
		return (require :: any)(modulePath)
	end)
	if not loaded or type(spec) ~= "function" then
		failed += 1
		local reason = if loaded
			then "it must return a function"
			else stripRoot(string.match(tostring(spec), "[^\n]+") or "")
		table.insert(failures, path .. "\n    couldn't load: " .. reason)
		continue
	end

	local tests: { Test } = {}
	local registered, registerError = pcall(spec :: Spec, function(name: string, fn: () -> ())
		table.insert(tests, { name = name, fn = fn })
	end, check)
	if not registered then
		failed += 1
		table.insert(failures, path .. "\n    error while registering tests: " .. tostring(registerError))
		continue
	end

	for _, t in tests do
		local ok, err = xpcall(t.fn, function(e)
			return debug.traceback(tostring(e), 2)
		end)
		if ok then
			passed += 1
		else
			failed += 1
			table.insert(failures, path .. " > " .. t.name .. "\n" .. cleanTrace(tostring(err)))
		end
	end
end

if files == 0 then
	print(if filter then `No spec files match "{filter}".` else "No tests yet. Add tests/<name>.spec.luau files.")
	process.exit(0)
end

for _, failure in failures do
	print("FAIL " .. failure .. "\n")
end
print(
	string.format(
		"%d passed, %d failed (%d %s, %.2f s)",
		passed,
		failed,
		files,
		if files == 1 then "file" else "files",
		os.clock() - started
	)
)
process.exit(if failed > 0 then 1 else 0)
