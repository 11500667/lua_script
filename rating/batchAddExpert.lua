#ngx.header.content_type = "text/plain;charset=utf-8"
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
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end


--大赛id
if args["rating_id"] == nil or args["rating_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
  return
end
local rating_id = args["rating_id"]

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]

--专家数量
if args["count"] == nil or args["count"] == "" then
  ngx.say("{\"success\":false,\"info\":\"count参数错误！\"}")
  return
end

--学段
local stage_id
if args["stage_id"] == nil or args["stage_id"] == "" then
  stage_id=0
else
  stage_id=args["stage_id"]
end

--学科
local subject_id
if args["subject_id"] == nil or args["subject_id"] == "" then
  subject_id=0
else
  subject_id=args["subject_id"]
end


local qu_id = redis_db:hget("person_"..person_id.."_9","qu")
local shi_id = redis_db:hget("person_"..person_id.."_9","shi")
local sheng_id=redis_db:hget("person_"..person_id.."_9","sheng")
local xiao_id=redis_db:hget("person_"..person_id.."_9","xiao")
local bm = redis_db:hget("person_"..person_id.."_9","bm")
ngx.log(ngx.ERR, "person_"..person_id.."_9")

if qu_id == ngx.null then
	qu_id=0
end
if shi_id == ngx.null then
	shi_id=0
end
if sheng_id == ngx.null then
	sheng_id=0
end
if xiao_id == ngx.null then
	xiao_id=0
end
if bm == ngx.null then
	bm=0
end

--获取用户名称
--local sqlshi = "select value_name from t_rating_sys_experts where org_id='"..shi_id.."'"
local sqlshi = "select value_name from t_rating_sys_experts where rating_type = (select rating_type from t_rating_info where id="..rating_id..")"
local sqlshi_value, err, errno, sqlstate = db:query(sqlshi)
	ngx.log(ngx.ERR,sqlshi)
	if not sqlshi_value then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end
local value_name = sqlshi_value[1]["value_name"];

local count = args["count"]
local login_id = value_name

---获取当前最大索引
local maxsql = "select max(id) as index_id from t_rating_experts"
local max_id, err, errno, sqlstate = db:query(maxsql)
	ngx.log(ngx.ERR,maxsql)
	if not max_id then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end
local max_id_index = ""
if max_id[1]["index_id"] == nil or max_id[1]["index_id"] == "" then
	max_id_index = 0
else
	max_id_index = max_id[1]["index_id"];
end
ngx.log(ngx.ERR,"======================================="..max_id_index)
for i=1,count do
	local insstusql, err, errno, sqlstate = db:query("INSERT INTO t_base_person (PERSON_NAME,ORG_ID,BUREAU_ID,DISTRICT_ID,CITY_ID,PROVINCE_ID,CREATE_TIME,B_USE,IDENTITY_ID,DISPLAY) VALUES ('"..login_id..(i+max_id_index).."','"..xiao_id.."','"..bm.."','"..qu_id.."','"..shi_id.."','"..sheng_id.."',now(),2,11,1);")
	if not insstusql then
		ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
		ngx.log(ngx.ERR, "err: ".. err);
		return
	end
	local stuid=insstusql.insert_id
	local token = ngx.md5(tostring(stuid.."_11".."_dsideal4r5t6y7u"))
	local pwd_rel = tostring(math.random(100000,999999))
	local pwd_new = ngx.md5(pwd_rel)

  local inssql = "insert into t_rating_experts (login_pwd_rel,person_id,login_id,login_pwd,rating_id,status,stage_id,subject_id) VALUES ("..pwd_rel..","..stuid..",'"..login_id..(i+max_id_index).."','"..pwd_new.."','"..rating_id.."',1,"..stage_id..","..subject_id..")"
  local ex, err, errno, sqlstate = db:query(inssql)
	ngx.log(ngx.ERR,inssql)
	if not ex then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end
	
	--添加缓存

	local inslogsql, err, errno, sqlstate = db:query("INSERT INTO t_sys_loginperson (PERSON_ID,PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..stuid.."','"..login_id..(i+max_id_index).."','"..login_id..(i+max_id_index).."','"..pwd_new.."',11,1,2);")
	ngx.log(ngx.ERR,"INSERT INTO t_sys_loginperson (PERSON_ID,PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,audit_status) VALUES ('"..stuid.."','"..login_id..(i+max_id_index).."','"..login_id..(i+max_id_index).."','"..pwd_new.."',11,1,2);")
	if not inslogsql then
		ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
		ngx.log(ngx.ERR, "err: ".. err);
	return
	end
	
	
	
ngx.log(ngx.ERR,"login_" ..login_id..(i+max_id_index),"identity_id","11","person_name",login_id..(i+max_id_index),"pwd",pwd_new,"b_use","1","token",token,"audit_status","1")
local setLoginResult = redis_db: hmset("login_" ..login_id..(i+max_id_index), "identity_id","11","person_name",login_id..(i+max_id_index),"pwd",pwd_new,"b_use","1","token",token,"audit_status","1" ,"person_id",stuid)


local res1, err, errno, sqlstate = db:query("insert into t_base_chat(CHAT_TYPE) values (2);")
ngx.log(ngx.ERR,"insert into t_base_chat(CHAT_TYPE) values (2);")
if not res1 then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local chatid = res1.insert_id
local setPersonResult = redis_db: hmset("person_" ..stuid.."_11","sys_chatid",chatid,"person_name",login_id..(i+max_id_index),"avatar_url","default_person.png","bm","10","sheng",sheng_id,"shi",shi_id,"qu",qu_id,"xiao",xiao_id,"token",token )

end





local returnjson = {}
returnjson.success = true
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))


