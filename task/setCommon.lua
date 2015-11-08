local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--主任务id
if args["pid"] == nil or args["pid"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pid参数错误！\"}")
    return
end
local pid = args["pid"]

--内容content
if args["content"] == nil or args["content"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"content参数错误！\"}")
    return
end
local content = args["content"]

---person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

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

ngx.log(ngx.ERR, "**********东师理想微课大赛*****新增评论信息开始**********");
local inssql = "insert into t_task_comment (PID, CREATE_TIME, CONTENT, PERSON_ID, B_USE) values ("..pid..", now(), '"..content.."', "..person_id..", 1);"
ngx.log(ngx.ERR,inssql)
local inssql_res,err,errno,sqlstatus = db:query(inssql)
if not inssql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);	
end
local insResSql = "update t_rating_resource set comment_count = comment_count + 1 where RESOURCE_INFO_ID="..pid
ngx.log(ngx.ERR,insResSql)
local insResSql_res,err,errno,sqlstatus = db:query(insResSql)
if not insResSql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);	
end
local returnResult = {}
returnResult.success = true
returnResult.info = "评论成功"
db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(returnResult))
ngx.log(ngx.ERR, "**********东师理想微课大赛*****新增评论信息结束**********");
