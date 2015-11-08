
-- -----------------------------------------------------------------------------------
-- 描述：在t_stage_subject表中获取学段学科数据
-- 作者：刘全锋
-- 日期：2015年10月10日
-- -----------------------------------------------------------------------------------

local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
local request_method = ngx.var.request_method
local quote = ngx.quote_sql_str


local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local system_id  = args["system_id"];

-- 判断是否有system_id参数
if system_id==nil or system_id =="" then
    ngx.say("{\"success\":false,\"info\":\"system_id参数错误！\"}");
    return
end


local conditionSegement = " from t_stage_subject where system="..quote(system_id).." group by stage_id order by stage_id"

local sql = "select stage_id,stage_name,subject_id,subject_name ,system";

local res, err, errno, sqlstate = db:query(sql..conditionSegement);

if not res then
    ngx.say(encodeJson({success=false, info="查询数据出错！"}));
    return;
end


local resultObj = {};

local resultListStage = {};

for i=1, #res do
    local stageRecord = {};
    stageRecord.stage_id 	  	= res[i]["stage_id"];
    stageRecord.stage_name   	= res[i]["stage_name"];

    local conditionSegementChild = " from t_stage_subject where system="..quote(system_id).."  and stage_id="..res[i].stage_id.." order by subject_id";

    local resChild, err, errno, sqlstateChild = db:query(sql..conditionSegementChild);

    if not resChild then
        ngx.say(encodeJson({success=false, info="查询数据出错！"}));
    end

    local resultListSubject = {};

    for s=1, #resChild do
        local recordSubject = {};
        recordSubject.subject_id   	= resChild[s]["subject_id"];
        recordSubject.subject_name   	= resChild[s]["subject_name"];
        table.insert(resultListSubject, recordSubject);
    end
    stageRecord.subject_list=resultListSubject;
    table.insert(resultListStage, stageRecord);
end


resultObj.teach = resultListStage;

resultObj.success = true;

-- 将数据库连接返回连接池
DBUtil: keepDbAlive(db);

ngx.say("{\"success\":true,\""..system_id.."\":"..encodeJson(resultListStage).."}");
