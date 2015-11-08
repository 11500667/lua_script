--[[
管理员个人统计分析[mysql版]
@Author  chenxg
@Date    2015-06-05
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--判断request类型, 获得请求参数
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
--当前用户
local person_id = args["person_id"]
local subject_id = args["subject_id"]
local keyword = args["keyword"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
local dxq_id = args["dxq_id"]
local xzt_id = args["xzt_id"]
local org_id = args["org_id"]


--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not subject_id or string.len(subject_id) == 0
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	or not dxq_id or string.len(dxq_id) == 0
	or not xzt_id or string.len(xzt_id) == 0
	or not org_id or string.len(org_id) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or subject_id or keyword or dxq_id  or pageSize or pageNumber or xzt_id or org_id 参数错误！\"}")
    return
end

if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)
	else
		keyword = ""
	end
end

--根据分隔符分割字符串
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



--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
local personList = {}
local jsCount = 0

--获取当前用户所管理的大学区
local dxq_sql = "select dxq_id,js_tj from t_qyjh_dxq where b_delete=0 and b_use=1 and person_id = "..person_id
local dxq_sql2 = "select dxq_id from t_qyjh_dxq where b_delete=0 and b_use=1 and person_id = "..person_id
local dxq_result, err, errno, sqlstate = db:query(dxq_sql);
if not dxq_result then
	ngx.say("{\"success\":false,\"info\":\"查询大学区数据失败！\"}");
	return;
end
--local dxqs = ssdb:hget("qyjh_manager_dxqs",person_id)
if #dxq_result>=1 then
	returnjson.dxqCount = #dxq_result
	for i=1,#dxq_result,1 do
		local js_tj = dxq_result[1]["js_tj"]
		jsCount = tonumber(jsCount)+tonumber(js_tj)	
	end
	
	--获取教师数量
	local getPersonCountSql = "select count(DISTINCT person_id) as teaCount from t_base_person p left join t_qyjh_xzt_tea qxt on p.person_id = qxt.tea_id and qxt.b_use = 1  LEFT JOIN t_qyjh_dxq_org qdo on qdo.org_id = p.bureau_id left join t_base_organization o on o.org_id = p.bureau_id where p.identity_id=5 and qdo.dxq_id in("..dxq_sql2..") and person_name like '%"..keyword.."%' group by person_id";
	local personcount_res = db:query(getPersonCountSql)
	
	--获取协作体数量
	local getPersonSql = "select person_id,person_name,org_name,dxq_id from t_qyjh_xzt_tea qxt left join t_base_person p on p.person_id = qxt.tea_id left join t_base_organization o on o.org_id = qxt.org_id where qxt.b_use = 1 and qxt.dxq_id in("..dxq_sql2..") and person_name like '%"..keyword.."%' group by tea_id limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
	local getPersonSql2 = "select p.person_id,person_name,org_name,ifnull(qxt.dxq_id,0) as dxq_id from t_base_person p left join t_qyjh_xzt_tea qxt on p.person_id = qxt.tea_id and qxt.b_use = 1  LEFT JOIN t_qyjh_dxq_org qdo on qdo.org_id = p.bureau_id left join t_base_organization o on o.org_id = p.bureau_id where p.identity_id=5 and qdo.dxq_id in("..dxq_sql2..") and person_name like '%"..keyword.."%' group by person_id limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
	--say(getPersonSql)
	local person_res = db:query(getPersonSql2)
	
	local persons = {}
	for i=1,#person_res,1 do
		local person = {} 
		local tea_id = person_res[i]["person_id"]
		local person_name = person_res[i]["person_name"]
		local org_name = person_res[i]["org_name"]
		local pdxq_id = person_res[i]["dxq_id"]
		
		person.person_id = tea_id
		person.person_name = person_name
		person.org_name = org_name
		
		--获取参与协作体个数
		local xzt_sql = "select distinct xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..tea_id
		local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
		if not xzt_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		
		--local xztids = ssdb:hget("qyjh_tea_xzts",tea_id)

		person.xzt_count = #xzt_result
		if pdxq_id ~= "0" then
			--获取资源数
			local res_sql = "select count(distinct obj_id_int) as resCount from t_base_publish where b_delete=0 and pub_target="..pdxq_id.." and person_id = "..tea_id
			local res_result, err, errno, sqlstate = db:query(res_sql);
			if not res_result then
				ngx.say("{\"success\":false,\"info\":\"查询资源数据失败！\"}");
				return;
			end
			person.zy_count = res_result[1]["resCount"]
			
			--协作活动
			local hd_sql = "select count(1) as hdCount from t_qyjh_hd where b_delete = 0 and xzt_id in("..xzt_sql..")"
			local hd_result, err, errno, sqlstate = db:query(hd_sql);
			if not hd_result then
				ngx.say("{\"success\":false,\"info\":\"查询活动数据失败！\"}");
				return;
			end
			person.hd_count = hd_result[1]["hdCount"]
		else
			person.zy_count = 0
			person.hd_count = 0
		end
		
		personList[#personList+1] = person
		--personList.personList = persons
	end
	
	local totalRow = #personcount_res--jsCount
	returnjson.totalRow = totalRow
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	returnjson.totalPage = totalPage
end

returnjson.personList = personList
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)