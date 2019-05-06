local modulename = "abtestingDiversionArgDomainName"

local _M = {}
local mt = { __index = _M}
_M._VERSION = "0.0.1"

local ERRORINFO = require('abtesting.error.errcode').info

local k_domainname     = 'domainname'
local k_domainname_set = 'domainname_set'
local k_upstream       = 'upstream'

_M.new = function(self, database, policyLib)
    if not database then
        error{ERRORINFO.PARAMETER_NONE, 'need available redis db'}
    end if not policyLib then
        error{ERRORINFO.PARAMETER_NONE, 'need available policy lib'}
    end

    self.database = database
    self.policyLib = policyLib
    return setmetatable(self, mt)
end

local isNULL = function(v)
    return v and v ~= ngx.null
end

_M.check = function(self, policy)
    for _, v in pairs(policy) do
        local domainname_set = v[k_domainname_set]
        local upstream = v[k_upstream]

        local v_domainname_set = domainname_set and(type(domainname_set) == 'table')
        local v_upstream = upstream and upstream ~= ngx.null

        if not v_domainname_set or not v_upstream then
            local info = ERRORINFO.POLICY_INVALID_ERROR
            local desc = ' k_domainname_set or k_upstream error'
            return {false, info, desc}
        end

        for _, domainname in pairs(domainname_set) do
            if not tostring(uid) then
                local info = ERRORINFO.POLICY_INVALID_ERROR
                local desc = 'domainname invalid, cannot convert to string'
            end
        end
    end

    return {true}
end

_M.set = function(self, policy)
    local database = self.database
    local policyLib = self.policyLib

    database:init_pipeline()
    for _, v in pairs(policy) do
        local domainname_set   = v[k_domainname_set]
        local upstream = v[k_upstream]
        for _, domainname in pairs(domainname_set) do
            database:hset(policyLib, domainname, upstream)
        end
    end

    local ok, err = database:commit_pipeline()
    if not ok then
        error{ERRORINFO.REDIS_ERROR, err}
    end
end

_M.get = function(self)
    local database = self.database
    local policyLib = self.policyLib

    local data, err = database:hgetall(policyLib)
    if not data then
        error{ERRORINFO.REDIS_ERROR, err}
    end

    return data
end

_M.getUpstream = function(self, domainname)
    if not tostring(domainname) then
        return nil
    end

    local database, key = self.database, self,policyLib

    local backend, err = database:hget(key, domainname)
    if not backend then error{ERRORINFO.REDIS_ERROR, err} end

    if backend == ngx.null then backend = nil end

    return backend
end

return _M
