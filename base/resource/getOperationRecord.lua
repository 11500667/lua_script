#获取操作记录 by huyue 2015-06-15
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

function split(s, delim)
		if type(delim) ~= "string" or string.len(delim) <= 0 then
			return
		end

		local start = 1
		local t = {}
		while true do
		local pos = string.find (s, delim, start, true) -- plain find
			if not pos then
			  break
			end

			table.insert (t, string.sub (s, start, pos - 1))
			start = pos + string.len (delim)
		end
		table.insert (t, string.sub (s, start))

		return t
	end
	

local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]


local offset = pageSize*pageNumber-pageSize
local limit = pageSize


local create_person = args["create_person"]
if create_person == nil or create_person == '' then
  ngx.say("{\"success\":false,\"info\":\"create_person不能为空\"}")
  return
end

local res_count = db:query("select count(1) as count from t_resource_action where CreatePerson = "..create_person);
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local res = db:query(" SELECT ActionId,SourceStructureId,TargetStructureId,CreateTime,SourceResCount,UserOrDsideal,MediaType,ActionStatus,PersonName FROM t_resource_action WHERE CreatePerson="..create_person.." ORDER BY ActionTs DESC  LIMIT "..offset..","..limit..";")

ngx.log(ngx.ERR, "SELECT ActionId,SourceStructureId,TargetStructureId,CreateTime,SourceResCount,UserOrDsideal,MediaType,ActionStatus,PersonName FROM t_resource_action WHERE CreatePerson="..create_person.." ORDER BY ActionTs DESC  LIMIT "..offset..","..limit..";")

local resource_action_tab = {}
for i=1,#res do
	local resource_action_res = {}
	if res[i]["ActionId"] == 1 then
		resource_action_res["action_id"]="复制"
	elseif res[i]["ActionId"] == 2 then
		resource_action_res["action_id"]="移动"
	else
		resource_action_res["action_id"]="移动"
	end
	
	--获取sourcepath
	
	local sourcePath=""
	local sourceStructureId =  split(tostring(res[i]["SourceStructureId"]),",")
	for j=1,#sourceStructureId do
		local source_path = ""
		local structures = cache:zrange("structure_code_"..sourceStructureId[j],0,-1)
        for m=1,#structures do
            local structure_info = cache:hmget("t_resource_structure_"..structures[m],"structure_name")
            source_path = source_path..structure_info[1].."->"
		
        end
		if sourcePath == nil or sourcePath =='' then 
			sourcePath = string.sub(source_path,0,#source_path-2)
			
		else 
			sourcePath =sourcePath..",".. string.sub(source_path,0,#source_path-2)
		end
	end

	resource_action_res["source_structure_id"] = sourcePath
	
	--获取targetSource
	local targetStructureId = res[i]["TargetStructureId"]
	local target_path = ""
	local target_structures = cache:zrange("structure_code_"..targetStructureId,0,-1)
        for n=1,#target_structures do
            local structure_info = cache:hmget("t_resource_structure_"..target_structures[n],"structure_name")
            target_path = target_path..structure_info[1].."->"
			
        end
    target_path = string.sub(target_path,0,#target_path-2)
	
	resource_action_res["target_structure_id"] = target_path
		
		
	resource_action_res["create_time"] = res[i]["CreateTime"]
	resource_action_res["source_res_count"] = res[i]["SourceResCount"]
	resource_action_res["user_or_dsideal"] = res[i]["UserOrDsideal"]
	
	--状态	
	if res[i]["ActionStatus"] ==1 then
		resource_action_res["action_status"] ="需要处理"
	elseif res[i]["ActionStatus"] ==2 then
		resource_action_res["action_status"] ="正在处理"
	elseif res[i]["ActionStatus"] ==3 then
		resource_action_res["action_status"] ="已经完成"
	else
		resource_action_res["action_status"] = res[i]["ActionStatus"]
	end
	resource_action_res["person_name"] = res[i]["PersonName"]
	
	--媒体类型
	local mediaType = split(tostring(res[i]["MediaType"]),",")

	local media_type=""
	for o=1,#mediaType do
		local media_res = db:query(" select media_type  from t_resource_mediatype where b_use=1 and id="..mediaType[o])
		if media_type == nil or media_type == '' then
			media_type= media_res[1]["media_type"]
		else
			media_type = media_type..","..media_res[1]["media_type"]
		end
	end
	resource_action_res["media_type"] =media_type
	
	resource_action_tab[i] = resource_action_res
end

local result = {} 
result["list"] = resource_action_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

