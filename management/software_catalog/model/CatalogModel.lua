-- -----------------------------------------------------------------------------------
-- 描述：前台插件列表 -> 查询软件列表、添加软件列表、修改软件列表、删除软件列表
-- -----------------------------------------------------------------------------------


local _CatalogModel = {};
local quote = ngx.quote_sql_str
local DBUtil   = require "common.DBUtil";

--[[
	局部函数：后台查询软件列表
	作者：刘全锋 2015-10-08
	参数：parent_id	--0查询所有软件大分类 非0根据parent_id查询软件
]]


local function queryCatalog(parent_id, pageNumber, pageSize)
	
	local db = DBUtil: getDb();

	local conditionSegement = " from t_software_catalog where";


	if tonumber(parent_id)==999999 then
		conditionSegement = conditionSegement .. " parent_id!=0";
	else
		conditionSegement = conditionSegement .. " parent_id="..parent_id;
	end

	local sql = "select id,software_name,parent_id,b_use ,pic_url,software_url,create_time,px,software_content,software_explain"..conditionSegement;

	local queryCount = "select count(1) as count"..conditionSegement;

	local per_count = db:query(queryCount);
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local sql_limit = " order by px desc,id desc limit "..offset..","..limit;
	local totalRow = per_count[1]["count"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	

	local res, err, errno, sqlstate = db:query(sql..sql_limit);
	
	if not res then
		return {success=false, info="查询数据出错！"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};

		record.id 	  			= res[i]["id"];
		record.software_name   	= res[i]["software_name"];
		record.parent_id   		= res[i]["parent_id"];
		record.b_use   			= res[i]["b_use"];
		record.pic_url 			= res[i]["pic_url"];
		record.software_url   	= res[i]["software_url"];
		record.create_time 		= res[i]["create_time"];
		record.software_content = res[i]["software_content"];
		record.px 				= res[i]["px"];
		record.software_explain = res[i]["software_explain"];

		table.insert(resultListObj, record);
	end
	
	local resultJsonObj		= {};
	resultJsonObj.success   = true;
	resultJsonObj.totalRow   = tonumber(totalRow);
	resultJsonObj.totalPage  = totalPage;
	resultJsonObj.pageNumber = tonumber(pageNumber);
	resultJsonObj.pageSize 	 = tonumber(pageSize);
	resultJsonObj.rows 		 = resultListObj;
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	return true,resultJsonObj;
end

_CatalogModel.queryCatalog = queryCatalog;

---------------------------------------------------------------------------

--[[
	局部函数：前台查询所有分类
	作者：刘全锋 2015-10-09
	参数：parent_id	--0查询所有软件大分类 非0根据parent_id查询软件
]]


local function queryCatalogAll()

	local db = DBUtil: getDb();

	local conditionSegement = " from t_software_catalog where parent_id=0 and b_use=1 order by px desc,id desc";
	local sql = "select id,software_name,parent_id,b_use ,pic_url,software_url,create_time,px,software_content,software_explain";
	local res, err, errno, sqlstate = db:query(sql..conditionSegement);
	if not res then
		return false;
	end

	local resultListObj = {};
	for i=1, #res do
		local record = {};
		record.id 	  			= res[i]["id"];
		record.software_name   	= res[i]["software_name"];
		record.parent_id   		= res[i]["parent_id"];
		record.b_use   			= res[i]["b_use"];
		record.pic_url 			= res[i]["pic_url"];
		record.software_url   	= res[i]["software_url"];
		record.create_time 		= res[i]["create_time"];
		record.software_content = res[i]["software_content"];
		record.px 				= res[i]["px"];
		record.software_explain = res[i]["software_explain"];
		local conditionSegementChild = " from t_software_catalog where parent_id="..res[i]["id"].." and b_use=1 order by px desc,id desc";

		local resChild, err, errno, sqlstate = db:query(sql..conditionSegementChild);

		if not resChild then
			return false;
		end

		local resultListObjChild = {};
		for i=1, #resChild do
			local recordChild = {};
			recordChild.id 	  				= resChild[i]["id"];
			recordChild.software_name   	= resChild[i]["software_name"];
			recordChild.parent_id   		= resChild[i]["parent_id"];
			recordChild.b_use   			= resChild[i]["b_use"];
			recordChild.pic_url 			= resChild[i]["pic_url"];
			recordChild.software_url   		= resChild[i]["software_url"];
			recordChild.create_time 		= resChild[i]["create_time"];
			recordChild.software_content	= resChild[i]["software_content"];
			recordChild.px 					= resChild[i]["px"];
			recordChild.software_explain 	= resChild[i]["software_explain"];
			table.insert(resultListObjChild, recordChild);
		end
		record.childList = resultListObjChild;
		table.insert(resultListObj, record);
	end

	local resultJsonObj		= {};
	resultJsonObj.success   = true;
	resultJsonObj.rows 		 = resultListObj;

	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);

	return true,resultJsonObj;
end

_CatalogModel.queryCatalogAll = queryCatalogAll;

---------------------------------------------------------------------------


--[[
	局部函数：	创建软件列表
	作者：		刘全锋 2015-10-06
	参数：		paramTable -- 存储参数的table对象
	返回值：		boolean true操作成功，false操作失败
]]

local function saveCatalog(paramTable)

	local software_name		= paramTable["software_name"];
	local parent_id			= tonumber(paramTable["parent_id"]);
	local b_use				= tonumber(paramTable["b_use"]);
	local pic_url			= paramTable["pic_url"];
	local software_url		= paramTable["software_url"];
	local create_time		= paramTable["create_time"];
	local software_content	= paramTable["software_content"];
	local px				= tonumber(paramTable["px"]);
	local software_explain	= paramTable["software_explain"];

	local insertCatalogSql = "insert into t_software_catalog (software_name,parent_id,b_use,pic_url,software_url,create_time,software_content,px,software_explain) VALUES (" .. quote(software_name) .. ", " .. parent_id .. ", " .. b_use .. ", " .. quote(pic_url) .. ", " .. quote(software_url) .. ", " .. quote(create_time) ..","..quote(software_content)..","..px..","..quote(software_explain)..")";

	local result = DBUtil: querySingleSql(insertCatalogSql);

	if not result then
		return false, "cxg_log  执行sql语句报错， sql语句：[", insertCatalogSql, "]";
	end

	return result;
end

_CatalogModel.saveCatalog = saveCatalog;

---------------------------------------------------------------------------

--[[
	局部函数：	修改软件列表
	作者：		刘全锋 2015-10-06
	参数：		paramTable -- 存储参数的table对象
	返回值：	 	boolean true操作成功，false操作失败
]]

local function updateCatalog(paramTable)

	local catalogId = paramTable["catalogId"];
	if catalogId == nil or catalogId == ngx.null then
		return false, "catalogId不能为空";
	end

	local software_name		= paramTable["software_name"];
	local parent_id			= tonumber(paramTable["parent_id"]);
	local b_use				= tonumber(paramTable["b_use"]);
	local pic_url			= paramTable["pic_url"];
	local software_url		= paramTable["software_url"];
	local software_content	= paramTable["software_content"];
	local px				= paramTable["px"];
	local software_explain	= paramTable["software_explain"];


	local updateSql = "update t_software_catalog set software_name="..quote(software_name)..",parent_id="..parent_id..",b_use="..b_use..",pic_url="..quote(pic_url)..",software_url="..quote(software_url)..",software_content="..quote(software_content)..",px="..px..",software_explain="..quote(software_explain)

	updateSql = updateSql .. " where id = " .. catalogId;

	local result = DBUtil: querySingleSql(updateSql);
	if not result then
		return false;
	else
		return true;
	end
end

_CatalogModel.updateCatalog = updateCatalog;

---------------------------------------------------------------------------

--[[
	局部函数：	根据ID软件列表
	作者：		刘全锋 2015-10-06
	参数：		id -- 软件列表ID
	返回值： 	根据ID查询的数据，空返回false
]]

local function queryCatalogById(catalogId)

	local db = DBUtil: getDb();
	local sql = "select software_name,parent_id,b_use,pic_url,software_url,px,software_content,software_explain from t_software_catalog where id = "..tonumber(catalogId).." limit 1";
	
	local queryResult = db:query(sql);
	
	if not queryResult or #queryResult == 0 then
        return false;
    end
	
	local record = {};
    record.software_name 	= queryResult[1]["software_name"];
    record.parent_id     	= queryResult[1]["parent_id"];
    record.b_use 		 	= queryResult[1]["b_use"];
	record.pic_url  		= queryResult[1]["pic_url"];
	record.software_url  	= queryResult[1]["software_url"];
	record.software_content	= queryResult[1]["software_content"];
	record.px				= queryResult[1]["px"];
	record.software_explain	= queryResult[1]["software_explain"];

	record.success = true;
	
    return record;
end

_CatalogModel.queryCatalogById = queryCatalogById;
---------------------------------------------------------------------------

--[[
	局部函数：	删除软件列表
	作者：		刘全锋 2015-10-06
	参数：		paramTable -- 存储参数的table对象
	返回值：	 	boolean true操作成功，false操作失败
]]

local function deleteCatalog(catalogId)

	if catalogId == nil or catalogId == ngx.null then
		return false, "catalogId不能为空";
	end


	local deleteSql = "delete from  t_software_catalog where id = " .. catalogId;

	local result = DBUtil: querySingleSql(deleteSql);
	if not result then
		return false;
	end

	local deleteParentSql = "delete from  t_software_catalog where parent_id = " .. catalogId;

	local resultParent = DBUtil: querySingleSql(deleteParentSql);

	if not resultParent then
		return false;
	else
		return true;
	end

end

_CatalogModel.deleteCatalog = deleteCatalog;

---------------------------------------------------------------------------


return _CatalogModel





