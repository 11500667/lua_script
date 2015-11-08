#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#曹洪念 2015-08-15
#描述：上传课件的对学生可见信息 
#参数：资源id 创建人create_person 资源类型 bk_type 是否对学生可见 is_stusee 可见的班级 class_id 课件的年级 grade_id (云版未添加此变量)  打开的班级（试卷类型） class_open
]]

--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--2.获取参数
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"]

--获得创建人 create_person
if args["create_person"] == nil or args["create_person"] == "" then
    ngx.say("{\"success\":false,\"info\":\"create_person参数错误！\"}")
    return
end
local create_person = args["create_person"]

--获得资源类型
if args["bk_type"] == nil or args["bk_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bk_type参数错误！\"}")
    return
end
local bk_type = args["bk_type"]

--获得是否对学生可见
if args["is_stusee"] == nil or args["is_stusee"] == "" then
    ngx.say("{\"success\":false,\"info\":\"is_stusee参数错误！\"}")
    return
end
local is_stusee = args["is_stusee"]

-- 如果没有勾选对学生可见  则不进行一下处理 
if (is_stusee == "1") then

--获得可见的班级
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end
local class_id = tostring(args["class_id"])

local class_ids_list = Split(class_id,",");
local res_str = ""
for i=1,#class_ids_list do
	res_str = res_str.."'"..class_ids_list[i].."',"
end
if res_str ~= "" then
	res_str = string.sub(res_str,0,#res_str-1)
end

--获得可见的年级
--if args["grade_id"] == nil or args["grade_id"] == "" then
 --   ngx.say("{\"success\":false,\"info\":\"grade_id参数错误！\"}")
  --  return
--end
--local grade_id = tostring(args["grade_id"])

--local grade_ids_list = Split(grade_id,",");
--local res_strgrade = ""
--for i=1,#grade_ids_list do
--	res_strgrade = res_str.."'"..grade_ids_list[i].."',"
--end
--if res_strgrade ~= "" then
--	res_strgrade = string.sub(res_strgrade,0,#res_strgrade-1)
--end

--获得打开的班级 只有在上传的是试卷的时候 才有打开班级
if (bk_type == "107")
then
if args["class_open"] == nil or args["class_open"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_open参数错误！\"}")
    return
end
local class_open = tostring(args["class_open"])

local class_opens_list = Split(class_open,",");
local res_stropen = ""
for i=1,#class_opens_list do
	res_stropen = res_stropen.."'"..class_opens_list[i].."',"
end
if res_stropen ~= "" then
	res_stropen = string.sub(res_stropen,0,#res_stropen-1)
end
end

--3.连接数据库
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
		ngx.print("{\"success\":false,\"info\":\"连接数据库失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end
	
--4.数据处理
-- 插入T_RESOURCE_RECORD表
local sql = "INSERT INTO T_RESOURCE_RECORD (RESOURCE_ID,CLASS_ID,IS_STUSEE) VALUES('"..resource_id.."','"..class_id.."','"..is_stusee.."'"..")"

local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"插入数据出错！\"}");
    return;
end

--更新派发作业时间
local sql2 = "SELECT RESOURCE_ID FROM T_RESOURCE_SENDSTUDENT WHERE RESOURCE_ID = "..resource_id

local resourceids, err, errno, sqlstate = db:query(sql2);
if not resourceids
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"resourceids查询数据出错！\"}");
    return;
end

if #resourceids ~= 0
then
local sql3 = "DELETE FROM T_RESOURCE_SENDSTUDENT WHERE RESOURCE_ID = "..resource_id

local del, err, errno, sqlstate = db:query(sql3);
if not del
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"del删除数据出错！\"}");
    return;
end
end

local create_time = os.date("%Y-%m-%d %H:%M:%S")

local sql4 = "SELECT STUDENT_ID AS PERSONID,CLASS_ID AS CLASSID FROM  t_base_student WHERE B_USE=1 AND  CLASS_ID IN ("..res_str..")"
local list2, err, errno, sqlstate = db:query(sql4);

if not list2
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list2查询数据出错！\"}");
    return;
end

for i = 1,#list2 do
local uuid =  require "resty.uuid";
local resource_id_char = uuid.new();

local sql5 = "INSERT INTO T_RESOURCE_SENDSTUDENT (ID,RESOURCE_ID,STUDENT_ID,CLASS_ID,SNED_PERSON,CATEGORY_ID,STATE_ID,TIME_I) VALUES('"..resource_id_char.."','"..resource_id.."','"..list2[i]["PERSONID"].."','"..list2[i]["CLASSID"].."','"..create_person.."','"..bk_type.."','1','"..create_time.."');"

local list3, err, errno, sqlstate = db:query(sql5);
if not list3
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list3插入数据出错！\"}");
    return;
end
end
--ngx.say("########","list3插入数据成功")

--表示是试卷
if bk_type== "107"
then
local sql6 = "DELETE FROM T_BAG_SJSTATE WHERE RESOURCE_ID="..resource_id.." AND CLASS_ID  IN ("..res_str..")"

local del2,err, errno, sqlstate = db:query(sql6);
if not del2
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"del2删除数据出错！\"}");
	return;
end

--为什么需要再重新获取一遍  直接用上面获取的参数未nil 
local class_open1 = tostring(args["class_open"])
local class_opens_list1 = Split(class_open1,",");

for k=1,#class_opens_list1 do
local tmpClass = string.sub(tostring(class_opens_list1[k]),1,-3)
local tmpOpen = string.sub(tostring(class_opens_list1[k]),-1,-1)
--ngx.say("###########Class:",tostring(tmpClass))
--ngx.say("###########Open:",tostring(tmpOpen))

local sql7="INSERT INTO T_BAG_SJSTATE (RESOURCE_ID,CLASS_ID,STATE_ID) VALUES ('"..resource_id.."','"..tmpClass.."','"..tmpOpen.."');"

local list4, err, errno, sqlstate = db:query(sql7);
if not list4
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"list4插入数据出错！\"}");
    return;
end
end
end
	
local result = {} 
result["success"] = true
result["info"] = "插入数据成功"	
	
-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 6.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = cjson.encode(result);

-- 7.输出json串到页面
ngx.say(resultJson);
-- 表示选择了对学生可见 才走以上代码处理
else

local result = {} 
result["success"] = true
result["info"] = "未设置对学生可见"	

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resultJson = cjson.encode(result);

-- 输出json串到页面
ngx.say(resultJson);
end



