
-- -----------------------------------------------------------------------------------
-- 描述：试卷后台管理 -> 试卷删除
-- 作者：刘全锋
-- 日期：2015年12月14日
-- -----------------------------------------------------------------------------------



local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local DBUtil   = require "common.DBUtil";
local cjson = require "cjson"
local CacheUtil = require "common.CacheUtil";
local SSDBUtil = require "common.SSDBUtil";

local cache = CacheUtil: getRedisConn();
local ssdb = SSDBUtil:getDb();
local db = DBUtil: getDb();
local p_myTs      = require "resty.TS"


local paper_id_int = tostring(args["paper_id_int"])
if paper_id_int == "nil" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end


local update_ts =  p_myTs.getTs();
local sql_up = "UPDATE t_sjk_paper_info SET B_DELETE=1, UPDATE_TS="..update_ts.." WHERE ID="..tonumber(paper_id_int);
db:query(sql_up);
local paper_info = {};
paper_info.b_delete = 1;
--修改缓存
cache:hmset("paper_"..paper_id_int,paper_info);


-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
local paramObj  = {};
paramObj["paper_id_int"] = paper_id_int;
local asyncQueueService = require "common.AsyncDataQueue.AsyncQueueService";
local asyncCmdStr       = asyncQueueService: getAsyncCmd("002003", paramObj)
ngx.log(ngx.ERR, "[sj_log] -> [supervise] -> asyncCmdStr: [", asyncCmdStr, "]");
asyncQueueService: sendAsyncCmd(asyncCmdStr);
-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
					

local responseObj = {};
responseObj.success = true;
responseObj.info = "操作成功";
local responseJson = cjson.encode(responseObj);

DBUtil: keepDbAlive(db);
CacheUtil:keepConnAlive(cache);
SSDBUtil:keepAlive(ssdb);

ngx.say(responseJson);


