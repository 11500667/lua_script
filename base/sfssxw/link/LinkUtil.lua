--[[
#赵夯 2015-09-09
#描述：针对友情链接的工具类
]]

dofile("/usr/local/lua_script_sfssxw/common/common.lua")
local _linkUtil = {};
--[[
	局部函数： 	根据一个友情链接的id值，获取的table返回友情链接信息
	作者：     	赵夯 2015-09-09
	参数：     	link_id  
	返回值：  	友情链接table
]]
local function getlinkInfoById(self,link_id)	

	local mysql = require "resty.mysql"
	local db, err = mysql:new()
	if not db then
		status = "FAILURE"
		info = "failed to instantiate mysql: " .. err
		return
	end

	db:set_timeout(1000) -- 1 sec

	--连接数据库

	local db = mysql:new()
	local ok, err, errno, sqlstate = db:connect{
		host = v_mysql_ip,
		port = v_mysql_port,
		database = v_mysql_database,
		user = v_mysql_user,
		password = v_mysql_password,
		max_packet_size = 1024*1024
	}

	if not ok then
		status = "FAILURE"
		info = "failed to connect: " .. err .. "：" .. errno .. " " .. sqlstate
		return
	end
	
	local select_sql = "SELECT	link_id,link_name,link_url,image_path,image_name,image_ext	FROM t_sfssxw_link WHERE link_id="..link_id.." "	
	
	local select_res, err, errno, sqlstate = db:query(select_sql)
		if not select_res then
		ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end
	--将结果返回页面
	local cjson = require "cjson"

	while err == "again" do
		select_res, err, errno, sqlstate = db:read_result()
		if not select_res then
			ngx.log(ngx.ERR, "bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")
			return ngx.exit(500)
		end
	end

	local ok, err = db:set_keepalive(0, v_pool_size)
	if not ok then
		ngx.say("failed to set keepalive: ", err)
		return
	end

	local result = {} 
	result["link_id"] = select_res[1]["link_id"];
	result["link_name"] = select_res[1]["link_name"];
	result["link_url"] = select_res[1]["link_url"];
	result["image_path"] = select_res[1]["image_path"];
	result["image_name"] = select_res[1]["image_name"];
	result["image_ext"] = select_res[1]["image_ext"];
	
	

	return result
end
_linkUtil.getlinkInfoById = getlinkInfoById;

return _linkUtil;

