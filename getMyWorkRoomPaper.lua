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
--人员ID
local cookie_person_id = tostring(ngx.var.cookie_person_id)
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
--按谁排序  1：上传时间  2：文件大小  3：下载次数
if args["sort_type"] == nil or args["sort_type"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_type参数错误！\"}")
    return
end
local sort_type = tostring(args["sort_type"])

local cjson = require "cjson"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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
    sort_filed = asc_desc.."ts;"
end

--拼工作室条件
local workroom_str = ""
if workroom_id ~= "0" then
	workroom_str = "filter=pub_target,"..workroom_id..";"
end

--拼删除条件
local delete_str = "filter=b_delete,0;"

--拼类型 3：试卷
local objtype_str = "filter=obj_type,3;"

--拼人员ID条件
local person_str = "filter=person_id,"..cookie_person_id..";"


local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"


local res = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_paper_sphinxse WHERE query='"..keyword..workroom_str..structure_scheme..delete_str..person_str..sort_filed.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_tab = {}
for i=1,#res do
	local resource_info = {}
	ngx.log(ngx.ERR,"@@@@@@@@@"..res[i]["id"].."@@@@@@@@@")
    local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
	ngx.log(ngx.ERR,"@@@@@@@@@"..iid.."@@@@@@@@@")
	local paper_value = cache:hmget("paper_"..iid,"paper_id_char","paper_name","question_count","create_time","paper_type","extension","parent_structure_name","paper_id_int","person_id","resource_info_id")
	resource_info["iid"] = iid
	resource_info["paper_id"] = paper_value[1]
	resource_info["paper_name"] = paper_value[2]
	resource_info["ti_num"] = paper_value[3]
	resource_info["create_time"] = paper_value[4]
	resource_info["paper_source"] = paper_value[5]
	resource_info["extenstion"] = paper_value[6]
	resource_info["parent_structure_name"] = paper_value[7]
	resource_info["paper_id_int"] = paper_value[8]
	resource_info["person_id"] =paper_value[9]
	resource_info["paper_id_char"] =paper_value[1]
	ngx.log(ngx.ERR,"@@@@@@@@@"..paper_value[9].."@@@@@@@@@")
	--local resource_value = cache:hmget("resource_"..paper_value[10],"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
	local resource_value = ssdb:multi_hget("resource_"..paper_value[10],"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
	resource_info["preview_status"] =resource_value[2]
	resource_info["for_iso_url"] =resource_value[4]
	resource_info["for_urlencoder_url"] =resource_value[6]
	resource_info["file_id"] =resource_value[8]
	resource_info["page"] =resource_value[10]
	resource_info["structure_id_int"] =resource_value[12]
	resource_info["scheme_id_int"] =resource_value[14]
	resource_tab[i] = resource_info
	
end

--放回到mysql连接池
db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resource_tab

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))

