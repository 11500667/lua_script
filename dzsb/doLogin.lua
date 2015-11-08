local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

ngx.log(ngx.ERR,"_____________aaaaa_____________")

--判断参数是否正确
if tostring(args["user"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"user参数错误！\"}")    
    return
end
if tostring(args["pwd"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"pwd参数错误！\"}")
    return
end
--[[if tostring(args["mac"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"mac参数错误！\"}")
    return
end
if tostring(args["type"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
]]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
	
--获取用户名参数
local user = tostring(args["user"])

--获取密码参数并转成MD5
local pwd = ngx.md5(tostring(args["pwd"]))

--local mac = tostring(args["mac"])
--local dtype = tostring(args["type"])

--获取登录来源信息和mac信息
--1:teach 2:office
local usertype = tostring(args["sys_type"])
local usermac = tostring(args["user_mac"])



--获取redis中该用户的启用状态
local redis_buse,err = cache:hget("login_"..user,"b_use")
if not redis_buse then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

if tostring(redis_buse)=="userdata: NULL" then
    ngx.say("{\"success\":false,\"info\":\"用户不存在！\"}")
    return
end

--判断该用户是否启用
if redis_buse~="1" then
    ngx.say("{\"success\":false,\"info\":\"该用户已停用！\"}")
    return
end

--获取redis中该用户的身份
local redis_identity,err = cache:hget("login_"..user,"identity_id")
if not redis_identity then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取redis中获取该用户的密码
local redis_pwd,err = cache:hget("login_"..user,"pwd")
if not redis_pwd then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

--判断参数传过来的密码和redis里存储的密码是否匹配
if v_is_cas ~= "1" then
if redis_pwd~=pwd then
    cache:set_keepalive(0,v_pool_size)
    ngx.say("{\"success\":false,\"info\":\"用户名或密码错误！\"}")
    return
end
else
    local login_cas_info = ngx.location.capture("/dsideal_yy/caslogin/dsidealSsoLogin?username="..args["user"].."&password="..args["pwd"].."&random="..math.random(1000))
    local login_cas_str = login_cas_info.body
    local login_cas_json = cjson.decode(login_cas_str)
    if tostring(login_cas_json.success) ~= "true" then
	ngx.print(tostring(login_cas_str))
	return
    end
end


    local res,err = cache:hmget("login_"..user,"person_id","person_name","identity_id","token")
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    --local shi_id = cache:hget("person_"..res[1].."_"..res[3],"shi")
    local xiao_id = cache:hget("person_"..res[1].."_"..res[3],"xiao")
	local avatar_url = cache:hget("person_"..res[1].."_"..res[3],"avatar_url")
    --redis放回连接池
    cache:set_keepalive(0,v_pool_size)
    ngx.header["Set-Cookie"] = {"person_id="..res[1]..";path=/","person_name="..urlencode(res[2])..";path=/","identity_id="..res[3]..";path=/","token="..res[4]..";path=/","user="..user..";path=/","type="..usertype..";path=/","mac="..usermac..";path=/","xiao_id="..xiao_id..";path=/"}
	
	
	--连接数据库
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
	local class_json = {}
	local subject_json = {}
	local result = {}
	if res[3] == "5" then
		--老师
		local tea_subject_list = db:query("SELECT DISTINCT t1.subject_id,t2.subject_name,t3.stage_name FROM t_base_class_subject t1 INNER JOIN t_dm_subject t2 ON t1.SUBJECT_ID = t2.subject_id INNER JOIN t_dm_stage t3 ON t2.STAGE_ID = t3.STAGE_ID WHERE t1.TEACHER_ID = "..res[1]);	
		subject_json = tea_subject_list
		
		if #subject_json > 0 then
			for i=1,#subject_json do
				local tea_class_list = db:query("SELECT t2.class_id,t2.class_name FROM t_base_class_subject t1 INNER JOIN t_base_class t2 ON t1.CLASS_ID = t2.CLASS_ID INNER JOIN t_base_term t3 on t3.XQ_ID = t1.XQ_ID and t3.SFDQXQ=1 WHERE t1.TEACHER_ID = "..res[1].." AND t1.subject_id="..subject_json[i].subject_id);
				subject_json[i]["class_list"] = tea_class_list
			end
		end	
		local teacher_subject=db:query("select distinct sub.subject_id,sub.subject_name,sta.stage_id,sta.stage_name from  (select subject_id from t_base_person where person_id ="..res[1].." union all select subject_id from t_base_person_subjects where person_id="..res[1]..") a join t_dm_subject sub on a.subject_id = sub.subject_id  join t_dm_stage sta on sub.stage_id=sta.stage_id;");
		result["teacher_subject"]=teacher_subject;
	end
	if res[3] == "6" then
		--学生
		local stu_class_list = db:query("SELECT t2.class_id,t2.class_name,t2.stage_id,t3.stage_name FROM t_base_student t1 INNER JOIN t_base_class t2 ON t1.CLASS_ID = t2.CLASS_ID INNER JOIN t_dm_stage t3 ON t2.STAGE_ID = t3.STAGE_ID WHERE t1.student_id = "..res[1]);	
		class_json = stu_class_list
		local stu_subject_list = db:query("SELECT DISTINCT t3.subject_id,t3.subject_name FROM t_base_student t1 INNER JOIN t_base_class_subject t2 ON t1.CLASS_ID = t2.CLASS_ID INNER JOIN t_dm_subject t3 ON t2.subject_id = t3.subject_id WHERE t1.student_id = "..res[1]);	
		subject_json = stu_subject_list	
	end	
	
	
	
	result["success"] = true
	if res[3] == "6" then
		result["class_list"] = class_json
	end	
	result["subject_list"] = subject_json
	
	result["person_id"] = res[1]
	result["person_name"] = urlencode(res[2])
	result["identify_id"] = res[3]
	result["token"] = res[4]
	result["avatar_url"] = avatar_url
	local ts_str = os.date("%Y-%m-%d");
	result["sys_date"] = ts_str  
	local xq_id = db:query("SELECT XQ_ID FROM t_base_term WHERE SFDQXQ = 1");	
	result["xq_id"] = xq_id[1]["XQ_ID"]
	
	
	--陈续刚20150506添加  备注：返回结果增加了allsum
	
	--获取登录来源信息和mac信息
	--1:teach 2:office
	local usertype = tostring(args["sys_type"])
	local usermac = tostring(args["user_mac"])
	if usermac~="nil" and usertype ~="nil" then
	--限制的登录机器数
	local hostsum = 3;
	if usermac =="kong" then
		ngx.say("{\"success\":\"false\",\"info\":\"获取机器mac地址出错，无法登录！\"}");
		return;
	end
		local quote = ngx.quote_sql_str

		--查询数据库，对比该mac地址是否已经在列表中
		--查询数据库，获取已经登录过的机器列表
		local countSql = "select count(1) as allsum from t_base_person_loginrecord where person_id="..res[1].." and system_type="..usertype..";select count(1) as hdsum from t_base_person_loginrecord where person_id="..res[1].." and system_type="..usertype.." and host_mac='"..usermac.."';";
		local results, err, errno, sqlstate = db:query(countSql);
		if not results then
			ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
			ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
			return;
		end
		local allsum = results[1]["allsum"]
		local res1 = db:read_result()		
		local hdsum = res1[1]["hdsum"]

		if tonumber(allsum) <=tonumber(hostsum)  then
			local n = ngx.now();
			local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
			ts2 = ts2..string.rep("0",19-string.len(ts2));
			if tonumber(allsum) == tonumber(hostsum) and tonumber(hdsum) == 0 then
				ngx.say("{\"success\":\"false\",\"info\":\"登录的机器数已经超过"..hostsum.."台！\"}");
				return;
			else
				if tonumber(hdsum) == 0  then
					local insertsql = "insert into  t_base_person_loginrecord(person_id,system_type,host_mac,lastts)values("..res[1]..","..quote(usertype)..","..quote(usermac)..","..quote(ts2)..");"
					
					local results, err, errno, sqlstate = db:query(insertsql);
					if not results then
						ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
						ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
						return;
					end
					result["allsum"] = tonumber(allsum)+1
				else
					local updatesql = "update t_base_person_loginrecord set lastts="..quote(ts2).." where person_id = "..quote(res[1]).." and system_type = "..quote(usertype).." and host_mac = "..quote(usermac)..""
					local results, err, errno, sqlstate = db:query(updatesql);
					if not results then
						ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
						ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
						return;
					end
					result["allsum"] = allsum
				end
			end
		else
			ngx.say("{\"success\":\"false\",\"info\":\"登录的机器数已经超过"..hostsum.."台！\"}");
			return;
		end

	end
	--陈续刚20150506添加
	
	
	local cjson = require "cjson"
	cjson.encode_empty_table_as_object(false);
	
	ngx.log(ngx.ERR,"##########")
	ngx.log(ngx.ERR,"#####"..cjson.encode(result).."#####")
	ngx.log(ngx.ERR,"##########")
	
	ngx.say(cjson.encode(result))
	
	-- 将mysql连接归还到连接池
	ok, err = db: set_keepalive(0, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
	end
--[[
else
    --redis放回连接池
    cache:set_keepalive(0,v_pool_size)
    ngx.say("{\"success\":false,\"info\":\"用户名或密码错误！\"}")    
end
]]
