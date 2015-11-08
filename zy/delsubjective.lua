--[[
学生删除自己的主观题
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
local path = args["path"]
local resource_id = args["resource_id"]
if not zy_id or string.len(zy_id) == 0 or not path or string.len(path)==0 or not resource_id or string.len(resource_id)==0 then
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
local truepath=ngx.decode_base64(path)

if(truepath~="-1") then
    --ngx.log(ngx.ERR, "@@@@@@@@@@@@@@@@@@@@"..truepath.."@@@@@@@@@@@@@@@@@@@@");
	ssdb:hdel("homework_answersubjective_"..student_id.."_"..zy_id,truepath);
	ssdb:hdel("zy_zg_answer_img"..student_id.."_"..zy_id,truepath);
end
ssdb:hdel("zy_zg_answer_noimg"..student_id.."_"..zy_id,resource_id)
say("{\"success\":true,\"info\":\"删除成功！\"}")
ssdb:set_keepalive(0,v_pool_size)
