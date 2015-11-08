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


local res, err, errno, sqlstate = db:query("SELECT value FROM t_sys_config WHERE id IN (3,4,5,6);")
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

--   0--省    1--市    2--区
local pro_or_dis = ""
local title = ""
local sqlquery = ""
local returnjson = {}
if res ~= nil then
	ngx.log(ngx.ERR, "res2: ".. res[2]["value"])
	ngx.log(ngx.ERR, "res3: ".. res[3]["value"])
  if res[2]["value"] == "0" then
    pro_or_dis = "0"
    title = res[1]["value"]
    sqlquery = "SELECT org_id,org_name FROM t_base_organization;"
  elseif  res[2]["value"] ~= "0" and res[3]["value"] == "0" then
    pro_or_dis = "1"
    title = res[2]["value"]   
    sqlquery = "SELECT id,districtname FROM t_gov_district where cityid = "..title..";"
  else
    pro_or_dis = "2"
    title = res[3]["value"]
    sqlquery = "SELECT id,districtname FROM t_gov_district where id = "..title..";"
  end

else
  returnjson.success = false
  returnjson.info = "查询数据库失败"
  return


end
ngx.log(ngx.ERR, "sqlquery: ".. sqlquery);
local res, err, errno, sqlstate = db:query(sqlquery)
if not res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local restab = {}
if res == nil then
  returnjson.success = false
  returnjson.info = "查询数据库失败"
  return
else
  returnjson.success = true
  for i=1,#res do
    local registered_res = {}
    registered_res.org_id = res[i]["id"]
    registered_res.org_name = res[i]["districtname"]
	restab[i] = registered_res
  end
end

returnjson["list"] = restab
returnjson["success"] = true
cjson.encode_empty_table_as_object(false)



-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
  ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
ngx.print(cjson.encode(returnjson))
