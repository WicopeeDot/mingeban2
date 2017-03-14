
mingeban.utils = {}
function mingeban.utils.checkParam(param, typ, num, fnName)
	assert(type(param) == typ, "bad argument #" .. tostring(num) .. " to '" .. fnName .. "' (" .. typ .. " expected, got " .. type(param) .. ")")
end

