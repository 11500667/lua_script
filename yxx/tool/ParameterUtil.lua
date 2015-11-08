
local ParameterUtil = {}

local function parseRequestData()
    local request_method = ngx.var.request_method;
    local args = nil;
    if "GET" == request_method then
        args = ngx.req.get_uri_args();
    else
        ngx.req.read_body();
        args = ngx.req.get_post_args();
    end
    ngx.ctx[ParameterUtil] = args;
    return ngx.ctx[ParameterUtil];
end

function ParameterUtil:getParameterData()
    return ngx.ctx[ParameterUtil] or parseRequestData()
end

function ParameterUtil:getStrParam(name,default)
    local param = parseRequestData()[name]
    if param == nil or param == ''  then
        param = default
    end
    return param
end

function ParameterUtil:getNumParam(name, default)
    local param = parseRequestData()[name]
    if param == nil then
        param = default
    end
    return param
end
return ParameterUtil;
