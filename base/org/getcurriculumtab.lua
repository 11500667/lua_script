--[[
#��ѩ�� 2015-2-3
#��������ȡ�γ̱�
]]

ngx.header.content_type = "text/plain;charset=utf-8"

-- 1.��ȡ����
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--����mysql���ݿ�
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password, 
    max_packet_size = 1024*1024
}

local cjson = require "cjson"

--��ȡ����
local person_id = tostring(ngx.var.cookie_background_person_id)
local stage_id = args["stage_id"]
local xq_id = args["xq_id"]
local class_id = args["class_id"]

local res = mysql_db:query("select a.id,a.week,a.kejie,b.subject_name,a.subject_id from t_base_kechengbiao a,t_dm_subject b where a.SUBJECT_ID = b.SUBJECT_ID and a.CLASS_ID = "..class_id.." and b.STAGE_ID = "...stage_id." and a.XQ_ID = "..xq_id.." and a.PERSON_ID = "..person_id..";")

local curriculumInfo = {}

if res == nil or res = "" then 
	curriculumInfo.success = false;
	curriculumInfo.info = "�ð༶û����Ϣ��"
	ngx.say(cjson.encode(curriculumInfo))
	return
else
	local rlist = {}
	for i=1,#res do
		local list = {}
		list.id = res[i]["id"]
		list.week = res[i]["week"]
		list.subject_name = res[i]["subject_name"]
		list.subject_id = res[i]["subject_id"]
		table.insert(rlist,list)
	end
	curriculumInfo.success = true
	curriculumInfo.info = rlist
	ngx.say(cjson.encode(curriculumInfo))
end

-- ��mysql���ӹ黹�����ӳ�
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end
