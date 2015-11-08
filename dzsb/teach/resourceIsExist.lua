#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#������ 2015-01-23
#����������resource_id����Ա��Ϣ�����Ƿ���Ҫ����
]]
--1.��ò�������
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
 local myts = require "resty.TS";
 
 --���ղ��������жϲ����Ƿ���ȷ
--���resource_id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id��������\"}")
    return
end
local resource_id = args["resource_id"];
--��ò���person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id��������\"}")
    return
end
local person_id = args["person_id"];

--��ò���identity_id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id��������\"}")
    return
end
local identity_id = args["identity_id"];

--����SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--��ȡssdb�洢��resource_id

local resource_info=ssdb_db:multi_hget("bag_res_"..resource_id,"create_person","identity_id");
if not resource_info then
    ngx.say("{\"success\":false,\"info\":\"2\"}")
    return
end 
local create_person = resource_info[2]
local identity_id_db = resource_info[4]
--ngx.log(ngx.ERR,"create_person====="..create_person.."identity_id_db==="..identity_id_db)
if  person_id == create_person and  identity_id==identity_id_db then
   -- ngx.log(ngx.ERR,"SSSSSS")
     ngx.say("{\"success\":true,\"info\":\"1\"}")
else
    ngx.say("{\"success\":false,\"info\":\"2\"}")
end
--[[
if person_id == create_person then
   if identity_id~=identity_id_db then
       
          return
   end
else 
   ngx.say("{\"success\":true,\"info\":\"1\"}")
end

--]]

--�Żص�SSDB���ӳ�
ssdb_db:set_keepalive(0,v_pool_size)