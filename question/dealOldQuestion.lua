#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-01-29
#描述：处理旧试题的MD5的值，写入到ssdb中
]]

-- local request_method = ngx.var.request_method;
-- local args = nil;
-- if "GET" == request_method then
    -- args = ngx.req.get_uri_args();
-- else
    -- ngx.req.read_body();
    -- args = ngx.req.get_post_args();
-- end

-- if args["param"] == nil or args["param"]=="" then
	-- ngx.print("{\"success\":\"false\",\"info\":\"参数param不能为空！\"}");
	-- return;
-- end

local function getDb()
	local mysql = require "resty.mysql";
	local local_db, err = mysql : new();
	if not local_db then 
		ngx.log(ngx.ERR, err);
		return nil;
	end

	local_db:set_timeout(1000) -- 1 sec

	local ok, err, errno, sqlstate = local_db:connect{
		host = v_mysql_ip,
		port = v_mysql_port,
		database = v_mysql_database,
		user = v_mysql_user,
		password = v_mysql_password,
		max_packet_size = 1024 * 1024 }

	if not ok then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
		ngx.log(ngx.ERR, "=====> 连接数据库失败!");
		return nil;
	end
	
	return local_db;
end

-- 3. 获取数据库连接
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
    ngx.print("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end

-- 4.获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.print("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


-- 获取SSDB连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local querySsdb = ssdblib:new()
local ok, err = querySsdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson";

-- 获取T_TK_QUESTION_BASE表记录总数
local sql = "SELECT COUNT(1) AS TOTAL_COUNT FROM T_TK_QUESTION_BASE";
local countTab = db:query(sql);
local count = tonumber(countTab[1]["TOTAL_COUNT"]);
ngx.log(ngx.ERR, "===> T_TK_QUESTION_BASE 表的记录总数 ===> ", count, type(count));

-- 轮询T_TK_QUESTION_BASE表，每次取1000条
-- count = 10;
local offset = 0;
local limit = 50;
local sql = "SELECT QUESTION_ID_CHAR, CONTENT_MD5, CREATE_PERSON, FILE_ID FROM T_TK_QUESTION_BASE ORDER BY TS ASC LIMIT " .. offset .. ", " .. limit;

ngx.log(ngx.ERR, "===> 开始处理！");

local updateDb = getDb();
local subQueryDb = getDb();

while offset < count do
	local updateSql = "START TRANSACTION;";

	local result, err, errno, sqlstate = db:query(sql);
	
	ssdb:init_pipeline();
	
	for i=1, #result do
		--ngx.log(ngx.ERR, "===> result[i] ===> ", cjson.encode(result[i]), result[i]["CONTENT_MD5"]~=ngx.null);
		ngx.log(ngx.ERR, "===> 正在处理第".. (offset+i) .."条记录！ ===> ");
		
		if result[i]["CONTENT_MD5"]~=ngx.null and result[i]["CONTENT_MD5"]~=nil then
			
			-- 更新T_TK_QUESTION_BASE表中的FILE_ID字段
			local questionIdChar = result[i]["QUESTION_ID_CHAR"];
			local contentMd5     = result[i]["CONTENT_MD5"];
			local createPerson   = result[i]["CREATE_PERSON"];
			local oldFileId      = (result[i]["FILE_ID"]~=ngx.null and result[i]["FILE_ID"]) or 0;
			
			local fileIdTab = querySsdb:hget("md5_ques_"..contentMd5, "file_id");
			ngx.log(ngx.ERR, "===> hash-key ===> ", "md5_ques_"..contentMd5);
			ngx.log(ngx.ERR, "===> fileIdTab ===> ", cjson.encode(fileIdTab));
			-- ngx.log(ngx.ERR, "===> fileIdTab to json ===> ", cjson.encode(fileIdTab));
			if fileIdTab ~= nil then
				local fileId    = fileIdTab[1];
				
				-- 更新T_TK_QUESTION_BASE表中的FILE_ID字段
				if oldFileId ~= fileId then					
					updateSql = updateSql .. "UPDATE T_TK_QUESTION_BASE SET FILE_ID='"..fileId.."' WHERE QUESTION_ID_CHAR='"..  questionIdChar .."';";										
				end
			
				-- 同步SSDB -> md5_ques_[md5]
				local subSql = "SELECT ID, STRUCTURE_ID_INT, CREATE_PERSON FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='".. questionIdChar	.."' AND OPER_TYPE=1;";
				
				local subResult, err, errno, sqlstate = subQueryDb:query(subSql);
				ngx.log(ngx.ERR, "===> subResult ===> ", cjson.encode(subResult));
				if subResult~=nil and subResult~=ngx.null and #subResult>0 then
					
					for j=1, #subResult do
						ngx.log(ngx.ERR, "===> 循环向ssdb中存数据！ ");
						local personId   = subResult[j]["CREATE_PERSON"];
						local identityId = "5";
						if personId == "1" then
							identityId = "2";
						else
							identityId = "5";
						end
						local strucIdInt = subResult[j]["STRUCTURE_ID_INT"];
						local quesInfoId = subResult[j]["ID"];
						local existTab   = querySsdb:hexists("md5_ques_" .. contentMd5, personId.."_"..identityId.."_"..strucIdInt);
						local isExist    = existTab[1];
						
						ssdb:hset("md5_ques_" .. contentMd5, personId.."_"..identityId, questionIdChar);
						if isExist == "0" then
							ssdb:hset("md5_ques_" .. contentMd5, personId.."_"..identityId.."_"..strucIdInt, quesInfoId);
						end
					end
				end
			end		
		end
	end
	
	updateSql = updateSql .. "COMMIT;";
	
	local updateResult, err, errno, sqlstate = updateDb:query(updateSql);
	if not updateResult then  
		ngx.log(ngx.ERR, "===> 执行updateSql出错！！错误信息：err: ", err, "==> errno: ", errno, "==> sqlstate: ", sqlstate);
		return
	end
	
	-- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
	while err == "again" do
		res, err, errno, sqlstate = updateDb:read_result()
		if not res then
			ngx.log(ngx.ERR, "bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")			
		end
	end
	
	--管道提交
	local ssdb_results, err = ssdb:commit_pipeline();
	ngx.log(ngx.ERR, " ===> ssdb 提交的结果：", cjson.encode(ssdb_results));
	if not ssdb_results then  
		ngx.log(ngx.ERR, " ===> 写入ssdb出错！<=== ");
		return
	end
	ngx.log(ngx.ERR, " ===> 已处理 ".. (offset+limit) .. "条 <=== ");
	
	offset = offset + limit;
end

-- 将SSDB连接归还连接池
ssdb:set_keepalive(0,v_pool_size)
querySsdb:set_keepalive(0,v_pool_size)

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

updateDb:set_keepalive(0, v_pool_size);
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end