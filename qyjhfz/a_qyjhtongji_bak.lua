--[[
����������ͳ��
@Author  chenxg
@Date    2015-03-17
--]]

local say = ngx.say

--����ģ��
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--�ж�request����, ����������
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
--�������ID
local qyjh_id = args["qyjh_id"]
--��ǰ�û�
local person_id = args["person_id"]
--1����ѧ������Աͳ�� 2��Э�����ͷ��ͳ��
local user_type = args["user_type"]
--ͳ�����ͣ�1������ͳ�Ʒ���2��Э����ͳ�Ʒ���3��ѧУͳ�Ʒ���4������ͳ�Ʒ���
local tongji_type = args["tongji_type"]
local subject_id = args["subject_id"]
local keyword = args["keyword"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
local page_type = args["page_type"]


--�жϲ����Ƿ�Ϊ��
if not person_id or string.len(person_id) == 0 
	or not qyjh_id or string.len(qyjh_id) == 0
	or not user_type or string.len(user_type) == 0
	or not tongji_type or string.len(tongji_type) == 0
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or qyjh_id or user_type or tongji_type  or pageSize or pageNumber ��������\"}")
    return
end

--���ݷָ����ָ��ַ���
function Split(str, delim, maxNb)   
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result
end

if keyword=="nil" then
	keyword = ""
else  --��������ؼ��ֲ�Ϊ�վͰѴ�������base64���б���ת����ʵ������
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..";"
	else
		keyword = ""
	end
end

--����ssdb����
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
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
--����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
local dxqList = {}
local xztList = {}
local orgList = {}
local personList = {}
local xztCount = 0
local dtrCount = 0
local zyCount = 0
local hdzyCount = 0
local xxCount = 0 
local jsCount = 0
local hdCount = 0
if user_type == "1" then--��ѧ������Ա���ͳ��
	--��ȡ��ǰ�û�������Ĵ�ѧ��
	local dxqs = ssdb:hget("qyjh_manager_dxqs",person_id)
	if string.len(dxqs[1])>1 then
		local dxqids = Split(dxqs[1],",")
		returnjson.dxqCount = #dxqids-2
		for i=2,#dxqids-1,1 do
			local xzt_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_xzt_tj")
			local xx_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_xx_tj")
			local js_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_js_tj")
			local hd_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_hd_tj")
			local zy_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_zy_tj")
			local dtr_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_dtr_tj")
			
			xztCount = xztCount+tonumber(xzt_tj[1])
			--ngx.log(ngx.ERR,"---->"..xzt_tj[1].."<------")
			dtrCount = tonumber(dtrCount)+tonumber(dtr_tj[1])
			zyCount = tonumber(zyCount)+tonumber(zy_tj[1])
			xxCount = tonumber(xxCount)+tonumber(xx_tj[1])
			jsCount = tonumber(jsCount)+tonumber(js_tj[1])
			hdCount = tonumber(hdCount)+tonumber(hd_tj[1])
			
		end
		if tongji_type == "1" then--��ѧ������ͳ�Ʒ���
			local res_person = ngx.location.capture("/dsideal_yy/qyjhfz/getDxqByParams?qyjh_id="..qyjh_id.."&pageSize="..pageSize.."&pageNumber="..pageNumber.."&person_id="..person_id.."&keyword="..keyword.."")
			if res_person.status == 200 then
				dxqList = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"��ѯͳ����Ϣʧ�ܣ�\"}")
				return
			end
			returnjson.dxqList = dxqList.dxqList
		elseif tongji_type == "2" then--��ѧ��Э����ͳ�Ʒ���
			if not subject_id or string.len(subject_id) == 0
			then
				say("{\"success\":false,\"info\":\"subject_id ��������\"}")
				return
			end

			local res_person = ngx.location.capture("/dsideal_yy/qyjhfz/getXztByParams?subject_id="..subject_id.."&keyword="..keyword.."&person_id="..person_id.."&qyjh_id="..qyjh_id.."&page_type=3&pageSize="..pageSize.."&pageNumber="..pageNumber)
			if res_person.status == 200 then
				xztList = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"��ѯͳ����Ϣʧ��ʧ�ܣ�\"}")
				return
			end
			returnjson.xztList = xztList
		elseif tongji_type == "3" then--��ѧ��ѧУͳ�Ʒ���
			pageSize = tonumber(pageSize)
			pageNumber = tonumber(pageNumber)
			
			--��ȡЭ��������
			local getXztSql = "select qxt.org_id,count(1) as xzt_count from t_qyjh_xzt_tea qxt where b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") group by org_id";
			local xzt_res = mysql_db:query(getXztSql)
			
			--��ȡѧУ����Э����
			local getOrgXztSql = "select qxt.org_id,xzt_id from t_qyjh_xzt_tea qxt where b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") group by org_id,xzt_id";
			local org_xzt_res = mysql_db:query(getOrgXztSql)
			
			--��ȡ��ѧ���µ�ѧУ
			local getSchSql = "select o.org_id,o.org_name from t_qyjh_dxq_org qdo left join t_base_organization o on qdo.org_id = o.org_id where qdo.b_use = 1 and qdo.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") and o.org_name like '%"..keyword.."%' limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
			local org_res = mysql_db:query(getSchSql)
			local orgs = {}
			for i=1,#org_res do
				local org = {}
				local org_id = org_res[i]["org_id"]
				local org_name = org_res[i]["org_name"]
				org.org_id = org_id
				org.org_name = org_name
				--��������
				local dxqid = ssdb:hget("qyjh_org_dxq", org_id)
				local hdxq = ssdb:hget("qyjh_dxq", string.gsub(dxqid[1],",",""))
				org.dxq_name = cjson.decode(hdxq[1]).name
				--Э�������
				for j=1,#xzt_res do
					local xzt_org_id = xzt_res[j]["org_id"]
					local xzt_count = xzt_res[j]["xzt_count"]
					if org_id == xzt_org_id then
						org.xzt_count = xzt_count
						break
					end
				end
				--��ͷ�˸���
				local hdtrids = ssdb:hset("qyjh_dxq_org_dtrs",dxqid[1].."_"..org_id)
				local dtr_count = 0
				if string.len(hdtrids[1])>2 then
					dtr_count = #Split(hdtrids[1],",")-2
				end
				org.dtr_count = dtr_count
				--��ʦ����
				local getTeaSql = "SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 and BUREAU_ID = "..org_id.."";
				--ngx.log(ngx.ERR,"---->"..getTeaSql.."<------")
				local tea_res = mysql_db:query(getTeaSql)
				local tea_count = tea_res[1]["TEACOUNT"]
				org.tea_count = tea_count
				--������Դ
				local zy_count = ssdb:zget("qyjh_org_uploadcount",org_id)
				org.zy_count = zy_count
				--Э���
				local hd_count = 0
				for j=1,#org_xzt_res do
					local xzt_id = org_xzt_res[j]["xzt_id"]
					if org_id == org_xzt_res[j]["org_id"] then
						hd_count = hd_count+ tonumber(ssdb:hget("qyjh_xzt_tj",xzt_id.."_hd_tj")[1])
					end
				end
				org.hd_count = hd_count
				orgs[#orgs+1] = org
			end
			orgList.orgList = orgs 
			orgList.pageSize = pageSize
			orgList.pageNumber = pageNumber
			orgList.totalRow = xxCount
			local totalPage = math.floor((xxCount+pageSize-1)/pageSize)
			orgList.totalPage = totalPage
				
		elseif tongji_type == "4" then--����ͳ�Ʒ���
			local dxq_id = args["dxq_id"]
			local xzt_id = args["xzt_id"]
			local org_id = args["org_id"]
			--��ȡ��ʦ����
			local getPersonCountSql = "select count(DISTINCT tea_id) as teaCount from t_qyjh_xzt_tea qxt where qxt.b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..")";
			local personcount_res = mysql_db:query(getPersonCountSql)
			--��ȡЭ��������[ֻ��ѯ����Э����Ľ�ʦ]
			local getPersonSql = "select person_id,person_name,org_name,dxq_id from t_qyjh_xzt_tea qxt left join t_base_person p on p.person_id = qxt.tea_id left join t_base_organization o on o.org_id = qxt.org_id where qxt.b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") and person_name like '%"..keyword.."%' group by tea_id limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
			--��ȡЭ��������[��ѯ���н�ʦ]
			local getPersonSql2 = "select p.person_id,person_name,org_name,ifnull(qxt.dxq_id,0) as dxq_id from t_base_person p left join t_qyjh_xzt_tea qxt on p.person_id = qxt.tea_id and qxt.b_use = 1  LEFT JOIN t_qyjh_dxq_org qdo on qdo.org_id = p.bureau_id left join t_base_organization o on o.org_id = p.bureau_id where qdo.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") and person_name like '%"..keyword.."%' group by person_id limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
			--select p.person_id,person_name,org_name,ifnull(qxt.dxq_id,0) as dxq_id ,qdo.org_id from t_base_person p left join t_qyjh_xzt_tea qxt on p.person_id = qxt.tea_id and qxt.b_use = 1  LEFT JOIN t_qyjh_dxq_org qdo on qdo.org_id = p.bureau_id left join t_base_organization o on o.org_id = p.bureau_id where person_name like '%%' and qdo.org_id = p.bureau_id and qdo.dxq_id in(834) group by p.person_id limit 0,100


			--say(getPersonSql2)
			local person_res = mysql_db:query(getPersonSql2)
			local persons = {}
			for i=1,#person_res,1 do
				local person = {} 
				local tea_id = person_res[i]["person_id"]
				local person_name = person_res[i]["person_name"]
				local org_name = person_res[i]["org_name"]
				local dxq_id = person_res[i]["dxq_id"]
				
				person.person_id = tea_id
				person.person_name = person_name
				person.org_name = org_name
				
				--��ȡ����Э�������
				local xztids = ssdb:hget("qyjh_tea_xzts",tea_id)
				local xzt_count = 0
				if string.len(xztids[1])>2 then
					xzt_count = #Split(xztids[1],",")-2
				end
				person.xzt_count = xzt_count
				if dxq_id ~= "0" then
					--��ȡ��Դ��
					local zy_count = ssdb:zget("qyjh_dxq_tea_uploadcount_"..dxq_id,tea_id)[1]
					person.zy_count = zy_count
					--Э���
					local hd_count = ssdb:hget("qyjh_dxq_tj",dxq_id.."_hd_tj")[1]
					person.hd_count = hd_count
				else
					person.zy_count = 0
					person.hd_count = 0
				end
				
				persons[#persons+1] = person
			end
				personList.personList = persons
				personList.pageSize = pageSize
				personList.pageNumber = pageNumber
				local totalRow = jsCount--tonumber(personcount_res[1]["teaCount"])
				personList.totalRow = totalRow
				local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
				personList.totalPage = totalPage
		
		end
	end
elseif user_type == "2" then--Э�����ͷ�����ͳ��
	--��ȡЭ�����б���ͷ�ˡ�
	local xzts = ssdb:hget("qyjh_manager_xzts",person_id)
	local xztids = Split(xzts[1],",")
	if string.len(xzts[1])>2 then
		xztCount = #xztids-2
	end
	for i=2,#xztids-1,1 do
		--����Э�����ȡ��Դ��
		local zy_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_zy_tj")
		--����Э�����ȡ��������
		local js_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_js_tj")
		--����Э�����ȡ���
		local hd_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_hd_tj")
			
		zyCount = tonumber(zyCount)+tonumber(zy_tj[1])
		jsCount = tonumber(jsCount)+tonumber(js_tj[1])
		hdCount = tonumber(hdCount)+tonumber(hd_tj[1])
	end
	--����Э�����ȡ���Դ��
	local hdzyCountSql = "select count(1) as hdzyCount from t_base_publish p where p.pub_type = 3 and p.xzt_id in("..string.sub(xzts[1],2,string.len(xzts[1])-1)..") and hd_id != -1";
	local hdzy_res = mysql_db:query(hdzyCountSql)
	lhdzyCount = hdzy_res[1]["hdzyCount"]

	if tongji_type == "2" then--Э�����ͷ��_Э����ͳ�Ʒ���
		local pyear = args["year"]
		local pmonth = args["month"]
		local baseStart = pyear..pmonth
		local baseEnd = pyear..pmonth
		if pmonth == "" then
			baseStart = pyear.."00"
			baseEnd = pyear.."12"
		end
		local start_time = baseStart.."00000000"
		local end_time = baseEnd.."31235959"
		--��ȡЭ�����б�
		for i=2,#xztids-1,1 do
			local txzt = {}
			local xzt = ssdb:hget("qyjh_xzt",xztids[i])
			local temp = cjson.decode(xzt)
			txzt.name = temp.name
			
			--��ȡ��ʦ����(����ʱ���ڸ���֮ǰ �����˳�ʱ���ڸ���)
			local teaCountSql = "select count(1) as teaCount from t_qyjh_xzt_tea t where (t.b_use=1 and t.start_time < "..end_time..") or (t.b_use=0 and t.end_time BETWEEN "..start_time.." and "..end_time..")";
			--��ȡ��Դ��΢�Σ������ϴ�ʱ�䣩
		end
	end
end

returnjson.xztCount = xztCount
returnjson.dtrCount = dtrCount
returnjson.zyCount = zyCount
returnjson.hdzyCount = hdzyCount
returnjson.xxCount = xxCount
returnjson.jsCount = jsCount
returnjson.hdCount = hdCount

returnjson.dxqList = dxqList
returnjson.personList = personList
returnjson.orgList = orgList

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb�Ż����ӳ�
ssdb:set_keepalive(0,v_pool_size)
--redis�Ż����ӳ�
cache:set_keepalive(0,v_pool_size)
--mysql�Ż����ӳ�
mysql_db:set_keepalive(0,v_pool_size)