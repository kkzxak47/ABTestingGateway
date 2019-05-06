local _M = {
    _VERSION = '0.0.1'
}

_M.get = function()
    local h = ngx.var.host
    return h
end
return _M
