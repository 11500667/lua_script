--[[
保存编辑后的大学区[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str

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
--参数 
local xzt_id = args["xzt_id"]
local subject_id = args["subject_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]
local is_init = args["is_init"]
--0:不保留  1：保留
local isOriginal = args["isOriginal"]


--从cookie获取当前用户的省市区ID
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0  
  or not subject_id or string.len(subject_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--存储详细信息

local xzt = {}
--获取详细信息
local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id from t_qyjh_xzt where b_use=1 and xzt_id = "..xzt_id.." "
local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
if not xzt_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
xzt.person_id = xzt_result[1]["person_id"]
local qyjh_id = xzt_result[1]["qyjh_id"]
local dxq_id = xzt_result[1]["dxq_id"]

if xzt.person_id ~= person_id then --协作体带头人发生了变化
	local old_sch_id = cache:hget("person_"..xzt.person_id.."_"..cookie_identity_id,"xiao")
	local new_sch_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
	--存储新的管理员
	if isOriginal == "0" then
		local params = "xzt_id="..xzt_id.."&org_id="..old_sch_id.."&operationtype=2&person_id="..xzt.person_id
		ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
	end
	local params = "xzt_id="..xzt_id.."&org_id="..new_sch_id.."&operationtype=1&person_id="..person_id
	ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
	
	local select_sql = "select person_id from t_qyjh_dxq_dtr where person_id="..person_id.." and b_use=1"
	local result1, err, errno, sqlstate = db:query(select_sql);
	if not result1 then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return
	end
	if #result1 == 0 then
		local insertSql = "insert into t_qyjh_dxq_dtr(qyjh_id,dxq_id,org_id,person_id,start_time) values("..quote(qyjh_id)..","..quote(dxq_id)..","..quote(new_sch_id)..","..quote(person_id)..","..quote(os.date("%Y-%m-%d %H:%M:%S"))..")"
		local result, err, errno, sqlstate = db:query(insertSql);
		if not result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
			return
		end
		local updateSql = "update t_qyjh_dxq set dtr_tj = dtr_tj+1  where dxq_id="..dxq_id
		db:query(updateSql);
	end
	
end

--更新mysql表中协作体信息
local person_name = cache:hget("person_"..person_id.."_"..cookie_identity_id,"person_name")
local new_sch_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
local ts = os.date("%Y-%m-%d %H:%M:%S")

local tea_sql = "select distinct tea_id from t_qyjh_xzt_tea where xzt_id="..xzt_id.." and b_use=1"
local res = db:query(tea_sql)

local updateSql = "update t_qyjh_xzt set subject_id ="..quote(subject_id)..",xzt_name = "..quote(name)..",description = "..quote(description)..",logo_url = "..quote(logo_url)..",person_name ="..quote(person_name)..",org_id ="..quote(new_sch_id)..",person_id ="..quote(person_id)..",ts="..quote(ts2).." ,is_init="..quote(is_init)..",js_tj="..#res.."  where xzt_id="..quote(xzt_id);
			
local ok, err = db:query(updateSql)
--需要将协作体初始化为版块
if is_init then	
	--先查询之前有没有初始化过
	local bbs_sql = "select bbs_pk,b_delete from t_qyjh_bbs where bbs_type=2 and xzt_id="..xzt_id..""
	local result, err, errno, sqlstate = db:query(bbs_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	
	local bbs_sql2 = "select bbs_pk,b_delete from t_qyjh_bbs where bbs_type=1 and dxq_id="..dxq_id..""
	local result2, err, errno, sqlstate = db:query(bbs_sql2);
	if not result2 then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	
	--调用论坛接口创建bbs
	if is_init == "1" then
		local bbsService = require("social.service.BbsService")
		local forumService = require("social.service.CommonForumService")
		local tbbs = bbsService:getBbsByRegionId(qyjh_id);
		local bbs_id=tbbs.id;
		--local icon_url = string.gsub(logo_url, "../../../", "../../")
		local icon_url = string.match(logo_url,".+/(.+)")
		local bz = {person_id=tostring(person_id),person_name=person_name,identity_id="5"}
		local forum_admin_list = {}
		forum_admin_list[1]=bz
		if #result>=1 then
			local pam = {bbs_id=tostring(bbs_id),partition_id=tostring(result2[1]["bbs_pk"]),name=name,icon_url=icon_url,description=description,sequence=tostring(xzt_id),type_id=tostring(xzt_id),type="3",forum_id=tostring(result[1]["bbs_pk"]),forum_admin_list=forum_admin_list}
			forumService:updateForum(pam)
				
			local update_sql = "update t_qyjh_bbs set b_delete=0,person_id="..person_id.." where bbs_pk="..result[1]["bbs_pk"]..""
			db:query(update_sql)
			if tonumber(result[1]["b_delete"]) == 1 then
				--ngx.log(ngx.ERR,"cxg_log ========><=============")
				forumService:recoveryForum(result[1]["bbs_pk"])
			end
		else
			local pam = {bbs_id=tostring(bbs_id),partition_id=tostring(result2[1]["bbs_pk"]),name=name,icon_url=icon_url,description=description,sequence=tostring(xzt_id),type_id=tostring(xzt_id),type="3",forum_admin_list=forum_admin_list}
			local bbs_pk = forumService:saveForum(pam)
			--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id.."<=============")
			local bbs_sql = "insert into t_qyjh_bbs(bbs_id,qyjh_id,dxq_id,xzt_id,bbs_type,create_time,bbs_pk,person_id)values("..quote(bbs_id)..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(xzt_id)..",2,"..quote(ts)..","..bbs_pk..","..person_id..")";
			db:query(bbs_sql);
		end
	else
		if #result>=1 then
			local update_sql = "update t_qyjh_bbs set b_delete=1 where bbs_pk="..result[1]["bbs_pk"]..""
			db:query(update_sql)

			if tonumber(result[1]["b_delete"]) == 0 then
				forumService:deleteForum(result[1]["bbs_pk"])
			end
		end
	end
	--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id.."<=============")
end

say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体信息修改成功！\"}")

-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
