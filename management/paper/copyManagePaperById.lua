-- -----------------------------------------------------------------------------------
-- 描述：试卷后台管理 -> 试卷复制
-- 作者：刘全锋
-- 日期：2015年12月14日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method;
local cjson = require "cjson";


local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();


local structure_id = tostring(args["structure_id"])
--判断是否有显示类型参数
if structure_id == "nil" or structure_id == "" then
    ngx.say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end

local version_id = tostring(args["version_id"]);
--判断是否有显示类型参数
if version_id == "nil" or version_id == "" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end

local curr_path = ""

local structures = cache:zrange("structure_code_"..structure_id,0,-1);

for j=1,#structures do
    local structure_info = cache:hmget("t_resource_structure_"..structures[j],"structure_name")
    curr_path = curr_path..structure_info[1].."->"
end
curr_path = string.sub(curr_path,0,#curr_path-2)



local ids = tostring(args["ids"])
--判断是否有显示类型参数
if ids == "nil" or ids == "" then
    ngx.say("{\"success\":false,\"info\":\"ids参数错误！\"}")
    return
end

local ids_table = Split(ids,",");



for i=1,#ids_table do
    local sql = "insert into t_sjk_paper_info(paper_name,scheme_id,structure_id,structure_code,question_count,paper_type,person_id,identity_id,create_time,ts,update_ts,json_content,paper_page,preview_status,file_id,for_urlencoder_url,for_iso_url,parent_structure_na,source_id,extension,group_id,resource_info_id,down_count,b_delete,oper_type,stage_id,subject_id,paper_app_type,paper_app_type_name) select paper_name,"..tonumber(version_id)..","..tonumber(structure_id)..",structure_code,question_count,paper_type,person_id,identity_id,create_time,ts,update_ts,json_content,paper_page,preview_status,file_id,for_urlencoder_url,for_iso_url,parent_structure_na,source_id,extension,group_id,resource_info_id,down_count,b_delete,oper_type,stage_id,subject_id,paper_app_type,paper_app_type_name from t_sjk_paper_info where id="..ids_table[i];

    local res, err, errno, sqlstate =db:query(sql);
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return false;
    end

end




local returnjson={};
returnjson.success = true;
returnjson.info = "试卷复制成功！";


ngx.say(encodeJson(returnjson));

