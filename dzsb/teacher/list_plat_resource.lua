local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--判断参数是否正确
--版本
if tostring(args["scheme_id_int"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id_int参数错误！\"}")    
    return
end
--节点
if tostring(args["structure_id_int"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"structure_id_int参数错误！\"}")    
    return
end
--是否包含子节点
if tostring(args["cnode"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"cnode参数错误！\"}")    
    return
end
--类型：（学案，电子书，测试）
if tostring(args["resource_category"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"resource_category参数错误！\"}")    
    return
end
--排序类型（1:时间  2：大小  3：下载次数）
if tostring(args["order_type"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"order_type参数错误！\"}")    
    return
end
--排序方式（1:升序 2：降序）
if tostring(args["order_num"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"order_num参数错误！\"}")    
    return
end
--是否为根节点（1：是 0：否）
if tostring(args["order_num"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"order_num参数错误！\"}")    
    return
end
--显示范围  0全部
if tostring(args["view"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"view参数错误！\"}")    
    return
end
--每页显示条数
if tostring(args["page_size"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"page_size参数错误！\"}")    
    return
end
--当前页数
if tostring(args["page_num"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"page_num参数错误！\"}")    
    return
end

--参数赋值
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local scheme_id_int = tostring(args["scheme_id_int"])
local structure_id_int = tostring(args["structure_id_int"])
local cnode = tostring(args["cnode"])
local resource_category = tostring(args["resource_category"])
local order_type = tostring(args["order_type"])
local order_num = tostring(args["order_num"])
local keyword = tostring(args["keyword"])
local is_root = tostring(args["is_root"])
local view = tostring(args["view"])
local page_size = tostring(args["page_size"])
local page_num = tostring(args["page_num"])

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--关键字搜索
if keyword == "nil" then
	keyword = ""
else
	if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
		keyword = ""
    end	
end

--是否包含子节点
local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id_int,"..scheme_id_int..";"
    else
		structure_scheme = "filter=structure_id_int,"..structure_id_int..";"
    end
else
    if cnode == "0" then
        structure_scheme = "filter=structure_id_int,"..structure_id_int..";"
    else
        local sid = cache:get("node_"..structure_id_int)
        local sids = Split(sid,",")
        for i=1,#sids do
            structure_scheme = structure_scheme..sids[i]..","
        end
		structure_scheme = "filter=structure_id_int,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
    end
end

--升序还是降序
local asc_desc = ""
if order_num == "1" then
    asc_desc = "attr_asc"
else
    asc_desc = "attr_asc"
end 

--排序
local sort_filed = ""
if order_type == "1" then
    sort_filed = "sort="..asc_desc..":ts;"
elseif order_type == "2" then
	sort_filed = "sort="..asc_desc..":resource_size_int;"
else
	sort_filed = "sort="..asc_desc..":down_count;"
end

-- --资源类型
local str_rtype = ""
if resource_category ~= "0" then
    str_rtype = " filter=resource_category,"..resource_category..";"
end

-- 拼组的条件
local str_group = ""
if view == "0" then
    str_group = "IF(create_person="..cookie_person_id..",1,0) "
    -- local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
    -- for i=1,#group_list do
        -- str_group = str_group.." OR IF(group_id="..group_list[i]..",1,0)"
    -- end
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

local str_maxmatches = "10000"
local offset = page_size*page_num-page_size
local limit = page_size

local res = ""
res = db:query("SELECT SQL_NO_CACHE id FROM t_bag_resource_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=b_delete,0;".."select=("..str_group..") as match_qq;filter= match_qq, 1;"..sort_filed.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+page_size-1)/page_size)

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local resinfo_json = {}
for i=1,#res do
	local res_json = {}
    local res_info = ssdb_db:multi_hget("bag_res_"..res[i]["id"],"resource_title","person_name","file_id","create_time","down_count","resource_size")
	local resource_title = res_info[2]
	local person_name = res_info[4]
	local file_id = res_info[6]
	local create_time = res_info[8]
	local down_count = res_info[10]
	local resource_size = res_info[12]
	res_json["resource_title"] = res_info[2]
	res_json["person_name"] = res_info[4]
	res_json["file_id"] = res_info[6]
	res_json["create_time"] = res_info[8]
	res_json["down_count"] = res_info[10]
	res_json["resource_size"] = res_info[12]
	resinfo_json[i] = res_json
end

--返回的table
local result = {}

result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = page_num
result["pageSize"] = page_size
result["list"] = resinfo_json

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))



