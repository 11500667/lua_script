--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local preparationModel = require "yxx.preparation.teacher.model.YxModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
--  获取request的参数
local yx_name = parameterUtil:getStrParam("yx_name", "");
local person_id = parameterUtil:getStrParam("person_id", "");
local person_identity = parameterUtil:getStrParam("person_identity", "");
local subject_id = parameterUtil:getStrParam("subject_id", "");
local structure_id = parameterUtil:getStrParam("structure_id", "");
local sort_mode = parameterUtil:getStrParam("sort_mode", "");
local sort_type = parameterUtil:getStrParam("sort_type", "");
local is_root = parameterUtil:getStrParam("is_root", "");
local scheme_id = parameterUtil:getStrParam("scheme_id", "");
local cnode = parameterUtil:getStrParam("cnode", "");
local page_size = parameterUtil:getNumParam("page_size", 0);
local page_number = parameterUtil:getNumParam("page_number", 0);
if string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
if string.len(person_identity) == 0 then
    say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
if string.len(subject_id) == 0 then
    say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
if string.len(structure_id) == 0 then
    say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end
if page_size == 0 then
    say("{\"success\":false,\"info\":\"page_size参数错误！\"}")
    return
end
if page_number == 0 then
    say("{\"success\":false,\"info\":\"page_number参数错误！\"}")
    return
end
if string.len(sort_mode) == 0 then
    say("{\"success\":false,\"info\":\"sort_mode参数错误！\"}")
    return
end
if string.len(sort_type) == 0 then
    say("{\"success\":false,\"info\":\"sort_type参数错误！\"}")
    return
end
if string.len(is_root) == 0 then
    say("{\"success\":false,\"info\":\"is_root参数错误！\"}")
    return
end
if string.len(scheme_id) == 0 then
    say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end
if string.len(cnode) == 0 then
    say("{\"success\":false,\"info\":\"cnode参数错误！\"}")
    return
end
--关键字处理
if string.len(yx_name) > 0 then
    yx_name = ngx.decode_base64(yx_name) .. ";"
end


local return_json = preparationModel:yxList(yx_name,person_id, person_identity, subject_id, is_root, scheme_id, structure_id, sort_type, sort_mode, cnode, page_size, page_number);

cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);