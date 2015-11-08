--[[
学生上传主观题
@Author chuzheng
@Date 2015-1-5
--]]
local say = ngx.say

--获取前台传过来的参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
        args,err = ngx.req.get_uri_args()
else
        ngx.req.read_body()
        args,err = ngx.req.get_post_args()
end

if not args then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
end


local student_id = ngx.var.cookie_person_id
local zy_id = args["zy_id"]

if not zy_id or string.len(zy_id)==0 then
	 say("{\"success\":false,\"info\":\"参数错误！\"}")
	 return
end
--引用模块
local ssdblib = require "resty.ssdb"
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--前台上传的作业
--[[ local path = args["path"]
local paths = Split(ngx.decode_base64(path),",")
for m=1,#paths do
	ssdb:hset("homework_answersubjective_"..student_id.."_"..zy_id,paths[m],"")
end ]]


--改动* start 获得前台传来的资源ID
local resource_ids = args["resource_ids"]
local ids = Split(ngx.decode_base64(resource_ids),",")
for i=1,#ids do
	local img_res = Split(ids[i],"_")
	if img_res[2] ~= "1" then
		ssdb:hset("homework_answersubjective_"..student_id.."_"..zy_id,img_res[2],"")
		ssdb:hset("zy_zg_answer_img"..student_id.."_"..zy_id,img_res[2],img_res[1])
	else
		ssdb:hset("zy_zg_answer_noimg"..student_id.."_"..zy_id,img_res[1],"")
	end
end
--改动* end
say("{\"success\":true,\"info\":\"上传成功\"}")
ssdb:set_keepalive(0,v_pool_size)
