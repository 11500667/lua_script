ngx.log(ngx.ERR,"根据区（县）ID获取该区（县）下有哪些学校开始")
--获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
  args = ngx.req.get_uri_args();
else
  ngx.req.read_body();
  args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--district_id参数
if args["district_id"] == nil or args["district_id"] == "" then
  ngx.print("{\"success\":false,\"info\":\"district_id参数错误！\"}")
  return
end
local title = args["district_id"]
print(title)

-- 获取数据库连接
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
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

local res, err, errno, sqlstate = db:query("SELECT org_id,org_name FROM t_base_organization WHERE ORG_TYPE = 2 and B_USE = 1 and district_id = "..title..";")
ngx.log(ngx.ERR,"SELECT org_id,org_name FROM t_base_organization WHERE district_id = "..title..";")
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end


local returnjson = {}
local returnjsonlist = {}
if res == nil then
  returnjson.success = false
  returnjson.info = "查询数据库失败"
  return
else
  returnjson.success = true
  local resList = {}
  for i=1,#res do
    local registered_res = {}
    registered_res.org_id = res[i]["org_id"]
    registered_res.org_name = res[i]["org_name"]
    returnjsonlist[i] = registered_res
  end
end

returnjson["success"] = true
returnjson["list"] = returnjsonlist
cjson.encode_empty_table_as_object(false)



-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
  ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))

