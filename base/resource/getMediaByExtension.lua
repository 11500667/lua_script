#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-06
#描述：根据扩展名获得对应的媒体类型
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
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

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
local resultJson={};
local filter_str = "";
if type_id == "1" then
	local sel_extension = "SELECT extension_name,mediatype_name FROM t_resource_extension WHERE extension_name != 'other'";
	local result_res, err, errno, sqlstate = db:query(sel_extension)
		if not result_res then
				 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				  ngx.say("{\"success\":false,\"info\":\"查询失败！\"}")
				 return
		end


	for i=1,#result_res do
		--[[local tab = {};
		tab.extension_name = result_res[i]["extension_name"];
		tab.mediatype_name = result_res[i]["mediatype_name"];
		
		tab.filter = result_res[i]["mediatype_name"].."文件("..string.upper(result_res[i]["extension_name"])..")|*."..result_res[i]["extension_name"];
		table.insert(resultJson,tab);
		]]
		filter_str = filter_str ..","..result_res[i]["mediatype_name"].."文件("..string.upper(result_res[i]["extension_name"])..")|*."..result_res[i]["extension_name"];
	end
	 filter_str = string.sub(filter_str,2,#filter_str)
elseif type_id == "2" then
    filter_str = "视频文件(.AVI)|*.avi,视频文件(.MP4)|*.mp4,视频文件(.WMV)|*.wmv,视频文件(.FLV)|*.flv";
   
--[[   local tab_1 ={};
	tab_1.extension_name = "avi";
	tab_1.mediatype_name = "视频";
	tab_1.filter = "视频文件(.AVI)|*.avi";
	table.insert(resultJson,tab_1);
	
	 local tab_2 ={};
	tab_2.extension_name = "mp4";
	tab_2.mediatype_name = "视频";
	tab_2.filter = "视频文件(.MP4)|*.mp4";
	table.insert(resultJson,tab_2);
	
	 local tab_3 ={};
	tab_3.extension_name = "wmv";
	tab_3.mediatype_name = "视频";
	tab_3.filter = "视频文件(.WMV)|*.wmv";
	table.insert(resultJson,tab_3);
	
	 local tab_4 ={};
	tab_4.extension_name = "flv";
	tab_4.mediatype_name = "视频";
	tab_4.filter = "视频文件(.FLV)|*.flv";
	table.insert(resultJson,tab_4);
	]]
end

resultJson.success = true;
resultJson.filter = filter_str;
local cjson = require "cjson";
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);
