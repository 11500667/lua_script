#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil

if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--判断是否有试卷ID参数
if args["question_info_id"]==nil or args["question_info_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"question_info_id参数错误！\"}")
    return
end

if args["question_id_char"]==nil or args["question_id_char"]=="" then
    ngx.say("{\"success\":false,\"info\":\"question_id_char参数错误！\"}")
    return
end


--if args["version_id"]==nil or args["version_id"]=="" then
 --   ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
 --   return
--end



local question_ids      = tostring(args["question_info_id"])
local question_id_chars = tostring(args["question_id_char"])
local version_id = tostring(args["version_id"]);


-- 获取ts值
local t=ngx.now();
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
      n=n..string.rep("0",19-string.len(n))
local quesInfoIdArray = Split(question_ids,",")
local quesIdCharArray = Split(question_id_chars,",")

local DBUtil   = require "common.DBUtil";
local SSDBUtil = require "common.SSDBUtil";

local sql = "SELECT DISTINCT INFO.QUESTION_ID_CHAR, INFO.STRUCTURE_ID_INT, BASE.CONTENT_MD5 FROM T_TK_QUESTION_INFO INFO INNER JOIN T_TK_QUESTION_BASE BASE ON INFO.QUESTION_ID_CHAR=BASE.QUESTION_ID_CHAR WHERE INFO.QUESTION_ID_CHAR IN ('" .. string.gsub(question_id_chars, ",", "','") .. "') AND INFO.B_DELETE=0";

if version_id ~= nil and version_id ~= "" then
    sql = sql .. " and scheme_id_int = " .. tonumber(version_id);
end

local queryResult = DBUtil: querySingleSql(sql);
if    queryResult ~= nil and queryResult ~= ngx.null and #queryResult ~= 0 then
    for i, record in ipairs(queryResult) do
        
        local contentMd5 = record["CONTENT_MD5"];
        if (contentMd5 ~= nil and contentMd5 ~= ngx.null and contentMd5 ~= "") then
            local strucId    = record["STRUCTURE_ID_INT"];
            SSDBUtil: hdel("md5_ques_" .. contentMd5, "1_2_" .. strucId);
            SSDBUtil: hdel("md5_ques_" .. contentMd5, "1_2");
        end 
    end
end


for i = 1, #quesIdCharArray do
	local ts = n;
	local count =  DBUtil: querySingleSql("update t_tk_question_info set b_delete = 1,update_ts = "..ts.." where question_id_char = '"..quesIdCharArray[i].."' and scheme_id_int="..version_id);
	if count ~=nil then
        DBUtil: querySingleSql("update t_tk_question_my_info set b_delete = 1,update_ts = "..ts.." where question_id_char = '"..quesIdCharArray[i] .. "'  and scheme_id_int="..version_id);
	end
end	
ngx.say("{\"success\":true}")		
	