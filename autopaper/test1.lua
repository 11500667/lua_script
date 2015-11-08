
--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson"

local group_id = redis_db:smembers("group_28887_5")

local aaaa ={}

aaaa["group_ids"] = group_id

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(aaaa))



local jsonStr = "{\"stage_id\": 5,\"subject_id\": 6,\"scheme_id_int\": 205,\"question_type\": [{\"type_id\": 2,\"count\": 3},{\"type_id\": 6,\"count\": 5},{\"type_id\": 14,\"count\": 6},{\"type_id\": 16,\"count\": 8}],\"difficulty\": 0.5,\"structure_ids\": [44320,44365,44338,44332]}"

local myJson = cjson.decode(jsonStr)

local stage_id = myJson.stage_id
local subject_id = myJson.subject_id
local question_type = myJson.question_type
for i=1,#question_type do
	ngx.say(question_type[i].type_id)
end

local structure_id = {}
local structure_ids = myJson.structure_ids
for i=1,#structure_ids do	
	local ids = Split(redis_db:get("node_"..structure_ids[i]),",")
	for j=1,#ids do
		table.insert(structure_id, tonumber(ids[j]))
	end	
end


local generate_json = {}

generate_json["structure_ids"] = structure_id

--cjson.encode_empty_table_as_object(false);
--ngx.print(cjson.encode(generate_json))


local a1 = cjson.decode(ngx.decode_base64(redis_db:hget("question_150967","json_question")))
local a2 = cjson.decode(ngx.decode_base64(redis_db:hget("question_150968","json_question")))

--local b1 = cjson.decode(a1)
--local b2 = cjson.decode(a2)


local generate_1 = {}

generate_1[1] = a1
generate_1[2] = a2

local generate_2 = {}

generate_2["aaa"] = generate_1

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(generate_2))




