--[[
记录教师、学校、大学区、协作体资源上传数量
@Author  chenxg
@Date    2015-02-05
--]]

local say = ngx.say
local len = string.len
local gsub = string.gsub

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
--参数
--当前用户ID
local person_id = args["person_id"]
--区域均衡ID
local qyjh_id = args["qyjh_id"]
--当前用户所在学校ID
local org_id = args["org_id"]
--增加上传数量的大学区ID
local add_dxq_ids = args["add_dxq_ids"]
--增加上传数量的协作体IDs
local add_xzt_ids = args["add_xzt_ids"]
--删除上传数量的大学区IDs
local del_dxq_ids = args["del_dxq_ids"]
--删除上传数量的协作体IDs
local del_xzt_ids = args["del_xzt_ids"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0
	or not qyjh_id or len(qyjh_id) == 0
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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

local identity_id = tostring(ngx.var.cookie_identity_id)
local org_id = redis:hget("person_"..person_id.."_"..identity_id, "xiao")
--******************************************
--=======发布到大学区
add_dxq_ids = gsub(add_dxq_ids, "[%[%]\" ]", "")
if add_dxq_ids and len(add_dxq_ids) > 0 then
	local adddxqids = Split(add_dxq_ids, ",")
	for i=1,#adddxqids do
		--学校在区域均衡的上传量加1
		local a = ssdb:zget("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id)
		if a then 
			ssdb:zset("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,0)
		end
		ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,1)
		--学校在大学区的上传量加1
		ssdb:zincr("qyjh_dxq_org_uploadcount_"..adddxqids[i],org_id,1)
		--教师在区域均衡上传量加1
		ssdb:zincr("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,1)
		--教师在大学区上传量加1
		ssdb:zincr("qyjh_dxq_tea_uploadcount_"..adddxqids[i],person_id,1)
		
		--统计大学区资源数量
		res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=pub_target,"..adddxqids[i]..";groupby=attr:obj_info_id;'")
		ssdb:hset("qyjh_dxq_tj_"..adddxqids[i],"zy_tj",#res)
		
		
	end
end
--=======从大学区取消发布
del_dxq_ids = gsub(del_dxq_ids, "[%[%]\" ]", "")
if del_dxq_ids and len(del_dxq_ids) > 0 then
	local deldxqids = Split(del_dxq_ids, ",")
	for i=1,#deldxqids do
		--学校在区域均衡的上传量-1
		ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,-1)
		--学校在大学区的上传量-1
		ssdb:zincr("qyjh_dxq_org_uploadcount_"..deldxqids[i],org_id,-1)
		--教师在区域均衡上传量-1
		ssdb:zincr("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,-1)
		--教师在大学区上传量-1
		ssdb:zincr("qyjh_dxq_tea_uploadcount_"..deldxqids[i],person_id,-1)

		--统计大学区资源数量
		res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=pub_target,"..deldxqids[i]..";groupby=attr:obj_info_id;'")
		ssdb:hset("qyjh_dxq_tj_"..deldxqids[i],"zy_tj",#res)
		
	end
end

--=======发布到协作体
add_xzt_ids = gsub(add_xzt_ids, "[%[%]\" ]", "")
if add_xzt_ids and len(add_xzt_ids) > 0 then
	local addxztids = Split(add_xzt_ids, ",")
	for i=1,#addxztids do
		local hxzt = ssdb:hget("qyjh_xzt",addxztids[i])
		local xzt = cjson.decode(hxzt[1])
		--学校在区域均衡的上传量+1
		ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,1)
		--学校在大学区的上传量+1
		ssdb:zincr("qyjh_dxq_org_uploadcount_"..xzt.dxq_id,org_id,1)
		
		--教师在区域均衡上传量+1
		ssdb:zincr("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,1)
		--教师在大学区上传量+1
		ssdb:zincr("qyjh_dxq_tea_uploadcount_"..xzt.dxq_id,person_id,1)
		--教师在协作体上传量+1
		ssdb:zincr("qyjh_xzt_tea_uploadcount_"..addxztids[i],person_id,1)
		--协作体资源量+1
		ssdb:hincr("qyjh_xzt_tj_"..addxztids[i],"zy_tj",1)
	end
end
--从协作体取消发布
del_xzt_ids = gsub(del_xzt_ids, "[%[%]\" ]", "")
if del_xzt_ids and len(del_xzt_ids) > 0 then
	local delxztids = Split(del_xzt_ids, ",")
	for i=1,#delxztids do
		local hxzt = ssdb:hget("qyjh_xzt",delxztids[i])
		local xzt = cjson.decode(hxzt[1])
		--学校在区域均衡的上传量-1
		ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,-1)
		--学校在大学区的上传量-1
		ssdb:zincr("qyjh_dxq_org_uploadcount_"..xzt.dxq_id,org_id,-1)
		
		--教师在区域均衡上传量-1
		ssdb:zincr("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,-1)
		--教师在大学区上传量-1
		ssdb:zincr("qyjh_dxq_tea_uploadcount_"..xzt.dxq_id,person_id,-1)
		--教师在协作体上传量-1
		ssdb:zincr("qyjh_xzt_tea_uploadcount_"..delxztids[i],person_id,-1)
		--协作体资源量-1
		ssdb:hincr("qyjh_xzt_tj_"..delxztids[i],"zy_tj",-1)
	end
end
--******************************************

--**************统计区域均衡资源数量************
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;sort=attr_desc:DOWN_COUNT;'")
ssdb:hset("qyjh_qyjh_tj_"..qyjh_id,"zy_tj",#res)
--**************统计大学区资源数量************






say("{\"success\":true}")
--根据分隔符分割字符串
function Split(str, delim, maxNb)   
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result
end

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
