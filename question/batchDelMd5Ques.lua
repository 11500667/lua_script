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

if args["param_json"] == nil or args["param_json"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数param_json不能为空！\"}");
	return;
end

-- 参数结构：
-- {
	-- del_list:[
		-- {
			-- ssdb_key : "md5_ques_[md5]",
			-- hash_keys : [
				-- [person_id]_[identity_id]_[structure_id],
				-- [person_id]_[identity_id]_[structure_id]				
			-- ]
		-- },
		-- {
			
		-- }
	-- ]
-- }

local paramBase64   = args["param_json"];

local paramJsonStr  = ngx.decode_base64(paramBase64);
ngx.log(ngx.ERR, " ===> paramJson base64解码后：===> ", paramJsonStr);
local cjson = require "cjson";
local paramJson = cjson.decode(paramJsonStr);

local syncList  = paramJson.del_list;
ngx.log(ngx.ERR, "===> syncList ===> ", type(syncList));

local SSDBUtil = require "common.SSDBUtil";
local ssdb = SSDBUtil:getDb;


ssdb:init_pipeline();
--循环获取参数


ngx.log(ngx.ERR,"0000===================>"..#syncList);
for i=1, #syncList do
	local ssdbKey  = syncList[i];
	local hashList = "is_struc_repeat";
	ngx.log(ngx.ERR,"===================>"..ssdbKey);
	local result, err = ssdb:multi_hdel(ssdbKey, unpack(hashList));
	ngx.log(ngx.ERR, "===> ssdbKey:", ssdbKey, " ===> result: ", cjson.encode(result));
	
end 

--管道提交
local results, err = ssdb:commit_pipeline()
if not results then  
    ngx.print("{\"success\":false,\"info\":\"删除数据失败！\"}");
	ngx.log(ngx.ERR, "===> batchDelMd5Ques 删除数据失败！===> ");
    ngx.exit(500);
end

ngx.print("{\"success\":true,\"info\":\"删除数据成功！\"}");

-- 将SSDB连接归还连接池
ssdb:set_keepalive(0,v_pool_size);









