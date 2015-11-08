local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取TS
local myts = require "resty.TS";
local ts =  myts.getTs();

--[[
ngx.print(ts)
ngx.print("===================")
ngx.print(string.sub(ts,2,#ts))
ngx.print("===================")
ngx.print(string.sub(ts,1,1))


ssdb_db:zset("tuijian","1",tonumber(ts+3000000000000000000))


ngx.print("**********************")
ngx.print(ngx.today());
ngx.print("**********************")
ngx.print(ngx.now());
ngx.print("**********************")
ngx.print(ngx.update_time());


--{"http://stu.baidu.com/n/searchpc?queryImageUrl=http://p2.vanclimg.com/product/0/1/8/0187455/lists170/51072.jpg"}

local xxTj,czTj = ngx.location.capture_multi({
	{"http://www.hao123.com/api/tnwhilte?tn=sitehao123&_=1429497624873"},
	{"http://www.hao123.com/api/tnwhilte?tn=sitehao123&_=1429497624873"}
})
]]

--ssdb_db:setx("test","abc",20)
ngx.print("**********************")
local cz = ssdb_db:zexists("test1","a")
ngx.print(tostring(cz[1]))






