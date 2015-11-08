local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--先判断参数是否正确
if tostring(args["user"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"user参数错误！\"}")    
    return
end
if tostring(args["pwd"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"pwd参数错误！\"}")
    return
end
--获取用户名参数
local user = tostring(args["user"])
--获取密码参数并转成MD5
local pwd = ngx.md5(tostring(args["pwd"]))



--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
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
if v_is_cas ~= "1" then
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
--判断该用户是否可以前台登录
if redis_identity~="5" then
    if redis_identity~="6" then
	if redis_identity~="7" then
	    if redis_identity~="11" then
	        ngx.say("{\"success\":false,\"info\":\"该用户的身份不允许登录！\"}")
    	        return
	    end
	end
    end
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
if redis_pwd==pwd then
	
    local str = "{\"success\":true,\"person_id\":\"##\",\"person_name\":\"##\",\"identity\":\"##\",\"token\":\"##\",\"avatar_url\":\"##\",\"class_id\":\"##\",\"bureau_id\":\"##\",\"bureau_name\":\"##\",\"mac_sum\":\"##\"}"
    local res,err = cache:hmget("login_"..user,"person_id","person_name","identity_id","token")
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    local shi_id = cache:hget("person_"..res[1].."_"..res[3],"shi")
    local xiao_id = cache:hget("person_"..res[1].."_"..res[3],"xiao")

    if shi_id ~=ngx.null and xiao_id~=ngx.null then
	ssdb_db:zincr("active_user_"..shi_id,res[1])
	ssdb_db:zincr("active_bureau_"..shi_id,xiao_id)
    end
    --放回到SSDB连接池
    ssdb_db:set_keepalive(0,v_pool_size)
    for i=1,#res do
	str = string.gsub(str,"##",res[i],1)
    end
    local avatar_url = cache:hmget("person_"..res[1].."_"..res[3],"avatar_url")[1]
    str = string.gsub(str,"##",avatar_url,1)
    --redis放回连接池
    -- cache:set_keepalive(0,v_pool_size)
	
	--连接mysql数据库
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

	local person_id = res[1]
	local identity_id = res[3]
	local class_id = "-1"
	local bureau_id="-1";
	if tostring(identity_id) == "6" then
			local res = mysql_db:query("SELECT class_id,bureau_id FROM t_base_student WHERE student_id = "..person_id)
			class_id = res[1]["class_id"]
			bureau_id=res[1]["bureau_id"]
	elseif tostring(identity_id)=="5" then
			local bureau_res=mysql_db:query("SELECT bureau_id FROM t_base_person WHERE person_id = "..person_id)
			bureau_id=bureau_res[1]["bureau_id"]
	end
	str = string.gsub(str,"##",class_id,1)
	
	str = string.gsub(str,"##",bureau_id,1)
	
	local bureau_name =  cache:hget("t_base_organization_"..bureau_id,"org_name");
	str = string.gsub(str,"##",bureau_name,1)
	

    ngx.location.capture("/dsideal_yy/new_djmh/setHuoYue?person_id="..res[1].."&random="..math.random(1000))
    ngx.header["Set-Cookie"] = {"person_id="..res[1]..";path=/","person_name="..urlencode(res[2])..";path=/","identity_id="..res[3]..";path=/","token="..res[4]..";path=/","avatar_url="..avatar_url..";path=/","class_id="..class_id..";path=/"}
ngx.say(str)
else
    --redis放回连接池
    --cache:set_keepalive(0,v_pool_size) 
    ngx.say("{\"success\":false,\"info\":\"用户名或密码错误！\"}")    
end

else
    local login_cas_info = ngx.location.capture("/dsideal_yy/caslogin/dsidealSsoLogin?username="..args["user"].."&password="..args["pwd"].."&random="..math.random(1000))
    local login_cas_str = login_cas_info.body
    local login_cas_json = cjson.decode(login_cas_str)
    if tostring(login_cas_json.success) == "true" then
       local str = "{\"success\":true,\"person_id\":\"##\",\"person_name\":\"##\",\"identity\":\"##\",\"token\":\"##\",\"avatar_url\":\"##\",\"class_id\":\"##\"}"
    local res,err = cache:hmget("login_"..user,"person_id","person_name","identity_id","token")
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    local shi_id = cache:hget("person_"..res[1].."_"..res[3],"shi")
    local xiao_id = cache:hget("person_"..res[1].."_"..res[3],"xiao")

    if shi_id ~=ngx.null and xiao_id~=ngx.null then
        ssdb_db:zincr("active_user_"..shi_id,res[1])
        ssdb_db:zincr("active_bureau_"..shi_id,xiao_id)
    end
    --放回到SSDB连接池
    ssdb_db:set_keepalive(0,v_pool_size)
    for i=1,#res do
        str = string.gsub(str,"##",res[i],1)
    end
    local avatar_url = cache:hmget("person_"..res[1].."_"..res[3],"avatar_url")[1]
    str = string.gsub(str,"##",avatar_url,1)
    --redis放回连接池
    cache:set_keepalive(0,v_pool_size)
	
	--连接mysql数据库
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

	local person_id = res[1]
	local identity_id = res[3]

	if tostring(identity_id) == "6" then
			local res = mysql_db:query("SELECT class_id,bureau_id FROM t_base_student WHERE student_id = "..person_id)
			class_id = res[1]["class_id"]
		
		
	end
	str = string.gsub(str,"##",class_id,1)

	
    ngx.location.capture("/dsideal_yy/new_djmh/setHuoYue?person_id="..res[1].."&random="..math.random(1000))
    ngx.header["Set-Cookie"] = {"person_id="..res[1]..";path=/","person_name="..urlencode(res[2])..";path=/","identity_id="..res[3]..";path=/","token="..res[4]..";path=/","avatar_url="..avatar_url..";path=/","class_id="..class_id..";path=/"}
    ngx.say(str)
    else
        ngx.print(tostring(login_cas_str))
    end
end
