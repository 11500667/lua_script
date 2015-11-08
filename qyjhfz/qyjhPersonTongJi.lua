--[[
统计个人相关信息
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
local xztCount = 0
local zyCount = 0
local wkzyCount = 0
local hdzyCount = 0
local jsCount = 0
local hdCount = 0
--按照资源、试卷、备课、微课统计
local res_count = 0
local sj_count = 0
local bk_count = 0
local wk_count = 0
--按照媒体类型统计
local tp_count = 0
local sp_count = 0
local yp_count = 0
local dh_count = 0
local wb_count = 0
local ppt_count = 0
local ysb_count = 0
local exe_count = 0
local qt_count = 0


local baseStart = pyear..pmonth
local baseEnd = pyear..pmonth
if pmonth == "-1" then
	baseStart = pyear.."00"
	baseEnd = pyear.."12"
end
local start_time = baseStart.."00000000"
local end_time = baseEnd.."31235959"

--获取协作体列表[根据加入时间和退出时间]
local xztListSql = "SELECT DISTINCT t.xzt_id from t_qyjh_xzt_tea t where tea_id = "..person_id.." and ((t.b_use=1 and t.start_time BETWEEN "..start_time.." and "..end_time..") or (t.b_use=0 and t.start_time BETWEEN "..start_time.." and "..end_time.." and end_time > "..end_time.."))";
--ngx.log(ngx.ERR,"===========>"..xztListSql.."<=============")
local xzt_res = mysql_db:query(xztListSql)
xztCount = #xzt_res
local xzt_ids = ""
for i=1,#xzt_res,1 do
	local xzt_id = xzt_res[i]["xzt_id"]
	xzt_ids = xzt_ids..xzt_id..","
end
if string.len(xzt_ids)>1 then
	xzt_ids = string.sub(xzt_ids,0,string.len(xzt_ids)-1)
else
	xzt_ids = "-1"
end

--*******获取活动数据****************
--=====================获取活动数===============
--获取未删除的活动
local rangePamas = "filter=b_delete,0;range=startts,"..start_time..","..end_time..";"
local dxqidPamas = "filter=xzt_id,"..xzt_ids..";"
--未删除活动统计
local hdCountSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'"..rangePamas..dxqidPamas.."\';"
ngx.log(ngx.ERR, "owndqxs====>"..hdCountSql.."<====owndqxs**dqxs===>");
local hdres1 = mysql_db:query(hdCountSql)

--[[
--获取删除的活动
local delRangePamas = "filter=b_delete,1;range=startts,"..start_time..","..end_time..";range=ts,"..end_time.."99999,9999999999999999999;"
--已删除活动统计
hdCountSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'"..delRangePamas..dxqidPamas.."\';"
local hdres2 = mysql_db:query(hdCountSql)
]]

hdCount = #hdres1--+#hdres2

--获取资源总数
--未删除资源的检索
local resrangePamas = "filter=b_delete,0;range=ts,"..start_time.."00000,"..end_time.."99999;"

local resCountSql1 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resrangePamas.."filter=pub_type,3;filter=xzt_id,"..xzt_ids..";groupby=attr:obj_info_id;maxmatches=1000';"
local res1 = mysql_db:query(resCountSql1)
--[[
local resdelrangePamas = "filter=b_delete,1;range=ts,"..start_time.."00000,"..end_time.."99999;range=update_ts,"..end_time.."99999,9999999999999999999;"

local resCountSql2 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resdelrangePamas.."filter=pub_type,3;filter=xzt_id,"..xzt_ids..";groupby=attr:obj_info_id;maxmatches=1000';"
local res2 = mysql_db:query(resCountSql2)]]
returnjson.zyCount = #res1--+#res2

--获取传播给我的资源
local resCountSql3 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resrangePamas.."filter=pub_type,3;filter=xzt_id,"..xzt_ids..";!filter=person_id,"..person_id..";groupby=attr:obj_info_id;maxmatches=1000';"
local res3 = mysql_db:query(resCountSql3)
returnjson.cbgwzyCount = #res3

--获取我传播的资源
local resCountSql4 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resrangePamas.."filter=pub_type,3;filter=xzt_id,"..xzt_ids..";filter=person_id,"..person_id..";groupby=attr:obj_info_id;maxmatches=1000';"
local res4 = mysql_db:query(resCountSql4)
returnjson.wcbzyCount = #res4

--活动资源
local hdCountSql1 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resrangePamas.."filter=pub_type,3;range=hd_id,0,999999;filter=person_id,"..person_id..";groupby=attr:obj_info_id;maxmatches=1000';"
local hdres1 = mysql_db:query(hdCountSql1)
--[[
local hdCountSql2 = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..resdelrangePamas.."filter=pub_type,3;range=hd_id,0,999999;filter=person_id,"..person_id..";groupby=attr:obj_info_id;maxmatches=1000';"
local hdres2 = mysql_db:query(hdCountSql2)]]
returnjson.hdzyCount = #hdres1--+#hdres2

--*****************按照资源、试卷、备课、微课统计资源数*************
local resTypeSql = "select count(distinct obj_info_id) as res_count,obj_type from t_base_publish p where p.pub_type=3 and person_id="..person_id.." AND ((b_delete=0 and ts BETWEEN "..start_time.."00000 and "..end_time.."99999) or (b_delete=1 and ts BETWEEN "..start_time.."00000 and "..end_time.."99999 and update_ts > "..end_time.."99999))group by p.obj_type;"
local resType = mysql_db:query(resTypeSql)
for i=1,#resType,1 do
	local res_count = resType[i]["res_count"]
	local obj_type = resType[i]["obj_type"]
	if obj_type == 1 then
		res_count = res_count
	elseif obj_type == 3 then
		sj_count = res_count
	elseif obj_type == 4 then
		bk_count = res_count
	elseif obj_type == 5 then
		wk_count = res_count
	end
end
returnjson.type_res_count = res_count
returnjson.type_sj_count = sj_count
returnjson.type_bk_count = bk_count
returnjson.type_wk_count = wk_count
--*****************按照资源、试卷、备课、微课统计资源数*************


returnjson.xztCount = xztCount
returnjson.zyCount = zyCount
returnjson.wkzyCount = wkzyCount
returnjson.hdCount = hdCount
returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)