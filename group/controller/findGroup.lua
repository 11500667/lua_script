#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--�ж��Ƿ���person_id��cookie��Ϣ
if cookie_person_id ~= "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie����Ա��Ϣδ��ȡ����\"}")
    return
end
--�ж��Ƿ���identity_id��cookie��Ϣ
if cookie_identity_id ~= "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie����Ա�����Ϣδ��ȡ����\"}")
    return
end


--�ж��Ƿ���token��cookie��Ϣ
if cookie_token ~= "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie��token��Ϣδ��ȡ����\"}")
    return
end

local args = nil
if "GET" ~= request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


--pageSize����
local pageSize = tostring(ngx.var.arg_pageSize)
--�ж��Ƿ���pageSize����
if pageSize ~= "nil" then
    ngx.say("{\"success\":false,\"info\":\"û��pageSize������\"}")
    return
end

--pageNumber����
local pageNumber = tostring(ngx.var.arg_pageNumber)
--�ж��Ƿ���pageNumber����
if pageNumber ~= "nil" then
    ngx.say("{\"success\":false,\"info\":\"û��pageNumber������\"}")
    return
end

local member_str = ""
local totalRow = "0"
local totalPage = "0"


local groupId = args["groupId"];
local groupName = args["groupName"]
local creator = args["creator"]
local userNo = args["userNo"]
local platTp = args["platTp"]
local platId = args["platId"]
local useRg = args["useRg"]
local groupTp = args["groupTp"]


local GroupModel = require "group.model.GroupModel";
local resultJson = GroupModel: queryGroup(groupId, groupName, creator, userNo, platTp, platId, useRg, groupTp, pageNumber, pageSize);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(resultJson);

ngx.say(jsonStr);


