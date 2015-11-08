#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-11-30
#描述：一次全部审核该科目下所有的资源
]]

if ngx.var.cookie_product_id == nil or ngx.var.cookie_product_id=="" then 
	ngx.say("{\"success\":\"false\",\"info\":\"从cookie中获取product_id失败！\"}")
    return
elseif ngx.var.cookie_background_stage_id == nil or ngx.var.cookie_background_stage_id=="" then 
	ngx.say("{\"success\":\"false\",\"info\":\"从cookie中获取background_stage_id失败！\"}")
    return
elseif ngx.var.cookie_background_subject_id == nil or ngx.var.cookie_background_subject_id=="" then 
	ngx.say("{\"success\":\"false\",\"info\":\"从cookie中获取background_subject_id失败！\"}")
    return
end

local productId = tostring(ngx.var.cookie_product_id);
local stageId 	= tostring(ngx.var.cookie_background_stage_id);
local subjectId = tostring(ngx.var.cookie_background_subject_id);

local responseObj = {};
-- 先给前台响应，再进行数据处理
responseObj.success = true;
responseObj.info = "后台正在进行数据处理，请稍后查看审核结果！";

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

--------------------------------------------------------------------------------
-- 局部函数：获取当前时间戳
local function getTS()
    local t=ngx.now();
    local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14);
    n = n..string.rep("0",19-string.len(n));
    return n;
end 

-- 局部函数：判断param是否为空
local function isNull(param)
    local returnVal = false;
    
    if param == nil or param == ngx.null or (type(param)=="string" and param == "") then
        returnVal = true;
    end
    
    return returnVal;
end

-- 局部函数：如果param为空，则返回defaultVal;如果param不为空，则返回param
local function defaultIfNull(param, defaultVal)
    -- local isNull = isParamNull(param);
    -- if isNull then
        -- return defaultVal;
    -- else
        -- return param;
    -- (a and b) or c 相当于三目运算符 a ? b : c 
    return (isNull(param) and param) or defaultVal;
end

-- 当前的时间戳
local currentTS = getTS();

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
    -- ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    -- ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


-- 局部函数：根据RESOURCE_ID_INT获取info的记录
local function getInfoCache(resourceIdInt)

	local sql = "SELECT ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int," .. tostring(resourceIdInt) .. ";filter=group_id,2;';";
	
	local res, err, errno, sqlstate = db:query(sql);
	if not res then
		ngx.log(ngx.ERR, "===> getInfoId execute sql error===> bad result: ", err, ": ", errno, ": ", sqlstate, ".");
		return nil;
	end
	
	local infoId = res[1]["ID"];
	
	local cacheInfo, err = ssdb_db:multi_hget("resource_" .. infoId, "app_type_id");
	if isNull(cacheInfo) then
		ngx.log(ngx.ERR, "===> getInfoId cache hmget error===> bad result: ", err, ": ", errno, ": ", sqlstate, ".");
		return nil;
	end
	
	return cacheInfo[2];
end

local sql = "SELECT T1.RESOURCE_ID_INT, T1.RESOURCE_ID_CHAR, T1.RESOURCE_TITLE, T1.RESOURCE_SIZE, T1.RESOURCE_SIZE_INT, " ..
            "T1.RESOURCE_TYPE, T1.RESOURCE_TYPE_NAME, T1.EXTENSION, T1.RESOURCE_PAGE, T1.CREATE_TIME," ..
            "T1.DOWN_COUNT, T1.FILE_ID, T1.THUMB_ID, T1.SCHEME_ID, T1.STRUCTURE_ID, T1.TS, " ..
            "T1.CREATE_PERSON, T1.PERSON_NAME, 5, T1.PREVIEW_STATUS, T1.THUMB_STATUS, " ..
            "T1.FOR_URLENCODER_URL, T1.FOR_ISO_URL, T1.WIDTH, T1.HEIGHT, " ..
            "T1.PARENT_NAME, T1.RELEASE_STATUS, T1.RES_TYPE, T1.BK_TYPE, T1.BK_TYPE_NAME, T1.MATERIAL_TYPE, " ..
            "T1.M3U8_STATUS, T1.M3U8_URL " ..
            "FROM T_RESOURCE_BASE T1 INNER JOIN T_RESOURCE_PRODUCT_SCHEME T2 " ..
            "ON T1.SCHEME_ID=T2.SCHEME_ID AND T2.PRODUCT_ID=" .. productId .. " AND T2.B_USE=1 AND T1.CHECK_STATUS=2; ";

ngx.log(ngx.ERR, "===sql===> " .. sql .. " <===sql===");			

local results, err, errno, sqlstate = db:query(sql);
if not results then
	-- ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end


local updateSql = "";
local totalResSize = 0;

for i=1, #results do

	local record = results[i];
    local infoCache = getInfoCache(record.RESOURCE_ID_INT);
	ngx.log(ngx.ERR, "===> app_type_id ===> ", infoCache[1]);
	
	if infoCache~=nil then
		
		local app_type_id = infoCache[1];
		
		totalResSize = totalResSize + defaultIfNull(record.RESOURCE_SIZE_INT, 0);
		
		updateSql = updateSql .. "START TRANSACTION;UPDATE T_RESOURCE_BASE SET CHECK_STATUS=1, CHECK_MESSAGE='审核通过' WHERE RESOURCE_ID_INT=" .. record.RESOURCE_ID_INT .. ";";
		
		updateSql = updateSql .. "INSERT INTO t_resource_info(" .. 
			  "RESOURCE_ID_INT, RESOURCE_ID_CHAR, RESOURCE_TITLE,RESOURCE_SIZE, RESOURCE_SIZE_INT," .. 
			 " RESOURCE_TYPE, RESOURCE_TYPE_NAME, RESOURCE_FORMAT,RESOURCE_PAGE,  CREATE_TIME," .. 
			  "DOWN_COUNT, FILE_ID, THUMB_ID, SCHEME_ID_INT,STRUCTURE_ID, TS, UPDATE_TS," .. 
			  "PERSON_ID, PERSON_NAME, IDENTITY_ID, GROUP_ID, PREVIEW_STATUS,THUMB_STATUS," .. 
			  "FOR_URLENCODER_URL, FOR_ISO_URL, WIDTH, HEIGHT," .. 
			  "PARENT_STRUCTURE_NAME, RELEASE_STATUS, RES_TYPE, BK_TYPE, BK_TYPE_NAME, MATERIAL_TYPE," .. 
			  "M3U8_STATUS, M3U8_URL, APP_TYPE_ID" .. 
			")	VALUES (" .. 
			  record.RESOURCE_ID_INT .. ",'" .. record.RESOURCE_ID_CHAR .. "','" .. record.RESOURCE_TITLE .."','" .. record.RESOURCE_SIZE .. "',"  ..record.RESOURCE_SIZE_INT .. "," ..
			  record.RESOURCE_TYPE .. ",'" .. record.RESOURCE_TYPE_NAME .."','".. record.EXTENSION .. "'," .. record.RESOURCE_PAGE .. ",'" .. record.CREATE_TIME .. "'," ..
			  record.DOWN_COUNT .. ",'" .. record.FILE_ID .. "','" .. record.THUMB_ID .. "'," .. record.SCHEME_ID .. "," .. record.STRUCTURE_ID .. "," .. record.TS .. "," ..  currentTS .. "," .. 
			  record.CREATE_PERSON .. ",'" .. record.PERSON_NAME .. "',5,1," .. record.PREVIEW_STATUS .. "," .. record.THUMB_STATUS .. ",'" .. record.FOR_URLENCODER_URL .. "','" .. record.FOR_ISO_URL .. "'," .. record.WIDTH .. "," .. record.HEIGHT .. ",'" .. record.PARENT_NAME .. "'," .. record.RELEASE_STATUS .. "," .. record.RES_TYPE .. "," .. record.BK_TYPE .. ",'" .. record.BK_TYPE_NAME .. "'," .. record.MATERIAL_TYPE .. "," .. record.M3U8_STATUS .. ",'" .. record.M3U8_URL .. "'," .. app_type_id .. 
			");COMMIT;";
			--SELECT LAST_INSERT_ID() AS NEW_INFO_ID;
		
		-- 执行sql
		local res, err, errno, sqlstate = db:query(updateSql)
		if not res then
			-- ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			return
		end
		
		local newInfoId = nil;
		local resIndex = 1;
		local doSuccess = true;
		ngx.log(ngx.ERR, "===>", resIndex, "===> type: ", type(res), ", value: ", cjson.encode(res));
		
		-- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
		while err == "again" do
			resIndex = resIndex + 1;
			res, err, errno, sqlstate = db:read_result();
			ngx.log(ngx.ERR, "===>", resIndex, "===> type: ", type(res), ", value: ", cjson.encode(res));
			if not res then
				ngx.log(ngx.ERR, "bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")
				doSuccess = doSuccess and false;
			end
			
			if doSuccess and resIndex==3 then
				newInfoId = res.insert_id;
			end 
		end
		
		ngx.log(ngx.ERR, "===> doSuccess ===> ", doSuccess);
		-- 数据库处理成功
		if not doSuccess then
			ngx.log(ngx.ERR, "审核resource_id_int为"..record.RESOURCE_ID_INT.."的资源出错！");
		else
			cache:hmset(
					"resource_" .. newInfoId, 
					"resource_id_int",      tostring(record.RESOURCE_ID_CHAR), 
					"resource_id_int",      tostring(record.RESOURCE_ID_INT), 
					"resource_title",       tostring(record.RESOURCE_TITLE),
					"resource_type",        tostring(record.RESOURCE_TYPE),
					"resource_type_name",   tostring(record.RESOURCE_TYPE_NAME),
					"resource_format",      tostring(record.EXTENSION),
					"resource_page",        tostring(defaultIfNull(record.RESOURCE_PAGE, "0")),
					"resource_size",        tostring(record.RESOURCE_SIZE),
					"resource_size_int",    tostring(record.RESOURCE_SIZE_INT),
					"create_time",          tostring(record.CREATE_TIME),
					"down_count",           tostring(record.DOWN_COUNT),
					"file_id",              tostring(record.FILE_ID),
					"thumb_id",             tostring(record.THUMB_ID),
					"person_id",            tostring(record.CREATE_PERSON),
					"identity_id",          tostring(record.IDENTITY_ID),
					"person_name",          tostring(record.PERSON_NAME, 未知),
					"structure_id",         tostring(record.STRUCTURE_ID) ,
					"scheme_id_int",        tostring(record.SCHEME_ID_INT),
					"preview_status",       tostring(record.PREVIEW_STATUS) ,
					"release_status",       tostring(defaultIfNull(record.RELEASE_STATUS, "1")),
					"for_urlencoder_url",   tostring(defaultIfNull(record.FOR_URLENCODER_URL, "-1")) ,
					"for_iso_url",          tostring(defaultIfNull(record.FOR_ISO_URL, "-1")),
					"width",                tostring(record.WIDTH) ,
					"height",               tostring(record.HEIGHT) ,
					"material_type",        tostring(defaultIfNull(record.MATERIAL_TYPE, "0")),
					"res_type",         	tostring(record.RES_TYPE) ,
					"bk_type_name",         tostring(record.BK_TYPE_NAME) ,
					"beike_type",           tostring(record.BK_TYPE) ,
					"m3u8_status",          tostring(defaultIfNull(record.M3U8_STATUS, "0")),
					"m3u8_url",             tostring(defaultIfNull(record.M3U8_URL, "暂无")),
					"app_type_id",          tostring(app_type_id),
					"parent_structure_name", "未知"
				)                
		end
	end
end
ngx.log(ngx.ERR, "===> tongji url ===>", "/dsideal_yy/ypt/tongji/tj_upload?stage_id="..stageId.."&subject_id="..subjectId.."&type_id=1&mtype=-1&size="..tostring(totalResSize/1024) .. "&count=" .. #results);

--local response = ngx.location.capture("/dsideal_yy/ypt/tongji/tj_upload?stage_id="..stageId.."&subject_id="..subjectId.."&type_id=1&mtype=-1&size="..tostring(totalResSize/1024) .. "&count=" .. #results);
-- local response = ngx.location.capture("/dsideal_yy/ypt/tongji/tj_upload", {
	-- method = ngx.HTTP_POST,
	-- args = "stage_id="..stageId.."&subject_id="..subjectId.."&type_id=1&mtype=-1&size="..tostring(totalResSize/1024) .. "&count=" .. #results, 
	-- body = "aaa"
-- });

--ngx.header['Set-Cookie'] = {'person_id=32; path=/', 'identity_id=4; path=/'}
local response = ngx.location.capture("/dsideal_yy/ypt/tongji/tj_upload", {
	method = ngx.HTTP_POST,
	body = "stage_id="..stageId.."&subject_id="..subjectId.."&type_id=1&mtype=-1&size="..tostring(totalResSize/1024) .. "&count=" .. #results
	-- args = {
		-- stage_id = stageId,
		-- subject_id = subjectId,
		-- type_id = "1",
		-- mtype = "-1",
		-- size = tostring(totalResSize/1024),
		-- count = "1"
	-- }
});

local ss = response.body;
ngx.log(ngx.ERR, "===> response.body ===> ", ss);
-- if not isNull(response) then
	-- local responseStr =  cjson.decode(response.body)
	-- ngx.log(ngx.ERR, "===>调用统计接口的返回值===>", responseStr);
-- end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);







