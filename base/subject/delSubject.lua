#删除学科 by huyue 2015-06-05
--1.获得参数方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local mysql_db, err = mysql : new();
if not mysql_db then
  ngx.log(ngx.ERR, err);
  return;
end


mysql_db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = mysql_db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }
 
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数subject_id不能为空！");
    return
end

local subject_id = args["subject_id"]
local result = {} 
--校验产品
local res_product = mysql_db:query(" select count(1) as count from t_pro_product where subject_id= "..subject_id)
ngx.log(ngx.ERR, " select count(1) as count from t_pro_product where subject_id= "..subject_id)
local product_count=  tonumber(res_product[1]["count"])
if product_count > 0 then
  result["success"] = false
  result["info"] = "该学科已有产品，不能删除该学科！"
  
 else
	--校验版本
	local resouce_scheme = mysql_db:query("select  count(1) as count from t_resource_scheme where subject_id ="..subject_id.." and b_use =1")
	ngx.log(ngx.ERR, "select  count(1) as count from t_resource_scheme where subject_id ="..subject_id.." and b_use =1")
	local count = tonumber(resouce_scheme[1]["count"])
	if count > 0 then
	  result["success"] = false
	  result["info"] = "该学科已有版本，不能删除该学科！"
	else
		local res,err,errno,sqlstate =  mysql_db:query("delete  from t_dm_subject where subject_id ="..subject_id)
		if not res then
			ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			return
		end
		result["success"] = true
	end
end
--放入缓存key=xd_subject 开始

--查询学段
local xd_stage_res=mysql_db:query("SELECT STAGE_ID,STAGE_NAME FROM t_dm_stage WHERE STAGE_ID  IN (4,5,6,8)");

local stage_tab={}
for i=1,#xd_stage_res do
	local stage_res = {}
	stage_res["xd_id"] = xd_stage_res[i]["STAGE_ID"]
	stage_res["xd_name"] = xd_stage_res[i]["STAGE_NAME"]
	--根据学段查询学科
	local su_subject_res = mysql_db:query("SELECT SUBJECT_ID,SUBJECT_NAME FROM t_dm_subject where STAGE_ID="..xd_stage_res[i]["STAGE_ID"]);
	local subject_tab={}
	for j=1,#su_subject_res do
		local subject_res ={}
		subject_res["subject_id"]=su_subject_res[j]["SUBJECT_ID"]
		subject_res["subject_name"]=su_subject_res[j]["SUBJECT_NAME"]
		subject_tab[j]=subject_res
	end
	stage_res["subject_list"] = subject_tab

	stage_tab[i] = stage_res
end

ngx.log(ngx.ERR,"hu_log".."\"xd_subject_list\":"..cjson.encode(stage_tab))
cache:set("xd_subject","\"xd_subject_list\":"..cjson.encode(stage_tab));

--放入缓存key=xd_subject 结束


--放入缓存key=stage_subject_info开始
local resultJson=mysql_db:query("SELECT T1.subject_id,T1.subject_name,CONCAT(T2.STAGE_NAME,T1.SUBJECT_NAME) as stage_subject,T1.stage_id,T2.stage_name FROM t_dm_subject T1 INNER JOIN t_dm_stage T2 ON T1.STAGE_ID=T2.STAGE_ID where T1.STAGE_ID in (4,5,6,7,8,9) ORDER BY t1.STAGE_ID");

local responseJson = cjson.encode(resultJson);

cache:set("stage_subject_info",responseJson);

--放入缓存key=stage_subject_info结束



--放入ssdb开始
--	local ssdb_key = {"subject_id","subject_name","stage_id","stage_name","stage_subject"}

	ssdb_db:multi_hdel("subject_"..subject_id,"subject_id");
	ssdb_db:multi_hdel("subject_"..subject_id,"subject_name");
	ssdb_db:multi_hdel("subject_"..subject_id,"stage_id");
	ssdb_db:multi_hdel("subject_"..subject_id,"stage_name");
	ssdb_db:multi_hdel("subject_"..subject_id,"stage_subject");

--放入ssdb结束


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);


cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
