--[[
带头人统计协作体相关信息
@Author  chenxg
@Date    2015-03-21
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
--当前用户
local person_id = args["person_id"]
local pyear = args["year"]
local pmonth = args["month"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not pyear or string.len(pyear) == 0
	or not pmonth or string.len(pmonth) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or year or month 参数错误！\"}")
    return
end

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

local returnjson = {}
local xztList = {}
local zyCount = 0
local wkzyCount = 0
local hdzyCount = 0
local jsCount = 0
local hdCount = 0
--获取协作体列表【带头人】
local xzts = ssdb:hget("qyjh_manager_xzts",person_id)
local xztids = Split(xzts[1],",")

local baseStart = pyear..pmonth
local baseEnd = pyear..pmonth
if pmonth == "-1" then
	baseStart = pyear.."00"
	baseEnd = pyear.."12"
end
local start_time = baseStart.."00000000"
local end_time = baseEnd.."31235959"
--获取协作体列表
for i=2,#xztids-1,1 do
	local txzt = {}
	local xzt = ssdb:hget("qyjh_xzt",xztids[i])
	local temp = cjson.decode(xzt[1])
	txzt.name = temp.name
	txzt.xzt_id = xztids[i]
	--获取教师人数(未退出协作体或者退出时间在该月之后)
	local teaCountSql = "select count(distinct tea_id) as teaCount from t_qyjh_xzt_tea t where ((t.b_use=1 and t.start_time < "..end_time..") or (t.b_use=0 and t.start_time < "..end_time.." and t.end_time < "..end_time..")) and t.xzt_id="..xztids[i];
	
	ngx.log(ngx.ERR,"========>"..teaCountSql.."<=============")
	local tea_res = mysql_db:query(teaCountSql)
	jsCount = tea_res[1]["teaCount"]
	
	--===========================获取资源数（根据上传时间）
	--未删除资源的检索
	local rangePamas = "filter=b_delete,0;range=ts,"..start_time.."00000,"..end_time.."99999;"
	
	local resCountSql = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..rangePamas.."filter=pub_type,3;filter=xzt_id,"..xztids[i]..";groupby=attr:obj_info_id;maxmatches=1000';SHOW ENGINE SPHINX STATUS;"

	res = mysql_db:query(resCountSql)
	local res1 = mysql_db:read_result()
	local _,s_str = string.find(res1[1]["Status"],"found: ")
	local e_str = string.find(res1[1]["Status"],", time:")
	zyCount = string.sub(res1[1]["Status"],s_str+1,e_str-1)
	
	--[[
	--已删除的资源的检索
	local delrangePamas = "filter=b_delete,1;range=ts,"..start_time.."00000,"..end_time.."99999;range=update_ts,"..end_time.."99999,9999999999999999999;"
	--删除资源的统计
	resCountSql = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..delrangePamas.."filter=pub_type,3;filter=xzt_id,"..xztids[i]..";groupby=attr:obj_info_id;maxmatches=1000';SHOW ENGINE SPHINX STATUS;"
	
	res = mysql_db:query(resCountSql)
	local res1 = mysql_db:read_result()
	local _,s_str = string.find(res1[1]["Status"],"found: ")
	local e_str = string.find(res1[1]["Status"],", time:")
	zyCount = #zyCount+string.sub(res1[1]["Status"],s_str+1,e_str-1)]]
	
	--=====================获取活动数===============
	--获取未删除的活动
	local rangePamas = "filter=b_delete,0;range=startts,"..start_time..","..end_time..";"
	
	local dxqidPamas = "filter=xzt_id,"..xztids[i]..";"
	--未删除活动统计
	local hdCountSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'"..rangePamas..dxqidPamas.."\';SHOW ENGINE SPHINX  STATUS;"
	
	res = mysql_db:query(hdCountSql)
	local res1 = mysql_db:read_result()
	local _,s_str = string.find(res1[1]["Status"],"found: ")
	local e_str = string.find(res1[1]["Status"],", time:")
	hdCount = string.sub(res1[1]["Status"],s_str+1,e_str-1)
	--[[
	--已删除活动统计
	local delRangePamas = "filter=b_delete,1;range=startts,"..start_time..","..end_time..";range=ts,"..end_time.."99999,9999999999999999999;"
	
	hdCountSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'"..delRangePamas..dxqidPamas.."\';SHOW ENGINE SPHINX  STATUS;"
	
	res = mysql_db:query(hdCountSql)
	local res1 = mysql_db:read_result()
	local _,s_str = string.find(res1[1]["Status"],"found: ")
	local e_str = string.find(res1[1]["Status"],", time:")
	hdCount = hdCount+string.sub(res1[1]["Status"],s_str+1,e_str-1)]]
	
	txzt.zyCount = zyCount
	txzt.jsCount = jsCount
	txzt.hdCount = hdCount
	txzt.wkzyCount = wkzyCount
	xztList[#xztList+1] = txzt
end

returnjson.xztList = xztList

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)