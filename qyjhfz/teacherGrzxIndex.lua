--[[
根据教师ID获取[资源、试卷、备课、微课]数量
@Author  chenxg
@Date    2015-03-13
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

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
local qyjh_id = args["qyjh_id"]
local person_id = args["person_id"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not qyjh_id or string.len(qyjh_id) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or qyjh_id 参数错误！\"}")
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

local returnjson = {}

--******************************
local allresparams = "?qyjh_id="..qyjh_id.."&isfljs=0&page_type=4&pageSize=1&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&rtype=0&app_type_id=0&Scope=-1&person_id="..person_id

local resparams = "?qyjh_id="..qyjh_id.."&isfljs=1&page_type=4&obj_type=1&pageSize=1&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&rtype=0&app_type_id=0&Scope=-1&person_id="..person_id

local sjparams = "?qyjh_id="..qyjh_id.."&isfljs=1&page_type=4&obj_type=3&pageSize=3&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&ptype=0&app_type_id=0&Scope=-1&person_id="..person_id

local bkparams = "?qyjh_id="..qyjh_id.."&isfljs=1&page_type=4&obj_type=4&pageSize=3&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&beike_type=0&app_type_id=0&Scope=-1&person_id="..person_id

local wkparams = "?qyjh_id="..qyjh_id.."&isfljs=1&page_type=4&obj_type=5&pageSize=3&pageNumber=1&nid=0&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=1&sort_type=1&wk_type=0&app_type_id=0&Scope=-1&person_id="..person_id

local allres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..allresparams)
--say("/dsideal_yy/qyjhfz/loadQyjhRes"..allresparams)
if allres.status == 200 then
	allreslist = (cjson.decode(allres.body))
else
	say("{\"success\":false,\"info\":\"获取所有资源总数失败！\"}")
	return
end

local res = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..resparams)
if res.status == 200 then
	reslist = (cjson.decode(res.body))
else
	say("{\"success\":false,\"info\":\"获取资源总数失败！\"}")
	return
end

local sjres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..sjparams)
if sjres.status == 200 then
	sjlist = (cjson.decode(sjres.body))
else
	say("{\"success\":false,\"info\":\"获取试卷总数失败！\"}")
	return
end

local bkres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..bkparams)
if bkres.status == 200 then
	bklist = (cjson.decode(bkres.body))
else
	say("{\"success\":false,\"info\":\"获取备课总数失败！\"}")
	return
end

local wkres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..wkparams)
if wkres.status == 200 then
	wklist = (cjson.decode(wkres.body))
else
	say("{\"success\":false,\"info\":\"获取微课总数失败！\"}")
	return
end
returnjson.allCount = allreslist.totalRow
returnjson.resCount = reslist.totalRow
returnjson.sjCount = sjlist.totalRow
returnjson.bkCount = bklist.totalRow
returnjson.wkCount = wklist.totalRow
--******************************

--==========获取个人所属协作体，等信息=============
--所属协作体数量
local xztparams = "?pageSize=1&pageNumber=1&searchTeam=&qyjh_id="..qyjh_id.."&page_type=2&subject_id=-1&person_id="..person_id.."&Scope=1"
local xztres = ngx.location.capture("/dsideal_yy/qyjhfz/getXztByParams"..xztparams)
if xztres.status == 200 then
	xztlist = (cjson.decode(xztres.body))
else
	say("{\"success\":false,\"info\":\"获取协作体总数失败！\"}")
	return
end
--参与活动：
local hdparams = "?pageSize=1&pageNumber=1&qyjh_id="..qyjh_id.."&hd_type=-1&subject_id=-1&person_id="..person_id.."&searchTeam=&Scope=-1&page_type=5"
local hdres = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..hdparams)
if hdres.status == 200 then
	hdlist = (cjson.decode(hdres.body))
else
	say("{\"success\":false,\"info\":\"获取活动总数失败！\"}")
	return
end
--活动资源：
local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
if xzts[1] and string.len(xzts[1])>2 then
	scopePamas = "filter=xzt_id"..string.sub(xzts[1],0,string.len(xzts[1])-1)..";"
else
	scopePamas = "filter=xzt_id,-1;"
end
local sphinxStartSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'"
local sphinxSql = sphinxStartSql..scopePamas.."'"
--ngx.log(ngx.ERR,"********===>"..sphinxSql.."<====*********")
local hd_res = mysql_db:query(sphinxSql)
local hdids = "-1"
for i=1,#hd_res do
	local hd_id = hd_res[i]["id"]
	if i == 1 then
		hdids = ""
	end
	hdids = hdids..hd_id
	if i ~= #hd_res then
		hdids = hdids..","
	end
end
local hdzyparams = "?qyjh_id="..qyjh_id.."&isfljs=0&path_id="..hdids.."&page_type=6&pageSize=3&pageNumber=1&hj_id=-1"
local hdzyres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..hdzyparams)
if hdzyres.status == 200 then
	hdzylist = (cjson.decode(hdzyres.body))
else
	say("{\"success\":false,\"info\":\"获取参与资源总数失败！\"}")
	return
end

--******************************************
--================================================
--参与资源
local cyzyparams = "?qyjh_id="..qyjh_id.."&isfljs=0&page_type=4&pageSize=1&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&rtype=0&app_type_id=0&Scope=-1&person_id="..person_id
local cyzyres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..cyzyparams)
if cyzyres.status == 200 then
	cyzylist = (cjson.decode(cyzyres.body))
else
	say("{\"success\":false,\"info\":\"获取参与资源总数失败！\"}")
	return
end

--发布资源
local fbzyparams = "?qyjh_id="..qyjh_id.."&isfljs=0&page_type=4&pageSize=1&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&rtype=0&app_type_id=0&Scope=1&person_id="..person_id
local fbzyres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..fbzyparams)
if fbzyres.status == 200 then
	fbzylist = (cjson.decode(fbzyres.body))
else
	say("{\"success\":false,\"info\":\"获取参与资源总数失败！\"}")
	return
end
--传播给我的资源
local cbgwzyparams = "?qyjh_id="..qyjh_id.."&isfljs=0&page_type=4&pageSize=3&pageNumber=1&nid=&scheme_id=&keyword=&is_root=-1&cnode=1&sort_num=2&sort_type=1&rtype=0&app_type_id=0&Scope=2&person_id="..person_id
local cbgwzyres = ngx.location.capture("/dsideal_yy/qyjhfz/loadQyjhRes"..cbgwzyparams)
if cbgwzyres.status == 200 then
	cbgwzylist = (cjson.decode(cbgwzyres.body))
else
	say("{\"success\":false,\"info\":\"获取参与资源总数失败！\"}")
	return
end

returnjson.xztCount = xztlist.totalRow
returnjson.hdCount = hdlist.totalRow
returnjson.hdzyCount = hdzylist.totalRow
returnjson.cyzyCount = cyzylist.totalRow
returnjson.fbzyCount = fbzylist.totalRow
returnjson.cbgwzyCount = cbgwzylist.totalRow

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)