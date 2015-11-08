local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--news_id参数 新闻ID
if args["id"] == nil or args["id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"id参数错误！\"}")
	return
end
local id = args["id"]

local cjson = require "cjson" 

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local news_info = ssdb_db:multi_hget("news_info_"..id, "title","content","create_time","create_person","create_person_name","column_id","column_name","regist_id","ts","image")

local result = {}
result["success"] = true
result["id"] = id
result["title"] = news_info[2]
result["content"] = news_info[4]
result["create_time"] = news_info[6]
result["create_person"] = news_info[8]
result["create_person_name"] = news_info[10]
result["column_id"] = news_info[12]
result["column_name"] = news_info[14]
result["regist_id"] = news_info[16]
result["ts"] = news_info[18]
result["image"] = news_info[20]

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print(cjson.encode(result))