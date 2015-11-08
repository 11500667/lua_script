local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--节点ID
if args["nid"] == nil or args["nid"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"nid参数错误！\"}")
    return
end
local nid = args["nid"]
--节点ID
if args["scheme_id"] == nil or args["scheme_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"scheme_id参数错误！\"}")
    return
end
local scheme_id = args["scheme_id"]
--工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]
--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]
--一页显示多少
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]
--搜索关键字
local keyword = tostring(args["keyword"])
if keyword =="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
	keyword = ""
    end
end
--是否包含子节点
if args["cnode"] == nil or args["cnode"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"cnode参数错误！\"}")
    return
end
local cnode = tostring(args["cnode"])
--是否是根节点
if args["is_root"] == nil or args["is_root"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"is_root参数错误！\"}")
    return
end
local is_root = tostring(args["is_root"])
--升序还是降序   1：ASC   2:DESC
if args["sort_num"] == nil or args["sort_num"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_num参数错误！\"}")
    return
end
local sort_num = tostring(args["sort_num"])
--按谁排序  1：教师  2：播放次数  3：平均分 4：时间
if args["sort_type"] == nil or args["sort_type"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_type参数错误！\"}")
    return
end
local sort_type = tostring(args["sort_type"])

local myPrime = require "resty.PRIME";
local cjson = require "cjson"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--转url_code
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--判断是否是根节点、是否包含子节点
local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id,"..scheme_id..";"
    else
		structure_scheme = "filter=structure_id,"..nid..";"
    end
else
    if cnode == "0" then
        structure_scheme = "filter=structure_id,"..nid..";"
    else
        local sid = cache:get("node_"..nid)
        local sids = Split(sid,",")
        for i=1,#sids do
            structure_scheme = structure_scheme..sids[i]..","
        end
      structure_scheme = "filter=structure_id,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
    end
end

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "sort=attr_asc:"    
else
    asc_desc = "sort=attr_desc:"    
end 

--排序
local sort_filed = ""
if sort_type=="1" then
    sort_filed = asc_desc.."teacher_name_py;"    
elseif sort_type=="2" then
    sort_filed = asc_desc.."play_count;"    
elseif sort_type=="3" then
    sort_filed = asc_desc.."score_average;"    
else
    sort_filed = asc_desc.."ts;"    
end

--拼工作室条件
local workroom_str = ""
if workroom_id ~= "0" then
	workroom_str = "filter=pub_target,"..workroom_id..";"
end

--拼删除条件
local delete_str = "filter=b_delete,0;"

--拼人员ID条件
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local person_str = "filter=person_id,"..cookie_person_id..";"

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_wk_sphinxse WHERE query='"..keyword..workroom_str..structure_scheme..delete_str..person_str..sort_filed.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_tab = {}
for i=1,#res do
	local res_tab = {}
    local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")	
	local wkds_value = cache:hmget("wkds_"..iid,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name", "study_instr","teacher_name","play_count","score_average","create_time","download_count","downloadable","person_id","table_pk","group_id","content_json")
	--获得缩略图id
	local thumb_id = ""
	local content_json = wkds_value[16]
	local aa = ngx.decode_base64(content_json)
	local data = cjson.decode(aa)
	if #data.sp_list~=0 then
		local resource_info_id = data.sp_list[1].id
		if resource_info_id ~= ngx.null then
			local thumbid = cache:hmget("resource_"..resource_info_id,"thumb_id")
			thumb_id = thumbid[1]
		end                              
	else
		thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end
	--获得微课位置				
	local structure_id = wkds_value[4]
	local curr_path = ""
	local structures = cache:zrange("structure_code_"..structure_id,0,-1)
	for i=1,#structures do
		local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
		curr_path = curr_path..structure_info[1].."->"
	end
	curr_path = string.sub(curr_path,0,#curr_path-2)
	
	res_tab["id"]=iid;
	res_tab["wkds_id_int"]=wkds_value[1];
	res_tab["wkds_id_char"]=wkds_value[2];
	res_tab["scheme_id_int"]=wkds_value[3];
	res_tab["structure_id"]=wkds_value[4];
	res_tab["wkds_name"]=wkds_value[5];
	res_tab["study_instr"]=wkds_value[6];
	res_tab["teacher_name"]=wkds_value[7];
	res_tab["play_count"]=wkds_value[8];
	res_tab["score_average"]=wkds_value[9];
	res_tab["create_time"]=wkds_value[10];
	res_tab["download_count"]=wkds_value[11];
	res_tab["thumb_id"]=thumb_id;
	res_tab["downloadable"]=wkds_value[12];
	res_tab["person_id"]=wkds_value[13];
	res_tab["table_pk"]=wkds_value[14];
	res_tab["group_id"]=wkds_value[15];
	res_tab["content_json"]=wkds_value[16];
	res_tab["parent_structure_name"]=curr_path;
	
	resource_tab[i] = res_tab
	
end

--放回到mysql连接池
db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resource_tab

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))

