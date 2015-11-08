#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-1-27
#描述：判断试题是否已经存在或已经重复
]]

-- 获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    ngx.print("{\"success\":\"false\",\"info\":\"此函数只支持POST请求！\"}");
	ngx.exit(ngx.HTTP_OK);
end

--[[
	局部函数：字符串分隔函数
]]
local function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

local cjson = require "cjson";
-- 获取redis连接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngxngx.print("{\"success\":false,\"info\":\"判断重复过程出错！\"}")
    ngx.log(ngx.ERR, "===> 获取连接出错 ===> ", err)
    return
end




local zlib = require "zlib"
local encoding = ngx.req.get_headers()["Content-Encoding"]
-- post参数在接收前首先要执行这个
ngx.req.read_body();

ngx.log(ngx.ERR, "====> isQuesExist Content-Encoding ===> ", encoding);
if encoding == "gzip" then
    local body = ngx.req.get_body_data()

    if body then
        local stream = zlib.inflate()
		local r = stream(body)
        ngx.req.set_body_data(r)
    else
		ngx.print("{\"success\":false,\"info\":\"读取请求的BODY出错\"}");
		ngx.exit(ngx.HTTP_OK);
	end
else
	ngx.print("{\"success\":false,\"info\":\"输入的内容未经过gzip压缩。\"}");
	ngx.exit(ngx.HTTP_OK);
end

args = ngx.req.get_post_args();

-- local ts_str = os.date("%Y-%m-%d %H:%M:%S");
-- ngx.print(ts_str);
if args["param_json"] == nil or args["param_json"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数param_json不能为空！\"}");
	return;
end
ngx.log(ngx.ERR, "===> args[\"param_json\"] ===> ", args["param_json"]);
local paramJsonStr = args["param_json"];
--local paramDecode  = ngx.decode_base64(paramJsonStr);
--ngx.log(ngx.ERR, "====> gizped stream ===> ", paramDecode);
--ngx.print(paramJsonStr);
-- 将参数转换成table对象
local paramJson = cjson.decode(paramJsonStr);
local quesList = paramJson.ques_list;


local personId   = ngx.var.cookie_person_id;
local identityId = ngx.var.cookie_identity_id;

-- 判断是否为东师理想的学科人员
local isDsidealPerson = false;
local captureResponse = ngx.location.capture("/dsideal_yy/ypt/question/isDsidealPerson", {
	method = ngx.HTTP_POST,
	body = "person_id="..personId.."&identity_id="..identityId
});
if captureResponse.status == ngx.HTTP_OK then
    resultJson = cjson.decode(captureResponse.body);
	ngx.log(ngx.ERR, "===> captureResponse.body ===> ", captureResponse.body);
	isDsidealPerson = resultJson.is_dsideal_person;
else
	ngx.print("{\"success\":false,\"info\":\"查询人员信息失败！\"}")
    return
end
ngx.log(ngx.ERR, "===> isDsidealPerson ===> ", isDsidealPerson);

-- 如果为东师理想的学科人员，则personId统一为1，因为东师理想的试题在上传时create_person为1
if isDsidealPerson then
	personId   = "1";
	identityId = "2";
end

-- 获取ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\"判断重复过程出错！\"}")
    ngx.log(ngx.ERR, "===> 获取ssdb连接出错 ===> ", err)
    return
end

local DBUtil   = require "common.DBUtil";
local SSDBUtil = require "multi_check.model.SSDBUtil";

-- 解析json对象
local strucId = paramJson.structure_id;

-- {
	-- "success": true,
	-- "que_list": 
	-- [
		-- {
			-- "question_id_char": "8A94C693-32E7-4E65-8307-20A2F6061E66",
			-- "file_exist": 0, //0文件不存在， 1文件已经存在
			-- "is_struc_repeat" : 0,
			-- "repeat_structure" : "", //重复的结点
			-- "file_id": "",
			-- "exist_ques_id_char" : ""
		-- },
		-- {
			-- "question_id_char": "DC37827B-D479-4F4B-BBBD-F970EDDDAA57",
			-- "file_exist": 1, //0文件不存在， 1文件已经存在
			-- "is_struc_repeat" : 1, //0章节目录下试题不存在，1章节目录下试题已存在
			-- "repeat_structure" : "23501,23502", //重复的结点，如果没有则为空字符串
			-- "file_id": "35EC5B6C-00D1-4CA2-BB86-CF13A446B6B9", //已有试题的FILE_ID,对应QUESTION.json文件中的t_id
			-- "exist_ques_id_char" : "FC37827B-D479-4F4B-BBBD-F970EDDDAA57" //如果试题已经存在，此属性为已有试题的ID
		-- }
	-- ]
-- }
local resultQuesList = {}

for i=1, #quesList do
	local quesJson   = quesList[i];
	local resultJson = {};
	
	local quesIdChar = quesJson.question_id_char;
	local zsdStr     = quesJson.zsd_id_chars;
	local contentMd5     = quesJson.content_md5;
	local existIdChar    = "";
	local isStrucRepeat  = false;
	local repeatStrucStr = "";
	
	-- 判断文件是否存在
	local existResult = ssdb:hexists("md5_ques_" .. contentMd5, "file_id");
	ngx.log(ngx.ERR, "===> existResult ===> ", type(existResult), " ===> ", cjson.encode(existResult));
	local isFileExist = existResult[1]; -- 返回值类型为table，["0"]或["1"]
	
	
	if isFileExist == "1" then -- 如果文件已经存在
		-- 获取试题的file_id,如果ssdb中存在，则重用
		local fileIdTab = ssdb:hget("md5_ques_"..contentMd5, "file_id");
		local fileId    = fileIdTab[1];

		-- 判断此用户是否已经上传过此试题
		local quesExistTab = ssdb:hexists("md5_ques_" .. contentMd5, personId .. "_" .. identityId);
		ngx.log(ngx.ERR, "===> quesExistTab ===> ", type(quesExistTab), " ===> ", cjson.encode(quesExistTab));
		local isQuesExist = quesExistTab[1]; -- 返回值类型为table，["0"]或["1"]
		
		local sql = "SELECT QUESTION_ID_CHAR, QUESTION_TITLE, JSON_ANSWER, JSON_QUESTION, FILE_ID  FROM T_TK_QUESTION_BASE WHERE CONTENT_MD5=" .. ngx.quote_sql_str(contentMd5) .. " LIMIT 1";
		local queryResult = DBUtil: querySingleSql(sql);

		if (queryResult ~= nil and queryResult ~= ngx.null and #queryResult ~= 0) then
			local quesBaseTable = {};
			quesBaseTable["question_id_cahr"] = queryResult[1]["QUESTION_ID_CHAR"];
			quesBaseTable["question_title"]   = queryResult[1]["QUESTION_TITLE"];
			quesBaseTable["json_question"]    = queryResult[1]["JSON_QUESTION"];
			quesBaseTable["json_answer"]      = queryResult[1]["JSON_ANSWER"];
			quesBaseTable["file_id"]      	  = fileId;
			local result = SSDBUtil:multi_hset("md5_ques_base_" .. contentMd5, quesBaseTable);
		end

		if isQuesExist == "1" then 
			local orginalIdCharTab = ssdb:hget("md5_ques_"..contentMd5, personId .. "_" .. identityId);
			existIdChar  = orginalIdCharTab[1];
			-- existIdChar  = cache:hget("question_"..orginalInfoId, "question_id_char");
		end
		
		-- 判断试题在章节目录下是否重复
		local hashKey 	= personId .. "_" .. identityId .. "_" .. strucId;
		ngx.log(ngx.ERR, "===> hashKey ===> ", personId .. "_" .. identityId .. "_" .. strucId);
		local isQuesStrucExistTab = ssdb:hexists("md5_ques_"..contentMd5, hashKey);
		local isQuesStrucExist    = isQuesStrucExistTab[1];
		
		if isQuesStrucExist == "1" then -- 判断试题在章节目录下是否重复
			-- local orginalInfoId = ssdb:hget("md5_ques_"..contentMd5, hashKey);
			-- existIdChar   = cache:hget("question_"..orginalInfoId, "question_id_char");
			isStrucRepeat = true;	
		end
		
		-- 判断试题在知识点下是否重复
		local zsdList = Split(zsdStr, ","); -- 获取试题所在的知识点
		-- 循环试题的知识点，判断其在知识点下是否重复
		for j=1, #zsdList do
			local zsdId = zsdList[j]
			hashKey 	= personId .. "_" .. identityId .. "_" .. zsdId;
			isQuesStrucExistTab = ssdb:hexists("md5_ques_"..contentMd5, hashKey);
			isQuesStrucExist    = isQuesStrucExistTab[1];
			
			if isQuesStrucExist == "1" then
				repeatStrucStr = repeatStrucStr .. "," .. zsdId;
			end
		
		end
		
		resultJson.question_id_char = quesIdChar;
		resultJson.file_exist       = 1;
		resultJson.is_ques_exist	= (isQuesExist == "1" and 1) or 0;
		resultJson.is_struc_repeat  = (isStrucRepeat and 1) or 0;
		if string.len(repeatStrucStr) > 1 then 
			resultJson.repeat_structure = string.sub(repeatStrucStr, 2, -1);
		else
			resultJson.repeat_structure = repeatStrucStr;
		end		
		resultJson.file_id = fileId;
		resultJson.exist_ques_id_char = existIdChar;
		
	else  -- 如果文件不存在
		resultJson.question_id_char   = quesIdChar;
		resultJson.file_exist 		  = 0;
		resultJson.is_ques_exist	  = 0;
		resultJson.is_struc_repeat 	  = 0;
		resultJson.repeat_structure   = "";
		resultJson.file_id 			  = "";
		resultJson.exist_ques_id_char = "";
	end
	
	table.insert(resultQuesList, resultJson);

end

local resultObj = {};
resultObj.success   = true;
resultObj.ques_list = resultQuesList;

local responseStr = cjson.encode(resultObj);
ngx.log(ngx.ERR, "===> isQuesExist 返回的值 ===> ", responseStr);
ngx.print(responseStr);

local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将SSDB连接归还连接池
ssdb:set_keepalive(0,v_pool_size)
