#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-01-29
#描述：批量插入md5_ques_[md5]的ssdb
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["param"] == nil or args["param"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数param不能为空！\"}");
	return;
end

-- 参数结构：
-- {
	-- save_list:[
		-- {
			-- ssdb_key : "md5_ques_[md5]",
			-- hash_list : [
				-- {
					-- hash_key   : "file_id",
					-- hash_value : "sdfsdfsdfsd-dsfsd-sdfsd-sdfsdf"
				-- },
				-- {
					-- hash_key   : "file_id",
					-- hash_value : "sdfsdfsdfsd-dsfsd-sdfsd-sdfsdf"
				-- }
			-- ]
		-- },
		-- {
			
		-- }
	-- ]
-- }

local paramBase64   = args["param"];

local paramJsonStr  = ngx.decode_base64(paramBase64);
local cjson = require "cjson";
local paramJson = cjson.decode(paramJsonStr);

local syncList  = paramJson.save_list;

local cjson   = require "cjson";
-- 获取SSDB连接
local ssdblib = require "resty.ssdb";
local ssdb    = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\"获取ssdb连接失败！\"}")
    ngx.exit(ngx.HTTP_OK);
end

ssdb:init_pipeline();
--循环获取参数
for i=1, #syncList do
	local ssdbKey  = syncList[i].ssdb_key;
	local hashList = syncList[i].hash_list;	
	local kvArray  = {};
	
	for j=1, #hashList do
		local hashKey    = hashList[j].hash_key;
		local hashValue  = hashList[j].hash_value;
		kvArray[hashKey] = hashValue		
	end
	
	local result, err = ssdb:multi_hset(ssdbKey, kvArray);

end 

--管道提交
local results, err = ssdb:commit_pipeline()
if not results then  
    ngx.print("{\"success\":false,\"info\":\"保存数据失败！\"}");
    ngx.exit(500);
end

ngx.print("{\"success\":true,\"info\":\"保存数据成功！\"}");

-- 将SSDB连接归还连接池
ssdb:set_keepalive(0,v_pool_size);









