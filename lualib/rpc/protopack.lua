local skynet = require "skynet"

local M = {}

function M.pack(name, msg)
	local buf = skynet.call(".pbc", "lua", "encode", name, msg)
	local len = 2 + #name + 2 + #buf
	return string.pack(">Hs2s2", len, name, buf)
end

function M.unpack(data)
	local name, buf = string.unpack(">s2s2", data)
	local msg  = skynet.call(".pbc", "lua", "decode", name, buf)
	return name, msg
end

function M.decode(name, buf)
	local msg  = skynet.call(".pbc", "lua", "decode", name, buf)
    return msg
end

function M.encode(name, msg)
	local buf = skynet.call(".pbc", "lua", "encode", name, msg)
    return buf
end

return M
