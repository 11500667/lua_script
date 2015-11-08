#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
    申健   2015-04-17
    #描述：获取科目下的预留字段映射
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local AnalyseService = require "management.analyse.services.AnalyseKeyMapService";
AnalyseService: initSubjectKeyMap();
AnalyseService: initAppTypeKeyMap();


ngx.print("执行初始化结束");