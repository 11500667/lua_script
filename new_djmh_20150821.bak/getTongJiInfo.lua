local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end
local bureau_id = args["bureau_id"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


--[[
local cz = ssdb_db:exists("TongJiInfo_"..bureau_id)
if tostring(cz[1]) == "1" then	
	local TongJiInfo = ssdb_db:get("TongJiInfo_"..bureau_id)

	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	
	ngx.print(TongJiInfo)
	
else
]]
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
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


	local sql = mysql_db:query("SELECT org_type FROM t_base_organization WHERE ORG_ID = "..bureau_id..";")
	local org_type = tostring(sql[1]["org_type"])

	local whereStr = ""
	local groupStr = ""
	
	local is_sq = ""
	
	if tonumber(bureau_id)>200000 and tonumber(bureau_id)<300000 then
		is_sq = "CITY_ID"
	else
		is_sq = "DISTRICT_ID"
	end
	
	
	--1：教育局  2：学校
	if org_type == "1" then
		whereStr = " AND "..is_sq.." = "..bureau_id
		groupStr = "1,"..bureau_id
	else
		whereStr = " AND BUREAU_ID = "..bureau_id
		groupStr = bureau_id
	end

	--用户个数
	sql = mysql_db:query("SELECT COUNT(1) AS personCount FROM t_base_person where IDENTITY_ID = 5  and B_USE=1"..whereStr..";")
	local personCount = sql[1]["personCount"]

	--资源个数
	--sql = mysql_db:query("SELECT COUNT(1) AS resourceCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id IN ("..groupStr..");")
	--local res_Count = tonumber(sql[1]["resourceCount"])
		
	local dsideal_count = redis_db:get("djmh_rescount_1")
	if dsideal_count == ngx.null then
		sql = mysql_db:query("SELECT COUNT(1) AS resourceCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id =1;")
		redis_db:set("djmh_rescount_1",sql[1]["resourceCount"])		
		dsideal_count = sql[1]["resourceCount"]
	end
	
	local bureau_count = redis_db:get("djmh_rescount_"..bureau_id)
	if bureau_count == ngx.null then
		sql = mysql_db:query("SELECT COUNT(1) AS resourceCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id ="..bureau_id..";")
		redis_db:set("djmh_rescount_"..bureau_id,sql[1]["resourceCount"])
		bureau_count = sql[1]["resourceCount"]
	end
	
	if org_type ~= "1" then
		dsideal_count = 0
	end
	
	local res_Count = tonumber(dsideal_count) + tonumber(bureau_count)
	
	sql = mysql_db:query("SELECT COUNT(1) AS resourceCount FROM t_wkds_info WHERE B_DELETE = 0 and group_id IN ("..groupStr..") ;")
	local wk_Count = tonumber(sql[1]["resourceCount"])
	
	sql = mysql_db:query("SELECT COUNT(1) AS resourceCount FROM t_sjk_paper_info WHERE B_DELETE = 0 and group_id IN ("..groupStr..") ;")
	local sj_Count = tonumber(sql[1]["resourceCount"])
	
	local resourceCount = res_Count + wk_Count + sj_Count
	
	ngx.log(ngx.ERR,"@@@dsideal_count："..dsideal_count.."@@@")
	ngx.log(ngx.ERR,"@@@bureau_count"..bureau_count.."@@@")
	ngx.log(ngx.ERR,"@@@res_Count"..res_Count.."@@@")
	ngx.log(ngx.ERR,"@@@wk_Count"..wk_Count.."@@@")
	ngx.log(ngx.ERR,"@@@sj_Count"..sj_Count.."@@@")

	--资源容量
	--sql = mysql_db:query("SELECT IFNULL(SUM(resource_size_int),0)/1024/1024/1024 AS resourceSize FROM t_resource_info WHERE res_type in (1,2,4,5) and RELEASE_STATUS in (1,3) and resource_size_int>0 AND group_id IN ("..groupStr..") ;")
	--local resourceSize = sql[1]["resourceSize"]
	
	local dsideal_size = redis_db:get("djmh_ressize_1")
	if dsideal_size == ngx.null then
		sql = mysql_db:query("SELECT IFNULL(SUM(resource_size_int),0) AS resourceSize FROM t_resource_info WHERE res_type in (1,2,4,5) and RELEASE_STATUS in (1,3) and resource_size_int>0 AND group_id =1;")
		redis_db:set("djmh_ressize_1",sql[1]["resourceSize"])		
		dsideal_size = sql[1]["resourceSize"]
	end
	
	local bureau_size = redis_db:get("djmh_ressize_"..bureau_id)
	if bureau_size == ngx.null then
		sql = mysql_db:query("SELECT IFNULL(SUM(resource_size_int),0) AS resourceSize FROM t_resource_info WHERE res_type in (1,2,4,5) and RELEASE_STATUS in (1,3) and resource_size_int>0 AND group_id = "..bureau_id..";")
		redis_db:set("djmh_ressize_"..bureau_id,sql[1]["resourceSize"])		
		bureau_size = sql[1]["resourceSize"]
	end
	
	if org_type ~= "1" then
		dsideal_size = 0
	end
	
	local resourceSize = mysql_db:query("SELECT ("..tonumber(dsideal_size).." + "..tonumber(bureau_size)..")/1024/1024/1024 AS resourceSize")[1]["resourceSize"]

	--浏览次数
	local viewCount = ssdb_db:get("viewcount_"..bureau_id)[1]
	if #viewCount == 0 then
		viewCount = 1
		ssdb_db:set("viewcount_"..bureau_id,viewCount)
	end

	--下载次数
	--sql = mysql_db:query("SELECT IFNULL(SUM(DOWN_COUNT),0) AS downCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id IN ("..groupStr..") ;")	
	--资源和备课
	--local res_downCount = tonumber(sql[1]["downCount"])
	
	local dsideal_down = redis_db:get("djmh_resdown_1")
	if dsideal_down == ngx.null then
		sql = mysql_db:query("SELECT IFNULL(SUM(DOWN_COUNT),0) AS downCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id =1 ;")
		redis_db:set("djmh_resdown_1",sql[1]["downCount"])		
		dsideal_down = sql[1]["downCount"]
	end
	
	local bureau_down = redis_db:get("djmh_resdown_"..bureau_id)
	if bureau_down == ngx.null then
		sql = mysql_db:query("SELECT IFNULL(SUM(DOWN_COUNT),0) AS downCount FROM t_resource_info WHERE res_type in (1,2) and RELEASE_STATUS in (1,3) and group_id ="..bureau_id.." ;")
		redis_db:set("djmh_resdown_"..bureau_id,sql[1]["downCount"])		
		bureau_down = sql[1]["downCount"]
	end
	
	if org_type ~= "1" then
		dsideal_down = 0
	end
	
	local res_downCount = tonumber(dsideal_down) + tonumber(bureau_down)
	
	
	sql = mysql_db:query("SELECT IFNULL(SUM(DOWNLOAD_COUNT),0) AS downCount FROM t_wkds_info WHERE B_DELETE = 0 and group_id IN ("..groupStr..") ;")
	local wk_downCount = tonumber(sql[1]["downCount"])
	sql = mysql_db:query("SELECT IFNULL(SUM(DOWN_COUNT),0) AS downCount FROM t_sjk_paper_info WHERE B_DELETE = 0 and group_id IN ("..groupStr..") ;")
	local sj_downCount = tonumber(sql[1]["downCount"])
	
	local downCount = res_downCount + wk_downCount + sj_downCount
	
	--mysql放回连接池
	mysql_db:set_keepalive(0,v_pool_size)

	local result = {}
	result["success"] = true
	result["personCount"] = tonumber(personCount)
	result["resourceCount"] = tonumber(resourceCount)
	result["resourceSize"] = tonumber(resourceSize)
	result["viewCount"] = tonumber(viewCount)
	result["downCount"] = tonumber(downCount)
	ssdb_db:setx("TongJiInfo_"..bureau_id,cjson.encode(result),300)
	
	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	
	ngx.print(cjson.encode(result))
--end



