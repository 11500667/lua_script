
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 重复试题合并
-- 作者：刘全锋
-- 日期：2015年9月14日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
local cjson = require "cjson"

local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local md5_ids = args["md5_ids"];

if md5_ids == nil or md5_ids =="" then
	ngx.say("{\"success\":false,\"info\":\"md5_ids参数错误！\"}");
	return
end


local result = true;
local questionModel = require "management.question.model.QuestionModel";

local md5_ids_table = cjson.decode(md5_ids);

for i=1,#md5_ids_table do

	result = questionModel.distinctQuestion(md5_ids_table[i]);
end


if not result then
	ngx.say("{\"success\":\"false\",\"info\":\"试题合并失败！}");
	return
end

ngx.say("{\"success\":\"success\",\"info\":\"试题合并成功！\"}");

