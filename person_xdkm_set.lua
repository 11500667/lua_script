ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"cookie_token参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取redis中该用户的token
local redis_token,err = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"token")
if not redis_token then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--验证cookie中的token和redis中存的token是否相同
if redis_token ~= cookie_token then
    ngx.say("{\"success\":\"false\",\"info\":\"错误的验证信息！\"}")
    return
end
-- ngx.log(ngx.ERR, "===>===>===>===> 保存用户的学段科目 <===<===<===<===");
-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["stage_id"] == nil or args["stage_id"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数stage_id为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数stage_id不能为空！\"}");
    return;
elseif args["subject_id"] == nil or args["subject_id"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数subject_id为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数subject_id不能为空！\"}");
    return;
elseif args["stage_name"] == nil or args["stage_name"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数stage_name为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数stage_name不能为空！\"}");
    return;
elseif args["subject_name"] == nil or args["subject_name"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数subject_name为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数subject_name不能为空！\"}");
    return;
elseif args["scheme_id"] == nil or args["scheme_id"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数scheme_id为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数scheme_id不能为空！\"}");
    return;
elseif args["structure_id"] == nil or args["structure_id"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数structure_id为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数structure_id不能为空！\"}");
    return;
elseif args["is_root"] == nil or args["is_root"]=="" then
	ngx.log(ngx.ERR, "===> savePersonXdkm ===> 参数is_root为空!!");
    ngx.print("{\"success\":true,\"info\":\"参数is_root不能为空！\"}");
    return;

end

local stage_id     = ngx.var.arg_stage_id;
local subject_id   = ngx.var.arg_subject_id;
local stage_name   = ngx.var.arg_stage_name; 
local subject_name = ngx.var.arg_subject_name;
local scheme_id    = ngx.var.arg_scheme_id; 
local structure_id = ngx.var.arg_structure_id; 
local is_root      = ngx.var.arg_is_root; 

local pid_str = "";
if args["pid_str"] ~= nil and args["pid_str"]~="" then
    pid_str = ngx.var.arg_pid_str;
    pid_str = ngx.decode_base64(pid_str)
end

-- ngx.log(ngx.ERR, "[sj_log] -> [xdkm]-> stage_id:[" .. stage_id .. "],subject_id:[" .. subject_id .. "],stage_name:[" .. stage_name .. "],subject_name:[" .. subject_name .. "],scheme_id:[" .. scheme_id .. "],structure_id:[" .. structure_id .. "],is_root:[" .. is_root .. "],pid_str:[" .. pid_str .. "]");

-- ngx.log(ngx.ERR, "===> stage_name base64 [解码前]===> ", stage_name);
-- ngx.log(ngx.ERR, "===> stage_name base64 [解码后] ===> ", ngx.decode_base64(stage_name));
-- ngx.log(ngx.ERR, "===> subject_name base64 [解码前]===> ", subject_name);
-- ngx.log(ngx.ERR, "===> subject_name base64 [解码后] ===> ", ngx.decode_base64(subject_name));

cache:hmset("person_"..cookie_person_id.."_"..cookie_identity_id,"stage_id",stage_id,"subject_id",subject_id,"stage_name",ngx.decode_base64(stage_name),"subject_name",ngx.decode_base64(subject_name),"scheme_id",scheme_id,"structure_id",structure_id,"is_root",is_root,"pid_str",pid_str)

local async_write_json = "{\"action\":\"sp_resource_person_record\",\"need_newcache\":\"0\",\"paras\":{\"v_person_id\":\""..cookie_person_id.."\",\"v_identity_id\":\""..cookie_identity_id.."\",\"v_stage_id\":\""..stage_id.."\",\"v_stage_name\":\""..ngx.decode_base64(stage_name).."\",\"v_subject_id\":\""..subject_id.."\",\"v_subject_name\":\""..ngx.decode_base64(subject_name).."\",\"v_scheme_id\":\""..scheme_id.."\",\"v_structure_id\":\""..structure_id.."\",\"v_is_root\":\""..is_root.."\",\"v_pid_str\":\""..pid_str.."\"}}";

cache:lpush("async_write_list", async_write_json)

--db:query("INSERT INTO T_BASE_PERSON_XDKM(PERSON_ID,IDENTITY_ID,STAGE_ID,STAGE_NAME,SUBJECT_ID,SUBJECT_NAME) VALUES ("..cookie_person_id..","..cookie_identity_id..","..stage_id..",\'"..ngx.decode_base64(stage_name).."\',"..subject_id..",\'"..ngx.decode_base64(subject_name).."\')")

ngx.say("{\"success\":true}")
