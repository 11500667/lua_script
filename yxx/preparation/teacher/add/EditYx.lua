local say = ngx.say;
local cjson = require "cjson";
local SSDBUtil = require "yxx.tool.SSDBUtil";
local parameterUtil = require "yxx.tool.ParameterUtil";
local yx_id = parameterUtil:getStrParam("yx_id","");
if  not yx_id or string.len(yx_id) == 0 then
    say("{\"success\":false,\"info\":\"yx_id都不能为空\"}");
    return
end
local preparation_table = SSDBUtil:hget("preparation_yx_info",yx_id);
cjson.encode_empty_table_as_object(false);
say(preparation_table);