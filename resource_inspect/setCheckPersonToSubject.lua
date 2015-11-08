#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-05
#描述：后台->学校管理员->设置检查人员
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--传参数
if args["param_json"] == nil or args["param_json"] == "" then
    ngx.say("{\"success\":false,\"info\":\"param_json参数错误！\"}")
    return
end
local paramJson  = tostring(args["param_json"]);

local cjson = require "cjson";
local paramObj = cjson.decode(paramJson);
local person_id = paramObj.person_id;
local identity_id = paramObj.identity_id;
local person_name = paramObj.person_name;
local check_id = paramObj.check_id;
local school_id = paramObj.school_id;
local subjectList = paramObj.subject_List;
local sql_del_person_subject = "update t_resource_check_person_subject SET b_use = 0 where check_id = "..check_id.." AND person_id = "..person_id..";";
local sql_add_check_person = "INSERT INTO t_resource_check_person_subject(person_id,person_name,identity_id,subject_id,subject_name,stage_id,stage_name,check_id,school_id,b_use,create_time) values";
 local sql_str = "";
-- 循环前台发送过来的学科数组，获取学科信息
for index=1, #subjectList do
   
	local subjectObj 	= subjectList[index];
	local stageId 		= subjectObj.stage_id;
	local stageName 	= subjectObj.stage_name;
	local subjectId 	= subjectObj.subject_id;
	local subjectName 	= subjectObj.subject_name;	
	local create_time = ngx.localtime();
	-- 重新插入审核人员与科目的关联关系
	sql_str = sql_str ..",".."("..person_id..",'"..person_name.."',"..identity_id..","..subjectId..",'"..subjectName.."',"..stageId..",'"..stageName.."',"..check_id..","..school_id..",1,'"..create_time.."')";
	
end
if #sql_str > 1 then
    sql_str = string.sub(sql_str,2,#sql_str);
	sql_str = sql_str..";";
end

--连接数据库
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
local create_time = ngx.localtime();

local sql_submit="start transaction;"..sql_del_person_subject..sql_add_check_person..sql_str.."commit;" ;
ngx.log(ngx.ERR,"----------->"..sql_submit.."<------------");

local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"设置检查人员失败！\"}");
	 return
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"设置检查人员成功\"}")












