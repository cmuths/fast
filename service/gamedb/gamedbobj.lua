local skynet = require "skynet"
local redis = require "skynet.db.redis"
local baseobj =  require "base.baseobj"


function NewGameDbObj(...)
    return CGameDb:New(...)
end

CGameDb = {}
CGameDb.__index = CGameDb
inherit(CGameDb, baseobj)

function CGameDb:New(mConfig, sDbName)
    local o = super(CGameDb).New(self)
    o.m_oClient = nil
    o.m_sDbName = sDbName
    o:Init(mConfig)
    return o
end

function CGameDb:Init(mConfig)
    local oClient = assert(redis.connect{
        host = mConfig.host,
        port = mConfig.port,
        db = mConfig.db or 0,
        auth = mConfig.auth,
    }, 'redis connect error')
    self.m_oClient = oClient
end

local function make_key(prefix, account)
    return string.format("%s:%u", prefix, account)
end

-- 用户数据最大的字节数
local MAX_USER_LEN = 10*1024

-- 获取用户数据
function CGameDb:GetUser(account)
    local key = make_key("user", account)
    local result = self.m_oClient:get(key)
    if result and #result > MAX_USER_LEN then
        return nil, "用户数据超过上限"
    end
    return result
end

-- 保存用户数据
function CGameDb:SetUser(account, value)
    local key = make_key("user", account)
    assert(self.m_oClient:set(key, value))
end
