-- -----------------------------------------------------------------------------------
-- 描述：审核流程的Controller类
-- 日期：2015年8月21日
-- 作者：申健
-- -----------------------------------------------------------------------------------
local _CheckFlowController = {}

local DBUtil    = require "common.DBUtil";
local checkFlowModel = require "multi_check.model.CheckFlow";
local CheckPersonMoldel = require "multi_check.model.CheckPerson";

-- -----------------------------------------------------------------------------------
-- 函数描述： 公用接口 -> 生成mysql事务处理的对象
-- 日    期： 2015年8月17日
-- 参    数： 无
-- 返 回 值： 返回数据事务的table对象
-- -----------------------------------------------------------------------------------
function _CheckFlowController: getLastCheckFlow()

    local objType   = self: getParamToNumber("obj_type", true);
    local objIdInt  = self: getParamToNumber("obj_id_int");
    local objIdChar = self: getParamByName("obj_id_char");

    if objType == 2 and (objIdChar == nil or objIdChar == "") then
        ngx.print("{\"success\":false,\"info\":\"参数obj_id_char不能为空\"}");
        return;
    elseif objType ~= 2 and objIdInt == nil then
        ngx.print("{\"success\":false,\"info\":\"参数obj_id_int不能为空\"}");
        return;
    end

    local sql = "";

    if objType == 2 then
        sql = "SELECT ID FROM T_BASE_CHECK_INFO WHERE OBJ_ID_CHAR=" .. ngx.quote_sql_str(objIdChar) .. " AND OBJ_TYPE=" .. objType .. " ORDER BY ID DESC LIMIT 1";
    else
        sql = "SELECT ID FROM T_BASE_CHECK_INFO WHERE OBJ_ID_INT=" .. objIdInt .. " AND OBJ_TYPE=" .. objType .. " ORDER BY ID DESC LIMIT 1";
    end

    ngx.log(ngx.ERR, "[sj_log] -> [checkFlow] -> sql: [", sql, "]");
    local resultJson      = {};
    local checkInfoResult = DBUtil: querySingleSql(sql);
    if not checkInfoResult or #checkInfoResult == 0 then
        -- ngx.print("{\"success\":false,\"info\":\"审核记录不存在！\"}");
        
        resultJson.success    = true;
        resultJson.last_check_flow = { person_name = "无"};
    else
        local checkId     = checkInfoResult[1]["ID"];
        local resultTable = checkFlowModel: getByCheckId(checkId);
        local objTypeName = {"资源", "试题", "试卷", "备课", "微课"};

        if not resultTable or #resultTable == 0 then
            resultJson.success    = true;
            resultJson.last_check_flow = { person_name = "无"};
        else
            local lastFlowRecord = resultTable[1];
            -- 如果是自动通过产生的记录，则人员姓名显示例如：【省级自动通过】
            if tonumber(lastFlowRecord["person_id"]) == 0 then
                local unitType = CheckPersonMoldel:getUnitType(tonumber(lastFlowRecord["unit_id"]));
                local unitTypeName = {"省级", "市级", "区级", "校级", "校级"};
                lastFlowRecord["person_name"] = unitTypeName[tonumber(unitType)] .. "自动通过审核";
            end
            resultJson.success    = true;
            resultJson.last_check_flow = lastFlowRecord;
        end
    end

    ngx.print(encodeJson(resultJson));

end

BaseController: initController(_CheckFlowController);