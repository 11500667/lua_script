#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

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
if cookie_token == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的token信息未获取到！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local member_str = ""

--local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
local group_list = cache:sunion("group_"..cookie_person_id.."_"..cookie_identity_id.."_real","group_"..cookie_person_id.."_"..cookie_identity_id.."_check")
for i=1,#group_list do
    local str = "{\"org_id\":\"##\",\"org_name\":\"##\",\"b_request\":\"##\",\"check_num\":\"##\",\"description\":\"##\",\"source_id\":\"##\",\"member_id\":\"##\",\"member_type\":\"##\",\"state_id\":\"##\",\"person_id\":\"##\",\"identity_id\":\"##\"}"
    local group_info = cache:hmget("groupinfo_"..group_list[i],"org_id","org_name","b_request","check_num","description","source_id","b_use")
    --ngx.say(group_info[7].."_"..group_info[6].."_"..group_list[i])
    if group_info[7]~=ngx.null and group_info[6]~=ngx.null then
    if group_info[7]=="1" and group_info[6]=="1" then
        for j=1,6 do
            if j == 5 then
				group_info[j] = string.gsub(group_info[j],"\n","")
				group_info[j] = string.gsub(group_info[j],"\t","")
				group_info[j] = string.gsub(group_info[j],"\"","")
			end
			str = string.gsub(str,"##",group_info[j],1)
        end
		
		
			ngx.log(ngx.ERR,"str-------1-------------"..str);
		
        local member_info = cache:hmget("member_"..group_list[i].."_"..cookie_person_id.."_"..cookie_identity_id,"member_id","member_type","state_id","person_id","identity_id")
        if tostring(member_info[1])~="userdata: NULL" then
            for j=1,#member_info do
                str = string.gsub(str,"##",member_info[j],1)
            end
            member_str = member_str..str..","
        end
		
			ngx.log(ngx.ERR,"member_str-------1-------------"..member_str);
    end
    end
end
member_str = string.sub(member_str,0,#member_str-1)

ngx.log(ngx.ERR,"member_str--------------------"..member_str);


ngx.say("{\"success\":true,\"table_List\":["..member_str.."]}")
