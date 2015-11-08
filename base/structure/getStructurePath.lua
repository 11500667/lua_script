#ngx.header.content_type = "text/plain;charset=utf-8"


--����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--�ṹid
local structure_id = tostring(args["structure_id"])
--�ж��Ƿ��н��ID����
if structure_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"structure_id��������\"}")
    return
end
--���ݽṹid���λ��
local curr_path = ""
 local structures = cache:zrange("structure_code_"..structure_id,0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
       curr_path = curr_path..structure_info[1].."->"
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)

--redis�Ż����ӳ�
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

--local  structure_path = "{\"success\":\"true\",\"structure_path\":\""..curr_path.."\"}"
ngx.print(curr_path);
