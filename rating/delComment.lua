local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评论id
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"id参数错误！\"}")
    return
end
local id = args["id"]

--资源id'
if args["pid"] == nil or args["pid"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pid参数错误！\"}")
    return
end
local pid = args["pid"]

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

ngx.log(ngx.ERR, "**********东师理想微课大赛*****删除评论信息开始**********");
local delsql = "update t_dswk_comment set b_use=0 where id="..id
ngx.log(ngx.ERR,delsql)
local delsql_res,err,errno,sqlstatus = db:query(delsql)
if not delsql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end
local insResSql = "update t_rating_resource set comment_count = comment_count -1 where RESOURCE_INFO_ID="..pid
ngx.log(ngx.ERR,insResSql)
local insResSql_res,err,errno,sqlstatus = db:query(insResSql)
if not insResSql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);	
end
local returnResult = {}
returnResult.success = true
returnResult.info = "删除成功"
db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(returnResult))
ngx.log(ngx.ERR, "**********东师理想微课大赛*****删除评论信息结束**********");