local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--版本ID
if args["scheme_id"] == nil or args["scheme_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"scheme_id参数错误！\"}")
    return
end
local scheme_id = args["scheme_id"]

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

local structure_res_1 = mysql_db:query("SELECT structure_id FROM t_resource_structure WHERE level=1 AND is_root = 1 AND  scheme_id_int = "..scheme_id)
local root_structure_id = structure_res_1[1]["structure_id"]

local structure_res_2 = mysql_db:query("SELECT structure_id,structure_name FROM t_resource_structure WHERE scheme_id_int = "..scheme_id.." and level = 2 AND is_delete = 0 ORDER BY SORT_ID ")

 local list = {}
for i=1,#structure_res_2 do
	local list_tab = {}
	local structure_list_tab = {}
	local structure_res_3 = mysql_db:query("SELECT structure_id,structure_name FROM t_resource_structure WHERE  is_delete = 0 AND parent_id = "..structure_res_2[i]["structure_id"].." ORDER BY SORT_ID ")
	for j=1,#structure_res_3 do
		local structure_list = {} 
		structure_list["structure_id"] = structure_res_3[j]["structure_id"]
		structure_list["structure_name"] = structure_res_3[j]["structure_name"]
		structure_list_tab[j] = structure_list
	end	
	list_tab["glass_id"] = structure_res_2[i]["structure_id"]
	list_tab["glass_name"] = structure_res_2[i]["structure_name"]
	list_tab["structure_list"] = structure_list_tab
	list[i] = list_tab
end

local result = {} 
result["success"] = true
result["structure_id"] = root_structure_id
result["list"] = list

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

