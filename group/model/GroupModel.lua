---------------------------------------------------------------------------

local _GroupModel = {};

--[[
	�ֲ���������ѯȺ��
	���ߣ���ȫ�� 2015-08-05
	������groupId	--Ⱥ��
	������groupName	--Ⱥ��
	������creator	--������
	������userNo		--��Ա���
	������platTp		--ҵ��ϵͳ���� 0ϵͳ��1��ƽ̨��2������⡢3���С�4ѧϰģ�顢5��ʦʵѵ
	������platId		--ϵͳ��ʶ
	������useRg		--Ⱥ��ʹ�÷�Χ 1��ʦ��2ѧ����3���
	������groupTp	--ҵ��Ⱥ������ 1�����飬2��Ա��
	
]]


local function queryGroup(self, groupId, groupName, creator, userNo, platTp, platId, useRg, groupTp,pageNumber, pageSize)
	
	local DBUtil = require "common.DBUtil";
	local db = DBUtil: getDb();
	
	local sql = "select ID,GROUP_NAME,PLAT_TYPE ,PLAT_ID,GROUP_DESC,GROUP_NOTICE,B_USE,CREATE_TIME,GROUP_LEVEL,LEVEL_ORG_ID,B_REQUEST,AVATER_URL from t_base_group_new where 1=1 ";
	
	local whereSql = "";
	
	local queryCount = "select count(1) as count from t_base_group_new where 1=1 ";
	
	--Ⱥ��
	if groupId ~= nil and groupId ~= "" then	
		whereSql = whereSql .. " and ID="..tonumber(groupId);
	end

	--Ⱥ��
	if groupName ~= nil and groupName ~= "" then	
	   whereSql = whereSql .. " and GROUP_NAME like '%"..ngx.decode_base64(groupName).."%'";
	end

	--������
	if creator ~= nil and creator ~= "" then	
		whereSql = whereSql .. " and ID in (select b.GROUP_ID from t_sys_loginperson a,t_base_group_member_new b where a.PERSON_NAME='"..ngx.quote_sql_str(creator).."' and a.IDENTITY_ID=b.IDENTITY_ID and a.PERSON_ID=PERSON_ID)";
	end

	--��Ա���
	if (userNo ~= nil and userNo ~= "") and (args["userId"] ~= nil and args["userId"] ~= "") then
		whereSql = whereSql .. " and ID=(select GROUP_ID from t_base_group_member_new where PERSON_ID="..tonumber(keyWord).." and IDENTITY_ID="..tonumber(keyWord)..")";
	end

	--ҵ��ϵͳ���� 0ϵͳ��1��ƽ̨��2������⡢3���С�4ѧϰģ�顢5��ʦʵѵ
	if platTp ~= nil and platTp ~= "" then
		whereSql = whereSql .. " and USE_RANGE="..tonumber(platTp);
	end

	--ϵͳ��ʶ
	if platId ~= nil and platId ~= "" then
		whereSql = whereSql .. " and GROUP_TYPE="..tonumber(platId);
	end

	--Ⱥ��ʹ�÷�Χ 1��ʦ��2ѧ����3���
	if useRg ~= nil and useRg ~= "" then
		whereSql = whereSql .. " and USE_RANGE="..tonumber(useRg);
	end

	--ҵ��Ⱥ������ 1�����飬2��Ա��
	if groupTp ~= nil and groupTp ~= "" then	
		whereSql = whereSql .. " and GROUP_TYPE="..tonumber(groupTp);
	end
	
	local per_count = db:query(queryCount..whereSql);
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local sql_limit = " limit "..offset..","..limit;
	local totalRow = per_count[1]["count"];
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
	
	whereSql = whereSql..sql_limit;
	
	local res, err, errno, sqlstate = db:query(sql..whereSql);
	
	if not res then
		return {success=false, info="��ѯ���ݳ���"};
	end
	
	local resultListObj = {};
	for i=1, #res do
		local record = {};
				
		record.ID 	  		= res[i]["ID"];
		record.GROUP_NAME   	= res[i]["GROUP_NAME"];
		record.PLAT_TYPE   	= res[i]["PLAT_TYPE"];
		record.PLAT_ID 		= res[i]["PLAT_ID"];
		record.GROUP_DESC   	= res[i]["GROUP_DESC"];
		record.GROUP_NOTICE 	= res[i]["GROUP_NOTICE"];
		record.B_USE 		= res[i]["B_USE"];
		record.CREATE_TIME 	= res[i]["CREATE_TIME"];
		record.GROUP_LEVEL 		= res[i]["GROUP_LEVEL"];
		record.LEVEL_ORG_ID 		= res[i]["LEVEL_ORG_ID"];
		record.B_REQUEST 		= res[i]["B_REQUEST"];
		record.AVATER_URL 		= res[i]["AVATER_URL"];
		
		table.insert(resultListObj, record);
	end
	
	local resultJsonObj = {};
	resultJsonObj.success  = true;
	resultJsonObj.records  = totalRow;
	resultJsonObj.total 	= totalPage;
	resultJsonObj.page 		= pageNumber;
	resultJsonObj.rows 		= resultListObj;
	
	-- �����ݿ����ӷ������ӳ�
	DBUtil: keepDbAlive(db);
	
	return resultJsonObj;
end

_GroupModel.queryGroup = queryGroup;