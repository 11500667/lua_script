#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-10
#描述：修改微课中正在上传资源个数的方法
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

 --连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--传参数
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

if args["type"] == nil or args["type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
local type_id  = tostring(args["type"]);

local cjson = require 'cjson';
local resultJson={};

if type_id == "3" then
	
	local upload_info = ssdb_db:get("upload_bk_"..obj_id_int);
	ngx.log(ngx.ERR,"----------"..upload_info[1])
	local upload_info_list = Split(upload_info[1],",");

	local total_count;
	if #upload_info[1] == 0 then
		total_count= 0;
	else
		total_count= #upload_info_list;
	end
	resultJson.total_count = total_count;
	resultJson.success = true;
	
else
	local upload_info = ssdb_db:get("upload_wkds_"..obj_id_int);
	ngx.log(ngx.ERR,"----------"..upload_info[1])
	local upload_info_list = Split(upload_info[1],",");

	local total_count;
	if #upload_info[1] == 0 then
		total_count= 0;
	else
		total_count= #upload_info_list;
	end

	local sp_count = 0;
	local sc_count = 0;
	local design_count = 0;
	local study_count = 0;
	local practice_count = 0;


	for i=1,#upload_info_list do
		local upload_temp = upload_info_list[i];
		local upload_type = ssdb_db:multi_hget(upload_temp,"upload_type");
		if upload_type[2] == "1" then
			sp_count = sp_count+1;
		elseif upload_type[2] == "2" then
			sc_count = sc_count+1;
		elseif upload_type[2] == "5" then
			design_count = design_count+1;
		elseif upload_type[2] == "4" then
			study_count = study_count+1;
		elseif upload_type[2] == "3" then
			practice_count = practice_count+1;
		end	
		end

		resultJson.total_count = total_count;
		resultJson.sp_count = sp_count;
		resultJson.sc_count = sc_count;
		resultJson.design_count = design_count;
		resultJson.study_count = study_count;
		resultJson.practice_count = practice_count;
		resultJson.success = true;

end



local responseJson = cjson.encode(resultJson);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say(responseJson);
