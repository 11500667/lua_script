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
local categorylist,err = ssdb:hscan("yxx_game_category",'','',1000)

if  not  categorylist then

    say("{\"success\":false,\"info\":\"查询类别信息失败！\"}")
    return
 end
local tab={}
if categorylist[1]~="ok" then
	local id=1
    for j=1,#categorylist,2 do         	
		local tabg={}
        tabg["categoryid"]=categorylist[j]
        tabg["categoryname"]=categorylist[j+1]
        tab[id]=tabg
		id=id+1
      end
		
end


cjson.encode_empty_table_as_object(false)
local resultjson=cjson.encode(tab)
say("{\"success\":true,\"table_List\":"..resultjson.."}")

ssdb:set_keepalive(0,v_pool_size)
