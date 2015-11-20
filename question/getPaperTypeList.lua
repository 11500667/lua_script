
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
local cjson = require "cjson"

local sql = "SELECT id,type_name FROM t_base_type WHERE b_use = 1 AND system_id=3";

local type_res, err, errno, sqlstate = db:query(sql);

local type_tab = {};
for i=1,#type_res do
	local type_info = {}
	type_info["paperAppType"] = type_res[i]["id"]
	type_info["paperAppTypeName"] = type_res[i]["type_name"]
	table.insert(type_tab, type_info);
end


local result = {} 
result["success"] = true
result["list"] = type_tab

DBUtil: keepDbAlive(db);

ngx.print(cjson.encode(result));





