#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-4-10
#描述：获取用户定制信息
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["id"]==nil or args["id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数id不能为空！");
    return
end
local id = tostring(args["id"]);
--local DBUtil = require "multi_check.model.DBUtil";
--local db = DBUtil: getDb();
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local result, info = ResourceCustomize: getCustomizeById(id);
--ngx.log(ngx.ERR, "ERR MSG =====> 参数id不能为空！"..result);
--local sql ="SELECT ID, PERSON_NAME,  CREATE_TIME, STAGE_NAME, SUBJECT_NAME,EMAIL, TELEPHONE, QQ, RES_NAME, RES_TYPE, RES_COMMENT, EXPECT_TIME FROM T_BASE_RES_CUSTOMIZE WHERE  id="..id;
--local res, err, errno, sqlstate =  db:query(sql)
	-- if not res then 
ngx.log(ngx.ERR, "===> 查询定制信息出错，错误信息：[err]-> [", err, "], [errno]->[", errno, "], [sqlstate]->[", sqlstate, "]");
     --   return {success=false, info="查询数据出错。"};
	--end
--local getCustomizeInfoo =res
--local getCustomizeInfo={};
--getCustomizeInfo.success=true;
--getCustomizeInfo.list=getCustomizeInfoo;
ngx.print(cjson.encode(result));