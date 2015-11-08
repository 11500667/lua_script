#资源结构复制的保存功能 by huyue 2015-06-09
--1.获得参数方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local mysql_db, err = mysql : new();
if not mysql_db then
  ngx.log(ngx.ERR, err);
  return;
end

mysql_db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = mysql_db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }
 
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end



--获取参数开始
if args["actionId"] == nil or args["actionId"] == "" then
    ngx.say("{\"success\":false,\"info\":\"actionId参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数actionId不能为空！");
    return
end
local actionId = args["actionId"];

if args["actionType"] == nil or args["actionType"] == "" then
    ngx.say("{\"success\":false,\"info\":\"actionType参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数actionType不能为空！");
    return
end
local actionType = tonumber(args["actionType"]);

if args["resType"] == nil or args["resType"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resType参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数resType不能为空！");
    return
end
local resType = args["resType"];

if args["sourceScheme"] == nil or args["sourceScheme"] == "" then
    ngx.say("{\"success\":false,\"info\":\"sourceScheme参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数sourceScheme不能为空！");
    return
end
local sourceScheme = args["sourceScheme"];

if args["targetScheme"] == nil or args["targetScheme"] == "" then
    ngx.say("{\"success\":false,\"info\":\"targetScheme参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数targetScheme不能为空！");
    return
end
local targetScheme = args["targetScheme"];

if args["sourceStructureId"] == nil or args["sourceStructureId"] == "" then
    ngx.say("{\"success\":false,\"info\":\"sourceStructureId参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数sourceStructureId不能为空！");
    return
end
local sourceStructureId = args["sourceStructureId"];

if args["targetStructureId"] == nil or args["targetStructureId"] == "" then
    ngx.say("{\"success\":false,\"info\":\"targetStructureId参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数targetStructureId不能为空！");
    return
end
local targetStructureId = args["targetStructureId"];

local sourceResCount = args["sourceResCount"];

local sourceRes = args["sourceRes"];

if actionType==1 then
	sourceResCount = "-1" 
	sourceRes = "-1"
end

if args["createPerson"] == nil or args["createPerson"] == "" then
    ngx.say("{\"success\":false,\"info\":\"createPerson参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数createPerson不能为空！");
    return
end
local createPerson = args["createPerson"];

if args["personName"] == nil or args["personName"] == "" then
    ngx.say("{\"success\":false,\"info\":\"personName参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数personName不能为空！");
    return
end
local personName = args["personName"];

if args["userOrDsideal"] == nil or args["userOrDsideal"] == "" then
    ngx.say("{\"success\":false,\"info\":\"userOrDsideal参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数userOrDsideal不能为空！");
    return
end
local userOrDsideal = args["userOrDsideal"];

if args["mediaType"] == nil or args["mediaType"] == "" then
    ngx.say("{\"success\":false,\"info\":\"mediaType参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数mediaType不能为空！");
    return
end
local mediaType = args["mediaType"];

local myts = require "resty.TS";
local ts =  myts.getTs();

local actionStatus = 1;


--获取参数结束

--插入学科到数据库
local insert_sql="insert into t_resource_action (ActionId, ActionType, ResType, SourceScheme, TargetScheme, SourceStructureId, TargetStructureId, SourceRes, CreatePerson, PersonName, CreateTime, EndTime, ActionStatus, MediaType, UserOrDsideal,  ActionTs) values ("..actionId..","..actionType..", "..resType..","..sourceScheme..", "..targetScheme..",'"..sourceStructureId.."' ,"..targetStructureId..", '"..sourceRes.."',"..createPerson..", '"..personName.."',now(),now(),"..actionStatus..",'"..mediaType.."',"..userOrDsideal..","..ts..")"
 ngx.log(ngx.ERR,insert_sql)
 
local res,err,errno,sqlstate = mysql_db:query(insert_sql)

if not res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end
 
--放回连接池
mysql_db:set_keepalive(0,v_pool_size)


local result = {} 
result.success = true;
result.info = "资源结构复制成功！";

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

