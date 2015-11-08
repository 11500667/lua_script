#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
--local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员信息未获取到！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员身份信息未获取到！\"}")
    return
end
--判断是否有token的cookie信息
--[[
if cookie_token == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的token信息未获取到！\"}")
    return
end
]]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


--sType参数 查询按什么类型 1：群号   2：群名
local sType = tostring(ngx.var.arg_sType)
--判断是否有sType参数
if sType == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有sType参数！\"}")
    return
end

--keyWord参数
local keyWord = tostring(ngx.var.arg_keyWord)
--判断是否有keyWord参数
if keyWord == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有keyWord参数！\"}")
    return
end

keyWord = ngx.decode_base64(keyWord)

--pageSize参数
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有pageSize参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有pageSize参数！\"}")
    return
end

--pageNumber参数
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有pageNumber参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有pageNumber参数！\"}")
    return
end

local member_str = ""
local totalRow = "0"
local totalPage = "0"

--1：群号   2：群名
if sType=="1" then
    --state_id 0：待审核  1：已加入 2：未加入
    local str = "{\"org_id\":\"##\",\"org_name\":\"##\",\"b_request\":\"##\",\"check_num\":\"##\",\"description\":\"##\",\"state_id\":\"##\"}"
    local group_info = cache:hmget("groupinfo_"..keyWord,"org_id","org_name","b_request","check_num","description")
    if tostring(group_info[1])=="userdata: NULL" then
	totalRow = "0"
	totalPage = "0"
    else
	totalRow = "1"
	totalPage = "1"
	str = string.gsub(str,"##",group_info[1],1)
	str = string.gsub(str,"##",group_info[2],1)
	str = string.gsub(str,"##",group_info[3],1)
	str = string.gsub(str,"##",group_info[4],1)
	str = string.gsub(str,"##",group_info[5],1)
	local member_info = cache:hget("member_"..group_info[1].."_"..cookie_person_id.."_"..cookie_identity_id,"state_id")
        if tostring(member_info)=="userdata: NULL" then
	    str = string.gsub(str,"##","2",1)
	else
	    str = string.gsub(str,"##",member_info,1)	    
	end
	member_str = str
    end
else
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

    local offset = pageSize*pageNumber-pageSize
    local limit = pageSize

    --ngx.say("SELECT SQL_NO_CACHE id FROM t_base_organization_sphinxse WHERE query=\'"..keyWord..";filter=B_GROUP,1;maxmatches=100000;offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

    local l_res = db:query("SELECT SQL_NO_CACHE id FROM t_base_organization_sphinxse WHERE query=\'"..keyWord..";filter=B_GROUP,1;maxmatches=100000;offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

    --去第二个结果集中的Status中截取总个数
    local res1 = db:read_result()
    local _,s_str = string.find(res1[1]["Status"],"found: ")
    local e_str = string.find(res1[1]["Status"],", time:")
    totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
    totalPage = math.floor((totalRow+pageSize-1)/pageSize)   
 
    if #l_res ~=0 then
    	for i=1,#l_res do
	    local str = "{\"org_id\":\"##\",\"org_name\":\"##\",\"b_request\":\"##\",\"check_num\":\"##\",\"description\":\"##\",\"state_id\":\"##\"}"
 	    local group_info = cache:hmget("groupinfo_"..l_res[i]["id"],"org_id","org_name","b_request","check_num","description")
	    if tostring(group_info[1])~="userdata: NULL" then
		str = string.gsub(str,"##",group_info[1],1)
       		str = string.gsub(str,"##",group_info[2],1)
        	str = string.gsub(str,"##",group_info[3],1)
        	str = string.gsub(str,"##",group_info[4],1)
		str = string.gsub(str,"##",group_info[5],1)
		local member_info = cache:hget("member_"..group_info[1].."_"..cookie_person_id.."_"..cookie_identity_id,"state_id")
        	if tostring(member_info)=="userdata: NULL" then
            	    str = string.gsub(str,"##","2",1)
        	else
            	    str = string.gsub(str,"##",member_info,1)
        	end
		member_str = member_str..str..","
	    end
        end
	member_str = string.sub(member_str,0,#member_str-1)
    end
end

ngx.say("{\"success\":true,\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"table_List\":["..member_str.."]}")


