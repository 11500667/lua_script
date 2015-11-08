--[[
根据大学区ID获取学校列表
@Author  chenxg
@Date    2015-01-19
--]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
local dxq_id = args["dxq_id"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber


--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取学校ID列表
local b, err = ssdb:hgetall("qyjh_dxq_orgs_"..dxq_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

local orgIDs = ""
for i=2,#b,2 do
	if b[i] ~="," then
		orgIDs = b[i] .. orgIDs
	end
end
orgIDs = string.gsub(orgIDs, ",,", ",")
local res = Split(orgIDs,",")

if #res <= 2 then
	local returnjson = {}
	local list = {}
	returnjson.list = list
	returnjson.success = "true"
	returnjson.totalRow = 0
	returnjson.totalPage = 0
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	say(cjson.encode(returnjson))
	return
end



local totalRow = #res-2--t_totalRow
if totalRow <0 then 
	totalRow = 0
end
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
	pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize+2
local limit = pageSize*pageNumber+2
if limit > totalRow+2 then
	limit = totalRow+1
end
  
--分页学校IDS
local orgids ="-1"
for i=offset,limit,1 do
	orgids = orgids..","..res[i]
end
--根据学校IDS获取学校列表开始
local orglist
local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. orgids)

if res_org.status == 200 then
	orglist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	--return
end
--根据学校IDS获取学校列表结束

local returnjson = {}
returnjson.list = orglist.list
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
