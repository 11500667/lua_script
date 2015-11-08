#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-29
#描述：根据参数id获取answer答案
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取参数id，并判断参数是否正确
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end

local id = args["id"];

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local answer ;
local res = {}
--根据id去缓存中获得json_answer的值
local redis_answer = cache:hget("question_"..id,"json_answer")
local json_answer1 = redis_answer
--ngx.log(ngx.ERR,"json_answer1"..json_answer1)

if json_answer1 == "-1" then 
   ngx.say("{\"success\":false,\"info\":\"该题答案不存在！\"}")
   return
  else 
	   --ngx.log(ngx.ERR,"ngx.decode_base64============="..ngx.decode_base64(json_answer1).."------------------")
	   --将空格77u/替换
	   json_answer1 = string.gsub(json_answer1, "77u/", "");
	   json_answer1 =ngx.decode_base64(json_answer1);

	   --ngx.log(ngx.ERR, "===> json_answer1 ===> ", json_answer1);
	   json_answer = cjson.decode(json_answer1);
	  
	--  ngx.log(ngx.ERR,"json_answer.answer==-====="..#json_answer.t_child_answer)
  --for i=1,#json_answer do
    answer  = json_answer.answer
	question_id_char=json_answer.question_id_char
	 -- ngx.log(ngx.ERR,"answer"..json_answer.answer)
		  
end
--local result ={}
--result.list = res
--result.success = true

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
ngx.say("{\"success\":true,\"answer\":\""..answer.."\",\"question_id_char\":\""..question_id_char.."\"}")
--ngx.say(answer);

