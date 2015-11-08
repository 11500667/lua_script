#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil

if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--判断是否有试卷ID参数
if args["question_info_id"]==nil or args["question_info_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"question_info_id参数错误！\"}")
    return
end

if args["question_id_char"]==nil or args["question_id_char"]=="" then
    ngx.say("{\"success\":false,\"info\":\"question_id_char参数错误！\"}")
    return
end

ngx.log(ngx.ERR,"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO")

local question_ids = tostring(args["question_info_id"])  
local question_id_chars = tostring(args["question_id_char"])

-- 获取ts值
local t=ngx.now();
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
      n=n..string.rep("0",19-string.len(n))
local question_id_int = Split(question_ids,",")
local question_id_char = Split(question_id_chars,",")

for i=1,#question_id_int do
	local ts = n;
	local count =  db:query("update t_tk_question_info set b_delete = 1,update_ts = "..ts.." where question_id_char = "..question_id_char[i])
	if count ~=nil then
		db:query("update t_tk_question_my_info set b_delete = 1,update_ts = "..ts.." where question_id_char ="..question_id_char[i])
	end
end	
ngx.say("{\"success\":true}")		
	