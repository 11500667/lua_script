#ngx.header.content_type = "text/plain;charset=utf-8"

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["chat_type"] == nil or args["chat_type"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数chat_type不能为空！\"}");
	return;
elseif args["chat_content"] == nil or args["chat_content"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数chat_content不能为空！\"}");
	return;
end 

-- 会话类型；1为系统公告， 2为系统个人消息
local chatType = tonumber(args["chat_type"]);
-- 消息内容
local chatContent = tostring(args["chat_content"]);
-- 会话名称
local chatName = "系统消息";

--连接redis服务器
local redis = require "resty.redis";
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\"发送失败\"}");
	ngx.log(ngx.ERR, "====> 获取redis连接失败！");
    return
end

-- 会话ID
local chatId = nil;
-- 头像
local avatarUrl = "images/head_icon/sys/speaker.png";

if chatType==1 then
	chatId = 100;
elseif chatType==2 then
	if args["person_id"] == nil or args["person_id"]=="" then
		ngx.say("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
		return;
	elseif args["identity_id"] == nil or args["identity_id"]=="" then
		ngx.say("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
		return;
	end
		
	-- 人员ID
	local personId = tostring(args["person_id"]);
	local identityId = tostring(args["identity_id"]);
	
	chatId = cache: hget("person_" .. personId .. "_" .. identityId, "sys_chatid");
	if chatId == ngx.null then
		ngx.say("{\"success\":\"false\",\"info\":\"发送信息失败！\"}");
		ngx.log(ngx.ERR, "====> 从用户缓存中获取个人系统会话ID失败！");
		return;
	end
else
	ngx.say("{\"success\":\"false\",\"info\":\"参数的值不正确\"}");
	ngx.log(ngx.ERR, "====> 参数chat_type的值只能为1和2，当前值为" .. chatType .. "！");
    return;
end

chatContent = ngx.decode_base64(chatContent)
chatContent = string.gsub (chatContent, "\n", "")
chatContent = string.gsub (chatContent, "\r", "")

--时间截
local ts = tostring(ngx.now()*1000)
--发送时间
local sendTime = tostring(ngx.localtime())


--向一个有序集合中插入
cache:zadd("msgContent_"..chatId, ts, "{\"chat_id\":\""..chatId.."\",\"chat_name\":\""..chatName.."\",\"chat_content\":\""..chatContent.."\",\"chat_time\":\""..sendTime.."\",\"send_person\":\"100000000\",\"send_identity\":\"100000000\",\"ts\":\""..ts.."\",\"chat_url\":\""..avatarUrl.."\"}")


--写队列
local str = "{\"action\":\"sp_add_msg\",\"need_newcache\":\"0\",\"paras\":{\"v_CHAT_ID\":\""..chatId.."\",\"v_MSG_TYPE\":\""..chatType.."\",\"v_MSG_CONTENT\":\""..chatContent.."\",\"v_SEND_TIME\":\""..sendTime.."\",\"v_ts\":\""..ts.."\",\"v_PERSON_ID\":\"100000000\",\"v_PERSON_NAME\":\""..chatName.."\",\"v_IDENTITY_ID\":\"100000000\",\"v_SYS_MSG_CODE\":\"000000\",\"v_AVATAR_URL\":\""..avatarUrl.."\"}}"

cache:lpush("async_write_list",str)

ngx.say("{\"success\":true,\"info\":\"消息发送成功！\"}")


-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end