local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--资源id
if args["pid"] == nil or args["pid"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pid参数错误！\"}")
    return
end
local pid = args["pid"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--连接mysql数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

ngx.log(ngx.ERR, "**********东师理想微课大赛*****查询评论信息开始**********");

local countsql = "select count(*) as count from t_task_comment where b_use=1 and pid="..pid
ngx.log(ngx.ERR,countsql)
local countsql_res,err,errno,sqlstatus = db:query(countsql)
if not countsql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);		
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = countsql_res[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local querysql= "select id,pid,create_time,content,person_id,b_use from t_task_comment where b_use=1 and pid = "..pid.." order by id desc limit "..offset..","..limit.."; "
ngx.log(ngx.ERR,querysql)
local querysql_res = db:query(querysql)
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);	
end
local resource_tab = {}
for i=1,#querysql_res do
	local resource_res = {}
	resource_res.id=querysql_res[i]["id"]
	resource_res.pid=querysql_res[i]["pid"]
	resource_res.create_time=querysql_res[i]["create_time"]
	resource_res.content=querysql_res[i]["content"]
	resource_res.person_id=querysql_res[i]["person_id"]
	local queryPersonNameSql = "select person_name from t_base_person where person_id='"..querysql_res[i]["person_id"].."' union all select person_name from t_dswk_login where person_id='"..querysql_res[i]["person_id"].."'"
	local queryPersonNameSql_res,err,errno,sqlstatus = db:query(queryPersonNameSql)
	ngx.log(ngx.ERR,queryPersonNameSql)
	if not queryPersonNameSql_res then
	  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	  ngx.log(ngx.ERR, "err: ".. err);	
	end
	resource_res.person_name=queryPersonNameSql_res[1]["person_name"]
	resource_res.b_use=querysql_res[i]["b_use"]
	resource_tab[i] = resource_res
end
local result = {} 
result["list"] = resource_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

ngx.log(ngx.ERR, "**********东师理想微课大赛*****查询评论信息结束**********");

