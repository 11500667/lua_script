local cjson = require "cjson"

local str = {"zy","st","sj","bk","wk"}

--ngx.say(str[1])

--ngx.say(#str)

table.insert(str, 3, "aaaaaaaaaaaaaaaa")

--ngx.say(str)

local json = "{\"layout\":\"2\",\"portlets\":[[{\"id\":\"1\",\"name\":\"a\"},{\"id\":\"2\",\"name\":\"b\"}],[{\"id\":\"3\",\"name\":\"c\"}]]}"

local abc = cjson.decode(json)

ngx.say("**********************")
table.insert(abc.portlets[1],2,cjson.decode("{\"id\":\"5\",\"name\":\"h\"}"))
ngx.say(#abc.portlets[1])
ngx.say("**********************")
cjson.encode_empty_table_as_object(false)
ngx.say(cjson.encode(abc))
ngx.say("**********************")
ngx.say(abc.portlets[1][2]["name"])
ngx.say("**********************")
ngx.say(abc.portlets[1][3]["name"])


--[[
local aaa = 1/3
ngx.say("=================")
ngx.say(roundOff(0.3333,2))
ngx.say("=================")
ngx.say(string.format("%.2f",0.3)*100)
]]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local nba = ssdb_db:zrank("resource_sort_4","1")

ngx.say(nba)
