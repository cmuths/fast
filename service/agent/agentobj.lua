local skynet = require "skynet"
local protopack = require "rpc.protopack"
local socket = require "skynet.socket"
local baseobj = require "base.baseobj"

function NewAgentObj(...)
    return CAgent:New(...)
end

CAgent = {}
CAgent.__index = CAgent
inherit(CAgent, baseobj)

function CAgent:New(fd, account)
    local o = setmetatable({}, self)
    o.m_fd = fd
    o.m_account = account
    o.m_player = nil
    o.m_changed = false  -- 标识m_player 是否有更改
    return o
end

-- 加载用户数据
function CAgent:LoadPlayer()
    local v, errmsg = skynet.call(".gamedb", "lua", "dbproxy", "GetUser", self.m_account)
    if not v then
        if errmsg then
            printf("LoadPlayer|load failed, account = %d, errmsg = %s", self.m_account, errmsg)
            return false, errmsg
        end
        -- 初始化用户数据
        self.m_player = {account = self.m_account}
        printf("LoadPlayer|account = %d init", self.m_account)
        self.m_changed = true
    else
        self.m_player = protopack.decode("User", v)
        assert(self.m_player.account == self.m_account)
        printf("LoadPlayer|account = %d loaded", self.m_account)
    end

    return true
end

-- 用户数据落地
function CAgent:DumpPlayer()
    assert(self.m_changed)
    assert(self.m_player.account == self.m_account,
        string.format("DumpPlayer|ERROR, m_player.account = %u, account = %u", self.m_player.account, self.m_account))

    local v = protopack.encode("User", self.m_player)
    printf("DumpPlayer|account = %u", self.m_account)
    skynet.call(".gamedb", "lua", "dbproxy", "SetUser", self.m_account, v)
end


-- 发消息给客户端
function CAgent:SendMessage(name, msg)
	local data = protopack.pack(name, msg)
	socket.write(self.m_fd, data)
end

-- 分发命令
function CAgent:Dispatch(name, msg)
    local func = "On" .. name
    printf("CAgent.Dispatch|%s, account = %u", func, self.m_account)
    if not self[func] then
        printf('agent, account = %d, Dispatch failed, name = %s', self.m_account, name)
        return
    end
    self[func](self, msg)
    if self.m_changed then
        self:DumpPlayer()
        self.m_changed = false
    end
end

----------- 逻辑处理 ---------------
function CAgent:OnGetUserReq(msg)
    local resp = {
        head = {result = 0, errmsg = "succ"},
        user = self.m_player,
    }
    self:SendMessage("GetUserRsp", resp)
end

return CAgent
