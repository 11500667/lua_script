local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"
local myTs = require "resty.TS"

local person_id = tostring(ngx.var.cookie_person_id)

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--新生成一个标示ID
local logo_id = tostring(myTs.getTs())..tostring(math.random(1,99999))

--POST过来的json串

if args["jsonStr"] == nil or args["jsonStr"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"jsonStr参数错误！\"}")
    return
end
local jsonStr = args["jsonStr"]

--测试JSON
--local jsonStr = "{\"stage_id\": 5,\"subject_id\": 6,\"scheme_id_int\": 205,\"question_type\": [{\"type_id\": 2,\"count\": 3},{\"type_id\": 6,\"count\": 5},{\"type_id\": 14,\"count\": 6},{\"type_id\": 16,\"count\": 8}],\"difficulty\": 0.5,\"structure_ids\": [44320,44365,44338,44332]}"


local myJson = cjson.decode(jsonStr)
--学段ID
local stage_id = myJson.stage_id
--学科ID
local subject_id = myJson.subject_id
--版本ID
local scheme_id_int = myJson.scheme_id_int
--题型
local question_type = myJson.question_type
local tx = {}
for i=1,#question_type do
	local qt_tab = {}
	local qt_id = question_type[i].type_id
	local qt_info = redis_db:hmget("qt_list_"..subject_id.."_"..qt_id,"qt_id","qt_name","qt_type","sort_id")
	qt_tab["qt_id"] = qt_info[1]
	qt_tab["visible"] = "1"
	qt_tab["pfl_visible"] = "1"
	qt_tab["tx_name"] = qt_info[2]
	qt_tab["sort_id"] = qt_info[4]
	qt_tab["oneortwo"] = qt_info[3]
	qt_tab["tx_zhu"] = "注释"
	tx[i] = qt_tab
end



--难度
local difficulty = myJson.difficulty

--获取所以子节点
local nodes = {}
local structure_ids = myJson.structure_ids
for i=1,#structure_ids do		
	local ids = Split(redis_db:get("node_"..structure_ids[i]),",")
	for j=1,#ids do
		table.insert(nodes, tonumber(ids[j]))
	end	
end

local generate_json = {}
generate_json["id"] = logo_id
generate_json["stage_id"] = stage_id
generate_json["subject_id"] = subject_id
generate_json["scheme_id_int"] = scheme_id_int
generate_json["question_type"] = question_type
generate_json["difficulty"] = difficulty
generate_json["structure_ids"] = nodes
generate_json["person_id"] = person_id

local group_ids = redis_db:smembers("group_"..person_id.."_5")
generate_json["group_ids"] = group_ids

cjson.encode_empty_table_as_object(false);
redis_db:lpush("generate_question_ids",cjson.encode(generate_json))

local now = ngx.time();

local result = {} 

while true do

if ngx.time()-now>30 then        
		result["success"] = false
		result["info"] = "生成试卷失败！"
		cjson.encode_empty_table_as_object(false);
		ngx.print(cjson.encode(result))
        ngx.exit(ngx.HTTP_OK)
end

local qtids = redis_db:get("AutoPaper_"..logo_id)

if qtids ~= ngx.null then
	result["paper_name"] = "未命名"
	result["create_or_update"] = "1"
	result["h1"] = "1"
	result["h1_l"] = "主标题"
	result["h1_text"] =  "2013-2014学年度xx学校xx月考卷"
	result["h2"] = "1"
	result["h2_l"] = "副标题"
	result["h2_text"] = "试卷副标题"
	result["h3"] = "1"
	result["h3_l"] = "装订线"
	result["h4"] = "1"
	result["h4_l"] = "保密标记"
	result["h4_text"] = "绝密★启用前"
	result["h5"] = "1"
	result["h5_l"] = "试卷信息栏"
	result["h5_text"] = "考试范围：xxx；考试时间：100分钟；命题人：xxx"
	result["h6"] = "1"
	result["h6_l"] = "考生输入栏"
	result["h6_text"] = "学校：___________姓名：___________班级：___________考号：___________"
	result["h7"] = "1"
	result["h7_l"] = "誉分栏"
	result["h8"] = "1"
	result["h8_l"] = "注意事项栏"
	result["h8_text"] = "1. 答题前填写好自己的姓名、班级、考号等信息<br/>2. 请将答案正确填写在答题卡上"
	result["b1"] = "1"
	result["b1_l"] = "第I卷(选择题)"
	result["b1_juanbiao"] = "分卷I"
	result["b1_juanzhu"] = "分卷I 注释"
	result["b2"] = "1"
	result["b2_l"] = "第II卷(非选择题)"
	result["b2_juanbiao"] = "分卷II"
	result["b2_juanzhu"] = "分卷II 注释"
	result["tx"] = tx
	local ti = {}	
	local question_info = cjson.decode(qtids)
	if question_info.success == true then
		local ids = question_info.question_ids
		for i=1,#ids do
			local id = ids[i]
			local q_info = redis_db:hget("question_"..id,"json_question")
			ti[i] = cjson.decode(ngx.decode_base64(q_info))			
			ti[i]["id"] = ids[i]
		end
		result["success"] = true
		result["ti"] = ti	
		redis_db:del("AutoPaper_"..logo_id)
		redis_db:set_keepalive(0,v_pool_size)
		cjson.encode_empty_table_as_object(false);		
		ngx.print(cjson.encode(result))
		ngx.exit(ngx.HTTP_OK)
	else
		result["success"] = false
		result["info"] = "很抱歉！未能找到满足条件的试题，请修改条件后重新组卷。"
		redis_db:del("AutoPaper_"..logo_id)
		redis_db:set_keepalive(0,v_pool_size)
		cjson.encode_empty_table_as_object(false);		
		ngx.print(cjson.encode(result))
		ngx.exit(ngx.HTTP_OK)
	end
	
end

ngx.sleep(0.5)

end


