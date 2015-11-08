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

local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local stage_id = args["stage_id"]
if stage_id == nil or stage_id == '' then
  ngx.say("{\"success\":false,\"info\":\"stage_id不能为空\"}")
  return
end

local subject_id = args["subject_id"]
if subject_id == nil or subject_id == '' then
  ngx.say("{\"success\":false,\"info\":\"subject_id不能为空\"}")
  return
end

local res_count = db:query("select count(1) as count from t_pro_product where subject_id = "..subject_id.." and stage_id = "..stage_id);
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local res = db:query("select  product_id,product_name, platform_id,system_id from t_pro_product where subject_id = "..subject_id.." and stage_id = "..stage_id.." LIMIT "..offset..","..limit..";")

ngx.log(ngx.ERR, "select  product_id,product_name, platform_id,system_id from t_pro_product where subject_id = "..subject_id.." and stage_id = "..stage_id.." LIMIT "..offset..","..limit..";")

local product_tab = {}
for i=1,#res do
	local product_res = {}
	product_res["product_id"] = res[i]["product_id"]
	product_res["product_name"] = res[i]["product_name"]
	product_res["platform_id"] = res[i]["platform_id"]
	product_res["system_id"] = res[i]["system_id"]
	product_tab[i] = product_res
end

local result = {} 
result["list"] = product_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))




