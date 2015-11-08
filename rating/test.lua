local upload = require "resty.upload"
local uuid =  require "resty.uuid";

local chunk_size = 4096
local form = upload:new(chunk_size)
local file

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local bureau_id = redis_db:hget("person_20306_5","xiao")

ngx.log(ngx.ERR,"######"..tostring(bureau_id).."######")


--获取文件名
function get_filename(res) 
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)') 
    if filename then  
        return filename[2] 
    end 
end 

--获取文件扩展名
function getExtension(str)
    return str:match(".+%.(%w+)$")
end

--文件ID
local file_id = uuid.new()

while true do
	local typ, res, err = form:read()	
	if not typ then		 
		 ngx.say("{error:false, msg:'"..tostring(err).."',imgurl:''}")
		 return
	end
	if typ == "header" then
		if res[1] ~= "Content-Type" then			
			local filen_ame = get_filename(res[2])
			local extension = getExtension(filen_ame)
			local dir = string.sub(file_id,0,2)			
			--local file_name = "/usr/local/tomcat7/webapps/dsideal_yy/html/down/Material/"..dir.."/"..file_id.."."..extension			
			local file_name = "/usr/local/tomcat7/webapps/dsideal_yy/html/down/Material/"..file_id.."."..extension
			if file_name then
				file = io.open(file_name, "w+")
				if not file then
					ngx.say("{error:false, msg:'failed to open file',imgurl:''}")
					return
				end
			end
		end
	 elseif typ == "body" then
		if file then
			file:write(res)			
		end
	elseif typ == "part_end" then
		file:close()
		file = nil
	elseif typ == "eof" then
		break
	else
		-- do nothing
	end
end

ngx.say("{error:true, msg:'"..file_id.."',imgurl:''}")