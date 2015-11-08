-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询需要审核试题列表
-- 作者：刘全锋
-- 日期：2015年8月28日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"


local check_status = args["check_status"] 
local version_id = args["version_id"]
local all_version_ids = args["all_version_ids"]
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]

	
--判断是否有check_status参数
if check_status == nil  then
    ngx.say("{\"success\":false,\"info\":\"check_status参数错误！\"}")
    return
end


--判断是否有version_id参数
if version_id==nil or version_id =="" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end


-- 判断是否有all_version_ids参数
if all_version_ids==nil or all_version_ids =="" then
    ngx.say("{\"success\":false,\"info\":\"all_version_ids参数错误！\"}")
    return
end


-- 判断是否有pageNumber参数
if pageNumber==nil or pageNumber =="" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end


-- 判断是否有pageSize参数
if pageSize == nil or pageSize =="" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

local versionStr = "";

if version_id == "0" then
    versionStr = all_version_ids;
else
    versionStr = version_id;
end


local statusStr = "";

if check_status==""  then
    statusStr = "1,2,3";
else
    statusStr = check_status;
end



local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100


local sql = "SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'filter=b_in_paper,0;filter=b_delete,0;filter=group_id,2;filter=check_status,"..statusStr..";filter=scheme_id_int,"..versionStr..";maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;"

local res = db:query(sql);


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local strucService  = require "base.structure.services.StructureService";
local question_info = ""
for i=1,#res do

    local question_json = tostring(cache:hmget("question_"..res[i]["id"],"json_question")[1])

    if question_json ~= "userdata: NULL" and question_json ~= "" then
        local jsonQuesObj = cjson.decode(ngx.decode_base64(question_json));
        local strucIdInt  = jsonQuesObj["structure_id"];
        local strucPath   = strucService: getStrucPath(strucIdInt);
        jsonQuesObj["structure_path"] = strucPath;

        local jsonEncodeStr = cjson.encode(jsonQuesObj);

        local create_person = tostring(cache:hmget("question_"..res[i]["id"],"create_person")[1])
        question_info = question_info .. "{\"id\":\"" .. res[i]["id"] .. "\",\"json_question\":" .. jsonEncodeStr .. ",\"create_person\":\"".. create_person .."\"},"
    end
end
question_info = string.sub(question_info,0,#question_info-1);


--放回连接池
cache:set_keepalive(0,v_pool_size);
DBUtil: keepDbAlive(db);


ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")
