--[[
根据区域均衡ID获取区域均衡首页的信息
@Author  chenxg
@Date    2015-01-27
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local returnjson = {}
--参数 
local qyjh_id = args["qyjh_id"]


--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取区域均衡统计信息开始
local dxq_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"dxq_tj")
local xzt_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"xzt_tj")
local xx_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"xx_tj")
local js_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"js_tj")
local hd_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"hd_tj")
local zy_tj = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"zy_tj")
--获取区域均衡统计信息结束
--根据区域均衡ID获取按照点击量排行的前6个大学区开始
local tdxqids = ssdb:zrrange("qyjh_dxq_djl_"..qyjh_id,0,6)
local dxqids = {}
local dxqs = {}
if #tdxqids>=2 then
	for i=1,#tdxqids,2 do
		table.insert(dxqids,tdxqids[i])
	end
	local dxqlist, err = ssdb:multi_hget('qyjh_dxq',unpack(dxqids));
	for i=2,#dxqlist,2 do
		--table.insert(dxqs,dxqlist[i])
		local t = cjson.decode(dxqlist[i])
		dxqs[#dxqs+1] = t
	end
end
returnjson.dxq_list = dxqs
--根据区域均衡ID获取按照点击量排行的前6个大学区结束

--根据下载数量获取资源列表开始
--UFT_CODE
local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--根据下载排行获取资源【资源、备课】
local resource_new_tab= {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;groupsort=DOWN_COUNT desc;limit=6'")
for i=1,#res do
	local  res_new_tab = {}
	local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
	ngx.log(ngx.ERR, "===sql===> " .. res[i]["id"] .."**"..qyjh_id .. " <===sql===");
	local  res_info = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int","scheme_id_int","create_time","resource_id_int")
	--根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb:hget("t_resource_scheme_"..res_info[14],"subject_name")[1]
    local subject_id = ssdb:hget("t_resource_scheme_"..res_info[14],"subject_id")[1]
	res_new_tab["iid"] = iid
	res_new_tab["resource_title"] = res_info[1]
	res_new_tab["resource_format"] = res_info[2]
	res_new_tab["resource_page"] = res_info[3]
	res_new_tab["file_id"] = res_info[4]
	res_new_tab["thumb_id"] = res_info[5]
	res_new_tab["preview_status"] = res_info[6]
	res_new_tab["width"] = res_info[7]
	res_new_tab["height"] = res_info[8]
	res_new_tab["for_urlencoder_url"] = res_info[9]
	res_new_tab["for_iso_url"] = res_info[10]
	res_new_tab["res_type"] = res_info[11]
	res_new_tab["beike_type"] = res_info[12]
	res_new_tab["resource_size_int"] = res_info[13]
	res_new_tab["url_code"] = urlEncode(res_info[1])
	res_new_tab["subject_name"] = subject_name
	res_new_tab["subject_id"] = subject_id
	res_new_tab["create_time"] = res_info[15]
	res_new_tab["resource_id_int"] = res_info[16]
	resource_new_tab[i] = res_new_tab
end
returnjson["resource_hot"] = resource_new_tab

--根据下载数量获取资源列表结束

--获取最新的活动开始 陈续刚2015-02-09添加
local hdlist
local params = "?page_type=1&hd_type=0&path_id="..qyjh_id.."&pageSize=3&pageNumber=1"
local res_org = ngx.location.capture("/dsideal_yy/qyjh/getHdByParams"..params)

if res_org.status == 200 then
	hdlist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询活动失败！\"}")
	return
end
returnjson.hd_list = hdlist.hd_list
--获取最新的活动结束

returnjson.success = "true"
returnjson.dxq_tj = dxq_tj[1]
returnjson.xzt_tj = xzt_tj[1]
returnjson.xx_tj = xx_tj[1]
returnjson.js_tj = js_tj[1]
returnjson.hd_tj = hd_tj[1]
returnjson.zy_tj = zy_tj[1]

say(cjson.encode(returnjson))
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)