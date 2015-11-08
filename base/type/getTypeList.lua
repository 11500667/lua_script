local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--系统ID  1：素材 2：试题 3：试卷 4：备课 5：微课

if args["system_id"] == nil or args["system_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"system_id参数错误！\"}")
    return
end

local system_id = args["system_id"];

if args["type_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"type_id参数错误！\"}")
    return
end

local type_id = args["type_id"];


--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

local beike_str = system_id;
if system_id =="4" then
   beike_str = system_id..",".."10"
end

local type_res = mysql_db:query("SELECT id,type_name FROM t_base_type WHERE b_use = 1 AND system_id in ("..beike_str..");")
--ngx.log(ngx.ERR,"--------".."SELECT id,type_name FROM t_base_type WHERE b_use = 1 AND system_id in ("..beike_str..")")
local type_tab = {}

if type_id ~= "1" then
	if  system_id == "4" then
		 local tab={};
		 tab["id"] = 0;
		 tab["type_name"] = "全部类型";
		type_tab[1] = tab;
	end
	if  system_id == "4" then
		 local tab={};
		 tab["id"] = 1;
		 tab["type_name"] = "资源包";
		 type_tab[2] = tab;
	end
	if  system_id == "3" then
		 local tab={};
		 tab["id"] = 0;
		 tab["type_name"] = "全部类型";
		type_tab[1] = tab;
	end
	
end

for i=1,#type_res do
	local type_info = {}
	type_info["id"] = type_res[i]["id"]
	type_info["type_name"] = type_res[i]["type_name"]
	if  system_id == "4" and  type_id ~= "1" then
	   type_tab[i+2] = type_info
	elseif system_id == "3" and  type_id ~= "1" then
	   type_tab[i+1] = type_info
	else
	   type_tab[i] = type_info
	end 
end


local result = {} 
result["success"] = true
result["list"] = type_tab

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))





