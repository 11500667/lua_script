#lzy 2015-05-16 获得管理员的信息
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--先判断参数是否正确
if tostring(args["person_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")    
    return
end

--获取人员id
local person_id = tostring(args["person_id"])

if tostring(args["identity_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")    
    return
end

--身份id
local identity_id = tostring(args["identity_id"])

local returnJson = {};
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
end

  db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

--判断人员是否能够登录后台

local sql_unit = "SELECT unit_id,unit_type FROM t_base_maneger WHERE person_id = "..person_id.." and b_use = 1";

local unit_result = db:query(sql_unit);
local is_quadmin = 0 ;
local is_xiaoadmin = 0;
local is_shiadmin =0;
local qu_info = {};
local xiao_info = {};
if #unit_result >0 then
-- 根据人员id查询对应的区id
for i=1,#unit_result do 
  local info = {};
  local unit_id =  unit_result[i]["unit_id"]
  local unit_type =  unit_result[i]["unit_type"]
  --查询校管理员获得区域管理员
  local manager_identity;
  if unit_type == 1 then
     manager_identity = 10;
	 is_quadmin = 1;
  elseif unit_type == 2 then
     manager_identity = 4;
	 is_xiaoadmin = 1;
  elseif unit_type == 3 then
     is_shiadmin = 1;
	 manager_identity = 9;
  end
  ngx.log(ngx.ERR,"=========="..unit_type)
  local  sel_new_person_id = "SELECT PERSON_ID FROM t_base_person WHERE bureau_id ="..unit_id.." and identity_id ="..manager_identity;
  local results, err, errno, sqlstate = db:query(sel_new_person_id);
  if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
  end

  local new_person_id  = results[1]["PERSON_ID"];
  -- 获得校管理员或者区管理员的登录名
   ngx.log(ngx.ERR,"=========new_person_id"..new_person_id)
   local login_name_sql =  "SELECT login_name FROM t_sys_loginperson WHERE person_id = "..new_person_id.." and identity_id = "..manager_identity;

   local results_login_name, err, errno, sqlstate = db:query(login_name_sql);
   if not results_login_name then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
   end

    local login_name = results_login_name[1]["login_name"];
	
	-- 组装后台登录管理员信息
   local admin_info,err = cache:hmget("login_"..login_name,"person_id","person_name","identity_id","token")
      if not admin_info then
       ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
       return
   end

    --获得管理员的省市区

    local org_info,err = cache:hmget("person_"..admin_info[1].."_"..manager_identity,"shi","qu","xiao","sheng");
       if not org_info then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
       return
    end
    local role_str = "";
	local role_info = cache:lrange("role_"..admin_info[1].."_"..manager_identity,0,-1)
		if #role_info ~= 0 then
		for j=1,#role_info,1 do
		   role_str = role_str..role_info[j]..",";
		end
	end
   info["background_bureau_id"] = org_info[3];
info["background_city_id"] = org_info[1];
info["background_district_id"] = org_info[2];
info["background_identity_id"] = admin_info[3];
info["background_person_id"] = admin_info[1];
info["background_person_name"] = admin_info[2];
info["background_role_id"] = role_str;
info["background_token"] = admin_info[4];
info["background_user"] = login_name;
info["background_province_id"] = org_info[4];

if manager_identity == 4 then
 returnJson.xiaoinfo = info;
elseif manager_identity == 10 then
 returnJson.quinfo = info;
elseif manager_identity == 9 then
 returnJson.shiinfo = info;
end	
end
end

returnJson["success"] = true;
returnJson["is_xiaoadmin"] =is_xiaoadmin;	
returnJson["is_quadmin"] =is_quadmin;	
returnJson["is_shiadmin"] =is_shiadmin;	

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)


	
