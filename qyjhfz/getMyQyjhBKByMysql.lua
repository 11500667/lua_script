--[[
备课中心根据personID获取发布到大学区和协作体的备课[mysql版]
@Author  chenxg
@Date    2015-06-05
--]]
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
--应用类型
if args["beike_type"] == nil or args["beike_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"beike_type参数错误！\"}")
    return
end
local beike_type = args["beike_type"]
--工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]
--类型ID，1大学区，2协作体
if args["page_type"] == nil or args["page_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"page_type参数错误！\"}")
    return
end
local page_type = args["page_type"]
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
--按谁排序  1：上传时间  2：文件大小  3：下载次数
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
    asc_desc = "asc"    
else
    asc_desc = "desc"    
end 

--排序
local sort_filed = ""
if sort_type=="1" then
    sort_filed = "groupsort=ts "..asc_desc..";"    
elseif sort_type=="2" then
    sort_filed = "groupsort=resource_size_int "..asc_desc..";"    
elseif sort_type=="3" then
    sort_filed = "groupsort=down_count "..asc_desc..";"    
elseif sort_type=="4" then
    sort_filed = "groupsort=resource_type "..asc_desc..";"    
elseif sort_type=="5" then
    sort_filed = "groupsort=resource_format "..asc_desc..";"    
else
    sort_filed = "groupsort=resource_page "..asc_desc..";"    
end

--拼媒体类型条件
local bktype_str = ""
if beike_type ~= "0" then
	bktype_str = "filter=bk_type,"..beike_type..";"
end

--拼工作室条件
local workroom_str = ""
if workroom_id ~= "0" then
	if page_type == "1" then
		workroom_str = "filter=pub_target,"..workroom_id..";"
	elseif page_type == "2" then
		workroom_str = "filter=xzt_id,"..workroom_id..";"
	end
end

--拼删除条件
local delete_str = "filter=b_delete,0;"

--拼类型 4：备课
local objtype_str = "filter=obj_type,4;"

--拼人员ID条件
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local person_str = "filter=person_id,"..cookie_person_id..";"

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_resource_sphinxse WHERE query='"..keyword..bktype_str..workroom_str..structure_scheme..delete_str..objtype_str..person_str..sort_filed.."groupby=attr:obj_info_id;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_tab = {}
for i=1,#res do
	local resourceUtil = require "base.resource.model.ResourceUtil";
	--local resource_info = {}
    local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")	
	local resids = {}
	local ids = {}
	ids["id"]=iid
	resids[1] = ids
	local resource_infos = resourceUtil:getResourceInfoByIds(resids) 
	local resource_info = resource_infos[1]

	local xzt_id = cache:hget("publish_"..res[i]["id"],"xzt_id");
    local hd_id = cache:hget("publish_"..res[i]["id"],"hd_id");	
	--[[local resource_value = cache:hmget("resource_"..iid,"resource_id_int","resource_id_char","resource_title","resource_type_name","resource_type","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","width","height","person_id","material_type","for_urlencoder_url","for_iso_url","parent_structure_name","app_type_id","bk_type_name")
	resource_info["iid"] = iid
	resource_info["resource_id_int"] = resource_value[1]
	resource_info["resource_id_char"] = resource_value[2]
	resource_info["resource_title"] = resource_value[3]
	resource_info["resource_type_name"] = resource_value[4]
	resource_info["resource_type"] = resource_value[5]
	resource_info["resource_format"] = resource_value[6]
	resource_info["resource_page"] = resource_value[7]
	resource_info["resource_size"] = resource_value[8]
	resource_info["create_time"] = resource_value[9]
	resource_info["down_count"] = resource_value[10]
	resource_info["file_id"] = resource_value[11]
	resource_info["thumb_id"] = resource_value[12]
	resource_info["preview_status"] = resource_value[13]
	resource_info["structure_id"] = resource_value[14]
	resource_info["scheme_id_int"] = resource_value[15]
	resource_info["width"] = resource_value[16]
	resource_info["height"] = resource_value[17]
	resource_info["person_id"] = resource_value[18]
	resource_info["material_type"] = resource_value[19]
	resource_info["for_urlencoder_url"] = resource_value[20]
	resource_info["for_iso_url"] = resource_value[21]
	resource_info["parent_structure_name"] = resource_value[22]
	resource_info["app_type_id"] = resource_value[23]
	resource_info["bk_type_name"] = resource_value[24]
	resource_info["url_code"] = encodeURI(resource_value[3])
	--陈续刚20150701添加，显示上传人姓名和学校开始
	 --上传人，上传机构
	local person_id = resource_value[18]
	local person_name="--";
	local org_name = "";
	if person_id=="32" or person_id=="34" or person_id=="-1" or person_id=="0" then
		org_name = "未知";
		person_name="未知";
	elseif person_id =="1" then
		org_name = "东师理想";
		person_name="东师理想";
	else
		person_name = cache:hget("person_"..person_id.."_5","person_name");
		--根据人员id获得对应的组织机构名称 
		local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..person_id.."&identity_id=5")
		org_name = org_name_body.body
	end
	resource_info["person_name"] = person_name
	resource_info["org_name"] = org_name
	--陈续刚20150701添加，显示上传人姓名和学校结束
	--*****
	]]
	local xzt_name = ""
	local hd_name = ""
	if tostring(xzt_id) ~= "userdata: NULL" and xzt_id ~= "" and xzt_id ~="-1" then
		--ngx.log(ngx.ERR,"===******===>"..xzt_id.."<=====******=====")
		local xzt_sql = "select xzt_name from t_qyjh_xzt where xzt_id="..xzt_id
		local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
		if not xzt_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		xzt_name = xzt_result[1]["xzt_name"]
	end

	if tostring(hd_id) ~= "userdata: NULL" and hd_id~= "" and hd_id ~="-1" then
		local hd_sql = "select hd_name from t_qyjh_hd where hd_id="..hd_id
		local hd_result, err, errno, sqlstate = db:query(hd_sql);
		if not hd_result then
			ngx.say("{\"success\":false,\"info\":\"查询活动数据失败！\"}");
			return;
		end
		hd_name = hd_result[1]["hd_name"]
	end
	resource_info["xzt_name"]=xzt_name;
	resource_info["hd_name"]=hd_name;
	--*****
	
	resource_tab[i] = resource_info
	
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

