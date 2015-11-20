#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#lzy 2015-09-07
#描述：设置试题的删除状态
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local person_id = tostring(args["person_id"])
if person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local identity_id = tostring(args["identity_id"])
if identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

local question_id_char = tostring(args["question_id_char"])
if question_id_char == "nil" then
    ngx.say("{\"success\":false,\"info\":\"question_id_char参数错误！\"}")
    return
end

local del_type = tostring(args["del_type"])
if del_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"del_type参数错误！\"}")
    return
end
local structure_ids = tostring(args["structure_ids"])
if structure_ids == "nil" then
    ngx.say("{\"success\":false,\"info\":\"structure_ids参数错误！\"}")
    return
end


local cjson = require "cjson";

local b_delete;
local type_id;
local b_delete_check;

local delete_status = tostring(args["delete_status"])
if delete_status == "nil" then
    ngx.say("{\"success\":false,\"info\":\"delete_status参数错误！\"}")
    return
end

if delete_status == "2" then--删除到回收站
    b_delete = 2;
	type_id = 10;
	b_delete_check = "0";
elseif delete_status == "0" then--还原
    b_delete = 0;
	type_id = 6;
	b_delete_check = "2";
elseif delete_status == "1" then--彻底删除
    b_delete = 1;
	type_id = 6;
	b_delete_check = "2";
end

--连接数据库
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();

local SSDBUtil = require "common.SSDBUtil";

local ssdb = SSDBUtil:getDb();

-- 发送删除试题的异步消息
local function sendAsyncCmd(quesIdChar, delType, strucIdArray)
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
	local paramObj  = {};
	paramObj["question_id_char"] = quesIdChar;
	paramObj["del_type"]         = delType;
	paramObj["structure_ids"]    = strucIdArray;
	local asyncQueueService = require "common.AsyncDataQueue.AsyncQueueService";
	local asyncCmdStr       = asyncQueueService: getAsyncCmd("003003", paramObj)
	ngx.log(ngx.ERR, "[sj_log] -> [supervise] -> asyncCmdStr: [", asyncCmdStr, "]");
	asyncQueueService: sendAsyncCmd(asyncCmdStr);
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
end

local myts = require "resty.TS";
--去缓存中取sheng,shi,qu,xiao
local person_map = cache:hmget("person_"..person_id.."_"..identity_id,"sheng","shi","qu","xiao");
local provinceId = person_map[1];
local cityId 	 = person_map[2];
local districtId = person_map[3];
local schoolId   = person_map[4];
local update_ts =  myts.getTs();
if del_type == "1" then
	--全部删除试题
	--ngx.log(ngx.ERR,"-----------------全部删除");
	local sql = "SELECT ID, STRUCTURE_ID_INT FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='"..question_id_char.."' "..
                        "AND GROUP_ID NOT IN("..provinceId..","..cityId..","..districtId..","..schoolId..") AND B_IN_PAPER=0 AND B_DELETE="..b_delete_check.." And CREATE_PERSON="..person_id;
						
	local infoRecordList = db:query(sql);

	for i=1,#infoRecordList do
		  sql = "UPDATE T_TK_QUESTION_INFO SET B_DELETE="..b_delete..", UPDATE_TS="..update_ts.." WHERE ID="..infoRecordList[i]["ID"];
		  db:query(sql);
		  cache:hset("question_"..infoRecordList[i]["ID"],"b_delete",b_delete);
		  if delete_status == "1" then
			  local ssdbKey  = person_id.."_"..identity_id.."_"..question_id_char.."_"..infoRecordList[i]["STRUCTURE_ID_INT"];
			  local hashKey = "is_struc_repeat";
			--  ngx.log(ngx.ERR,"===================>"..ssdbKey);
			  local result, err = ssdb:multi_hdel(ssdbKey, hashKey);
		  end
	end

	
	local sql_sel_myinfo = "SELECT ID, QUESTION_ID_CHAR, QUESTION_ID_INT_BAK_DEL, QUESTION_TITLE, "..
							"QUESTION_TYPE_ID, KG_ZG, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, SCHEME_ID_INT, "..
							"STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, TYPE_ID, TABLE_PK, UPLOADER_ID, DOWN_COUNT,  "..
							"B_DELETE FROM T_TK_QUESTION_MY_INFO WHERE QUESTION_ID_CHAR= '"..question_id_char.."'";
	
	local myInfoRecordList = db:query(sql_sel_myinfo);
	for h=1,#myInfoRecordList do
	    --删除我的试题中的数据
		local my_sql = "UPDATE T_TK_QUESTION_MY_INFO SET B_DELETE="..b_delete..", UPDATE_TS="..update_ts..",TYPE_ID = "..type_id.." WHERE ID ="..myInfoRecordList[h]["ID"]
		db:query(my_sql);
		cache:hset("myquestion_"..myInfoRecordList[h]["ID"],"b_delete",b_delete)
		cache:hset("myquestion_"..myInfoRecordList[h]["ID"],"type_id",type_id)
	end

	--获取删除试题信息后的知识点
	local zsd_sql = "SELECT T1.STRUCTURE_ID_INT, T2.STRUCTURE_NAME as STRUCTURE_NAME  FROM T_TK_QUESTION_INFO T1 "..
                " INNER JOIN T_RESOURCE_STRUCTURE T2 ON T1.STRUCTURE_ID_INT=T2.STRUCTURE_ID AND T2.TYPE_ID=2"..
                " WHERE T1.QUESTION_ID_CHAR='"..question_id_char.."' AND T1.B_DELETE="..b_delete_check.." AND T1.B_IN_PAPER=0 GROUP BY T1.STRUCTURE_ID_INT";
	
	local zsd_list = db:query(zsd_sql);
	local zsdStr="";
	if #zsd_list>0 then
		for j=1,#zsd_list do
			local strucName = zsd_list[j]["STRUCTURE_NAME"];
			zsdStr = zsdStr..","..strucName
		end
		zsdStr = string.sub(zsdStr,0,#zsdStr-1)
	end
	
	--更新t_tk_question_info表中未删除的记录的json_question字段中的知识点
	local sql_info = "SELECT ID, QUESTION_ID_CHAR, QUESTION_TITLE, QUESTION_TIPS, QUESTION_TYPE_ID, "..
                "QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, KG_ZG, SCHEME_ID_INT, STRUCTURE_ID_INT, JSON_QUESTION, "..
                "JSON_ANSWER, UPDATE_TS, STRUCTURE_PATH, B_IN_PAPER, PAPER_ID_INT, B_DELETE, OPER_TYPE, DOWN_COUNT, CHECK_STATUS, "..
                "CHECK_MSG, SORT_ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR = '"..question_id_char.."' and b_delete = "..b_delete_check;
	
	local quesToUpdate = db:query(sql_info);
	
	for m=1,#quesToUpdate do
		 local quesJson = cjson.decode(ngx.decode_base64(quesToUpdate[m]["JSON_QUESTION"]));
		  --quesJson.put("zsd", zsdStr);
		  quesJson.zsd = zsdStr;
		  local newJsonQues = ngx.encode_base64(cjson.encode(quesJson));
		 -- ngx.log(ngx.ERR,"newJsonQues==============="..newJsonQues);
		  
		  local up_info_json = "UPDATE T_TK_QUESTION_INFO SET JSON_QUESTION='"..newJsonQues.."', UPDATE_TS="..update_ts.." WHERE ID="..quesToUpdate[m]["ID"];
		  db:query(up_info_json);
		  --更新缓存
		  cache:hset("question_"..quesToUpdate[m]["ID"],"json_question",quesToUpdate[m]["JSON_QUESTION"])
	end
	--更新t_tk_question_my_info表中未删除的记录的json_question字段中的知识点
	
	local sql_my_info = "SELECT ID, QUESTION_ID_CHAR, QUESTION_ID_INT_BAK_DEL, QUESTION_TITLE, "..
						"QUESTION_TYPE_ID, KG_ZG, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, SCHEME_ID_INT, "..
						"STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, TYPE_ID, TABLE_PK, UPLOADER_ID, DOWN_COUNT, "..
						"B_DELETE FROM T_TK_QUESTION_MY_INFO WHERE QUESTION_ID_CHAR='"..question_id_char.."'";
	local myQuesToUpdate = db:query(sql_my_info);
	for n=1,#myQuesToUpdate do
		 local quesJson = cjson.decode(ngx.decode_base64(myQuesToUpdate[n]["JSON_QUESTION"]));
		 -- quesJson.put("zsd", zsdStr);
		  quesJson.zsd = zsdStr;
		  local newJsonQues = ngx.encode_base64(cjson.encode(quesJson));
		  ngx.log(ngx.ERR,"newJsonQues==============="..newJsonQues);
		  
		  local up_info_json = "UPDATE T_TK_QUESTION_MY_INFO SET JSON_QUESTION='"..newJsonQues.."', UPDATE_TS="..update_ts.." TYPE_ID = "..type_id.." WHERE ID="..myQuesToUpdate[n]["ID"];
		  db:query(up_info_json);
		  --更新缓存
		  cache:hset("myquestion_"..myQuesToUpdate[n]["ID"],"json_question",myQuesToUpdate[n]["JSON_QUESTION"])
		  cache:hset("myquestion_"..myQuesToUpdate[n]["ID"],"type_id",type_id)
	end
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
	sendAsyncCmd(question_id_char, del_type, nil);
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin

else
    ngx.log(ngx.ERR,"-----------------删除指定的");
	ngx.log(ngx.ERR,"structure_ids-----------------"..structure_ids);
     local strucIdArray = Split(structure_ids,",");


	 for i=1,#strucIdArray do
	 
		 local sql = "SELECT ID, STRUCTURE_ID_INT FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='"..question_id_char.."' AND STRUCTURE_ID_INT="..strucIdArray[i]..
                            " AND GROUP_ID NOT IN("..provinceId..","..cityId..","..districtId..","..schoolId..") AND B_IN_PAPER=0 AND B_DELETE= "..b_delete_check.." And CREATE_PERSON="..person_id;

		--ngx.log(ngx.ERR,"================================"..sql.."=============================")
		 local delQuesList = db:query(sql);
			 for j=1,#delQuesList do
				sql = "UPDATE T_TK_QUESTION_INFO SET B_DELETE="..b_delete..", UPDATE_TS="..update_ts.." WHERE ID="..delQuesList[j]["ID"];
				db:query(sql);
				--修改缓存
				 cache:hset("question_"..delQuesList[j]["ID"],"b_delete",b_delete);
				if delete_status == "1" then
					local ssdbKey  = person_id.."_"..identity_id.."_"..question_id_char.."_"..delQuesList[j]["STRUCTURE_ID_INT"];
					local hashKey = "is_struc_repeat";
					ngx.log(ngx.ERR,"===================>"..ssdbKey);
					local result, err = ssdb:multi_hdel(ssdbKey, hashKey);
				end
			 end

		 local sql_my = "SELECT ID, QUESTION_ID_CHAR, QUESTION_ID_INT_BAK_DEL, QUESTION_TITLE, "..
				"QUESTION_TYPE_ID, KG_ZG, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, SCHEME_ID_INT, "..
				"STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, TYPE_ID, TABLE_PK, UPLOADER_ID, DOWN_COUNT,  "..
				"B_DELETE FROM T_TK_QUESTION_MY_INFO WHERE QUESTION_ID_CHAR = '"..question_id_char.."' and STRUCTURE_ID_INT ="..strucIdArray[i];
		local delMyQuesList = db:query(sql_my);
			for k=1,#delMyQuesList do
			   sql = "UPDATE T_TK_QUESTION_MY_INFO SET B_DELETE="..b_delete..", UPDATE_TS="..update_ts..",TYPE_ID = "..type_id.." WHERE ID ="..delMyQuesList[k]["ID"];
			   db:query(sql);
			   cache:hset("myquestion_"..delMyQuesList[k]["ID"],"b_delete",b_delete)
			   cache:hset("myquestion_"..delMyQuesList[k]["ID"],"type_id",type_id)
			end
	
	 end


	  --更新t_tk_question_info表中未删除的记录的json_question字段中的知识点
	local sql_info = "SELECT ID, QUESTION_ID_CHAR, QUESTION_TITLE, QUESTION_TIPS, QUESTION_TYPE_ID, "..
                "QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, KG_ZG, SCHEME_ID_INT, STRUCTURE_ID_INT, JSON_QUESTION, "..
                "JSON_ANSWER, UPDATE_TS, STRUCTURE_PATH, B_IN_PAPER, PAPER_ID_INT, B_DELETE, OPER_TYPE, DOWN_COUNT, CHECK_STATUS, "..
                "CHECK_MSG, SORT_ID FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR = '"..question_id_char.."' and b_delete = "..b_delete_check;
	
	ngx.log(ngx.ERR,"***************************"..sql_info.."**************************")
	local quesToUpdate = db:query(sql_info);
	
	for m=1,#quesToUpdate do
		 local quesJson = cjson.decode(ngx.decode_base64(quesToUpdate[m]["JSON_QUESTION"]));
		 -- quesJson.put("zsd", zsdStr);
		  quesJson.zsd = zsdStr;
		  local newJsonQues = ngx.encode_base64(cjson.encode(quesJson));
		  --ngx.log(ngx.ERR,"newJsonQues==============="..newJsonQues);
		  
		  local up_info_json = "UPDATE T_TK_QUESTION_INFO SET JSON_QUESTION='"..newJsonQues.."', UPDATE_TS="..update_ts.." WHERE ID="..quesToUpdate[m]["ID"];
		  db:query(up_info_json);
		  --修改缓存
		  cache:hset("question_"..quesToUpdate[m]["ID"],"json_question",quesToUpdate[m]["JSON_QUESTION"])
	end
	--更新t_tk_question_my_info表中未删除的记录的json_question字段中的知识点
	
	local sql_my_info = "SELECT ID, QUESTION_ID_CHAR, QUESTION_ID_INT_BAK_DEL, QUESTION_TITLE, "..
						"QUESTION_TYPE_ID, KG_ZG, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, TS, SCHEME_ID_INT, "..
						"STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, TYPE_ID, TABLE_PK, UPLOADER_ID, DOWN_COUNT, "..
						"B_DELETE FROM T_TK_QUESTION_MY_INFO WHERE QUESTION_ID_CHAR='"..question_id_char.."'";

	local myQuesToUpdate = db:query(sql_my_info);
	for n=1,#myQuesToUpdate do
		 local quesJson = cjson.decode(ngx.decode_base64(myQuesToUpdate[n]["JSON_QUESTION"]));
		  quesJson.zsd = zsdStr;
		--  quesJson.put("zsd", zsdStr);
		  local newJsonQues = ngx.encode_base64(cjson.encode(quesJson));
		  local up_info_json = "UPDATE T_TK_QUESTION_MY_INFO SET JSON_QUESTION='"..newJsonQues.."', UPDATE_TS="..update_ts.." WHERE ID="..myQuesToUpdate[n]["ID"];
		  db:query(up_info_json);
		  cache:hset("myquestion_"..myQuesToUpdate[n]["ID"],"json_question",myQuesToUpdate[n]["JSON_QUESTION"]);
	end
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
	sendAsyncCmd(question_id_char, del_type, strucIdArray);
	-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池

db:set_keepalive(0,v_pool_size)
local responseObj = {};
responseObj.success = true;
responseObj.info = "还原成功";


cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

ngx.say(responseJson)


