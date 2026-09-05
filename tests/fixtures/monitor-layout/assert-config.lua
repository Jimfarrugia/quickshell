package.preload["config.system"] = function()
	return { hostname = os.getenv("TEST_HOSTNAME") or "jim-x1c", is_vm = false }
end

local monitors = {}
hl = {
	monitor = function(value)
		monitors[#monitors + 1] = value
	end,
}

dofile(assert(os.getenv("MONITORS_CONFIG")))
assert(#monitors == tonumber(os.getenv("EXPECTED_COUNT")))

local monitor = monitors[tonumber(os.getenv("EXPECTED_INDEX"))]
assert(monitor.output == os.getenv("EXPECTED_OUTPUT"))
assert(tostring(monitor.position) == os.getenv("EXPECTED_POSITION"))
assert(tonumber(monitor.scale) == tonumber(os.getenv("EXPECTED_SCALE")))
assert((monitor.mirror or "") == os.getenv("EXPECTED_MIRROR"))
