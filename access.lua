#ngx.header.content_type = "text/plain;charset=utf-8"


local path = ngx.var.uri
local ypt=string.find(path,"/dsideal_yy/ypt/")
if ypt then

	local cookie_person_id = tostring(ngx.var.cookie_person_id)
	local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
	local cookie_token = tostring(ngx.var.cookie_token)

	--判断是否有person_id的cookie信息
	if cookie_person_id == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有personid！\"}")
		ngx.exit(403)
		return
	end
	--判断是否有identity_id的cookie信息
	if cookie_identity_id == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有identity！\"}")
		ngx.exit(403)
		return
	end
	--判断是否有token的cookie信息
	if cookie_token == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有token！\"}")
		ngx.exit(403)
		return
	end

	--连接redis服务器
	local redis = require "resty.redis"
	local cache = redis.new()
	local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
	if not ok then
		ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
		ngx.exit(403)
		return
	end

	--获取redis中该用户的token
	local redis_token,err = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"token")
	-- ngx.log(ngx.ERR,"====".."person_"..cookie_person_id.."_"..cookie_identity_id)
	if not redis_token then
		ngx.say("{\"status\":\"0\",\"info\":\"redis中没有token！\"}")
		ngx.exit(403)
		return
	end
	--验证cookie中的token和redis中存的token是否相同
	if redis_token ~= cookie_token then
		ngx.log(ngx.ERR,"redis_token="..redis_token.."=======cookie_token"..cookie_token)
		ngx.say("{\"status\":\"0\",\"info\":\"redis中token与cookie不一致！\"}")
		ngx.exit(403)
		return
	end
end




local management=string.find(path,"/dsideal_yy/management/")
if management  then
	local cookie_background_person_id = tostring(ngx.var.cookie_background_person_id)
	local cookie_background_identity_id = tostring(ngx.var.cookie_background_identity_id)
	local cookie_background_token = tostring(ngx.var.cookie_background_token)

	--判断是否有background_person_id的cookie信息
	if cookie_background_person_id == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有personid！\"}")
		ngx.exit(403)
		return
	end
	--判断是否有background_identity_id的cookie信息
	if cookie_background_identity_id == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有identity！\"}")
		ngx.exit(403)
		return
	end
	--判断是否有background_token的cookie信息
	if cookie_background_token == "nil" then
		ngx.say("{\"status\":\"0\",\"info\":\"cookie中没有token！\"}")
		ngx.exit(403)
		return
	end

	--连接redis服务器
	local redis = require "resty.redis"
	local cache = redis.new()
	local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
	if not ok then
		ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
		ngx.exit(403)	    
		return
	end

	--获取redis中该用户的token
	local redis_token,err = cache:hget("person_"..cookie_background_person_id.."_"..cookie_background_identity_id,"token")
	if not redis_token then
		ngx.say("{\"status\":\"0\",\"info\":\"redis中没有token！\"}")
		ngx.exit(403)
		return
	end
	--验证cookie中的token和redis中存的token是否相同
	if redis_token ~= cookie_background_token then
		ngx.say("{\"status\":\"0\",\"info\":\"redis中token与cookie中不一致\"}")
		ngx.exit(403)
		return
	end
end


--新闻的拦截
local news=string.find(path,"/dsideal_yy/management/news/")
if news  then
	local request_method = ngx.var.request_method
	local args = nil
	if "GET" == request_method then
		args = ngx.req.get_uri_args()
	else
		ngx.req.read_body()
		args = ngx.req.get_post_args()
	end
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
	
	local regist_person = tostring(ngx.var.cookie_background_person_id)
	
	if args["regist_id"] == nil or args["regist_id"] == "" then 
		ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
		return
	end
	local regist_id = args["regist_id"]
	
	--column_id参数
	if args["column_id"] == nil or args["column_id"] == "" then 
		ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
		return
	end
	local column_id = args["column_id"]
	
	--判断regist_id和regist_person是否匹配
	local jq_sql = mysql_db:query("select count(1) as count from t_news_regist where regist_id = "..regist_id.." and regist_person = "..regist_person..";")
	if jq_sql[1]["count"] == "0" or #jq_sql == 0 then
		ngx.print("{\"success\":false,\"info\":\"注册号和注册人不匹配，不能创建新闻！\"}")
		ngx.exit(403)
		return		
	end
	
	--判断regist_id和regist_person和column_id是否匹配
	if column_id ~= "-1" then
		local colum_sql = mysql_db:query("select count(1) as count from t_news_column where column_id = "..column_id.." and regist_id = "..regist_id.." and create_person="..regist_person..";")
		if colum_sql[1]["count"] == "0" or #colum_sql == 0 then
			ngx.print("{\"success\":false,\"info\":\"注册号、注册人和栏目ID不匹配，不能创建新闻！\"}")	
			ngx.exit(403)
			return
		end
	end
	
end





--end
