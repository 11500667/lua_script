--[[
通过人员id跟身份id获取人员信息
@Author chuzheng
@data 2015-2-9
--]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--引用json
local cjson = require "cjson"

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--identity_id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]


--连接ssdb服务器
local ssdb = require "resty.ssdb"
local cache = ssdb:new()
local ok,err = cache:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--获取基础数据接口，通过人员id，身份id获取人员信息
local personinfo=ngx.location.capture("/dsideal_yy/space/base/getPersonInfoByLoginname",
{      
        args={person_id=person_id,identity_id=identity_id}
})
local person
if personinfo.status == 200 then                             
	person = cjson.decode(personinfo.body)                  
                                 
else                          
        ngx.say("{\"success\":false,\"info\":\"调用基础数据获取人员信息失败!\"}")                       
        return                         
end

--获取空间中的个性签名
local json = cache:get("space_signature_"..person_id.."_"..identity_id)
if not json then
	ngx.say("{\"success\":false,\"info\":\"读取个人签名信息失败！\"}")
	return
end
person.signature=json[1]



--ssdb放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.say(cjson.encode(person))
