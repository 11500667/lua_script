--[[
查看类别列表
@Author chuzheng
@date 2015-2-13
--]]
local say = ngx.say

--引用
local ssdblib = require "resty.ssdb"

local cjson = require "cjson"


--建立ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--查询ssdb中类别信息
local applicationrangelist,err = ssdb:hscan("yxx_game_applicationrange",'','',1000)

if  not  applicationrangelist then

    say("{\"success\":false,\"info\":\"查询适用范围信息失败！\"}")
    return
 end
local tab={}
if applicationrangelist[1]~="ok" then
	local id=1
    for j=1,#applicationrangelist,2 do         	
		local tabg={}
        tabg["applicationrangeid"]=applicationrangelist[j]
        tabg["applicationrangename"]=applicationrangelist[j+1]
        tab[id]=tabg
		id=id+1
      end
		
end


cjson.encode_empty_table_as_object(false)
local resultjson=cjson.encode(tab)
say("{\"success\":true,\"table_List\":"..resultjson.."}")

ssdb:set_keepalive(0,v_pool_size)
