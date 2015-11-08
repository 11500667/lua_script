#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
--参数：person_id
if args["person_id"]==nil or args["person_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
    ngx.log(ngx.ERR, "ERR MSG =====> 参数person_id不能为空！");
    return
end
local person_id = tostring(args["person_id"]);

--参数：identity_id
if args["identity_id"]==nil or args["identity_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
    ngx.log(ngx.ERR, "ERR MSG =====> 参数identity_id不能为空！");
    return
end
local identity_id = tostring(args["identity_id"]);


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


local personinfo = cache:hmget("person_"..person_id.."_"..identity_id,"sheng","shi","xiao","person_name","qu","bm");
local responseObj = {};
responseObj.success = true;
responseObj.person_name = personinfo[4];
responseObj.identity_id = identity_id;

local sheng_id = personinfo[1];
local shi_id = personinfo[2];
local qu = personinfo[5];
local bm = personinfo[6];

local org_id;
if identity_id == "6" then
      org_id= personinfo[3];
     local sel_studentinfo = "SELECT t2.province_id as province_id,t1.class_id,ifnull(t1.email,'') as email,t2.org_name,t2.city_id as city_id,t2.org_id as org_id FROM t_base_student AS t1 INNER JOIN  t_base_organization AS t2 ON t1.bureau_id = t2.org_id WHERE t2.org_id = "..org_id.." and t1.STUDENT_ID = "..person_id;
   
           local results_studentinfo , err, errno, sqlstate = db:query(sel_studentinfo);
        if not results_studentinfo then
         ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
         ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
        return
     end
     --根据班级id获得班级名称
     local sel_class = "SELECT class_name from t_base_class where class_id =" ..results_studentinfo[1]["class_id"];

       local results_class , err, errno, sqlstate = db:query(sel_class);
        if not results_class then
         ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
         ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
        return
     end
     
    responseObj.email = results_studentinfo[1]["email"];
    responseObj.school = results_studentinfo[1]["org_name"];
    responseObj.class_id = results_studentinfo[1]["class_id"];
    responseObj.class_name = results_class[1]["class_name"];
    sheng_id = results_studentinfo[1]["province_id"];
    shi_id = results_studentinfo[1]["city_id"];
    responseObj.person_photo= "0";
     
else 
    
--获得学校名称
local sel_xiao = "SELECT org_name FROM t_base_organization WHERE org_id = "..personinfo[3];
local results_xiao, err, errno, sqlstate = db:query(sel_xiao);
if not results_xiao then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local school = ""
if results_xiao[1] then
  school = results_xiao[1]["org_name"];
end

responseObj.school= school;

--获得邮箱信息

local sel_email = "SELECT ifnull(email,'') as  email,avatar_url FROM t_base_person WHERE person_id = "..ngx.quote_sql_str(person_id).." and identity_id = "..ngx.quote_sql_str(identity_id);

local results_email, err, errno, sqlstate = db:query(sel_email);
if not results_email then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local email = "";
local person_photo = ""
if results_email[1] then
  school = results_email[1]["email"];
  person_photo = results_email[1]["avatar_url"];
end

responseObj.email = email
responseObj.person_photo = person_photo

end


--获得省名称
local sel_sheng = "SELECT PROVINCENAME from t_gov_province WHERE ID ="..sheng_id;

local results_sheng, err, errno, sqlstate = db:query(sel_sheng);
if not results_sheng then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end


--获得市名称
local sel_shi = "SELECT cityname FROM t_gov_city WHERE ID ="..shi_id;

local results_shi, err, errno, sqlstate = db:query(sel_shi);
if not results_shi then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

--获得区名称
local sel_qu = "SELECT districtname FROM t_gov_district WHERE ID ="..qu;

local results_qu, err, errno, sqlstate = db:query(sel_qu);
if not results_qu then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local sheng_name = ""
if results_sheng[1] then
  sheng_name = results_sheng[1]["PROVINCENAME"];
end
local shi_name = ""
if results_shi[1] then 
  shi_name = results_shi[1]["cityname"];
end
responseObj.area= sheng_name..shi_name;
responseObj.qq="";
responseObj.sheng = sheng_id;
responseObj.sheng_name = sheng_name;
responseObj.shi = shi_id;
responseObj.shi_name = shi_name;
responseObj.xiao = personinfo[3];
responseObj.qu = qu;
if results_qu[1] then
  responseObj.qu_name = results_qu[1]["districtname"];
else
  responseObj.qu_name = ""
end
responseObj.bm = bm;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);


-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end