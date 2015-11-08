#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-02-05
#描述：设置资源的共享范围和发布班级
#修改 去掉是否共享的设置 只修改共享发布的班级 曹洪念 2015.8.25
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--2.获得参数方法
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"]

--获得人员id
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

--获得base64的发布班级，共享范围
if args["share_info"] == nil or args["share_info"] == "" then
    ngx.say("{\"success\":false,\"info\":\"share_info参数错误！\"}")
    return
end

local cjson = require "cjson"
local data = cjson.decode(args["share_info"])

--获得删除的班级
local del_class_id = data.del_class;
ngx.log(ngx.ERR,"del_class_id===="..del_class_id)
--获得增加的班级
local add_class = data.add_class;
--要修改的班级
local update_class= data.update_class;
local uuid =  require "resty.uuid";

local create_time = ngx.localtime();

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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

if  #del_class_id >0 then

if bk_type == "107" then
--删除发布的班级
    local del_class = "DELETE from t_bag_sjstate WHERE resource_id = '"..resource_id.."' AND class_id in ("..del_class_id..")";
    local del_class_results, err, errno, sqlstate = db:query(del_class);
    if not del_class_results then
       ngx.log(ngx.ERR, "删除发布班级出错bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	   ngx.say("{\"success\":\"false\",\"info\":\"删除发布班级出错！\"}");
       return
    end
 end
 end
 
--删除发布学生
if  #del_class_id >0 then
local del_class_student = "DELETE from t_resource_sendstudent  WHERE resource_id = '"..resource_id.."' AND class_id in ("..del_class_id..")";
local del_class_student_results, err, errno, sqlstate = db:query(del_class_student);

if not del_class_student_results then
    ngx.log(ngx.ERR, "删除发布学生出错bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"删除发布学生出错！\"}");
    return
end
end

if #add_class>0 then
local add_tab = Split(add_class,",");

for i=1,#add_tab do 
     local class_info = add_tab[i];
	 local classid = Split(class_info,":");
	 local id = classid[1];
	 
	 if bk_type == "107" then
    	 local state_id = classid[2];
	     local in_class = " insert into t_bag_sjstate(resource_id,class_id,state_id,exam_time,is_exam) values('"..resource_id.."','"..id.."','"..state_id.."','"..create_time.."',0)";
         ngx.log(ngx.ERR,"##################"..in_class)
		 
		local in_class_results, err, errno, sqlstate = db:query(in_class);
         if not in_class_results then
            ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	        ngx.say("{\"success\":\"false\",\"info\":\"如果是测试，需要表示试卷状态\"}");
            return
         end
	 end
	 
	 --根据班级获得学生
        local student_info;
	    local student = ngx.location.capture("/dsideal_yy/base/getStudentByClassId",
	    {
        	args={class_id=id}
    	})

	   if student.status == 200 then
        	student_info= cjson.decode(student.body)
	   else
        	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
        	return
	   end

	   local sql_in_dtudent_value = "";
	   for i=1,#student_info.list do
        local student_id = student_info.list[i].student_id;
		
		local resource_id_char = uuid.new();
		local temp_sql = "('"..resource_id_char.."','"..resource_id.."',"..student_id..","..id..","..create_person..","..bk_type..",1,'"..create_time.."')";       
		
		sql_in_dtudent_value = sql_in_dtudent_value..","..temp_sql;
	
	   end 
	   if #sql_in_dtudent_value>1 then
	     local in_student = "insert into t_resource_sendstudent(id,resource_id,student_id,class_id,sned_person,category_id,state_id,time_i)values ";
	     sql_in_dtudent_value = string.sub(sql_in_dtudent_value,2,#sql_in_dtudent_value)
		
		  ngx.log(ngx.ERR,"===========###########################===="..sql_in_dtudent_value)
	   	local in_student_results, err, errno, sqlstate = db:query(in_student..sql_in_dtudent_value);
		
          if not in_student_results then
            ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	        ngx.say("{\"success\":\"false\",\"info\":\"添加发布到班级！\"}");
          return
         end
		 
		 end
end
end

if #update_class>0 then
    if bk_type == "107" then
      local update_tab = Split(update_class,",");
	  
	  for i=1,#update_tab do
	     local class_info = update_tab[i];
	     local classid = Split(class_info,":");
		 local id = classid[1];
		 local state_id = classid[2];
		 local update_state = "update t_bag_sjstate set state_id = "..state_id.." where class_id = "..id.." and resource_id ='"..resource_id.."'";
		 db:query(update_state);
	  end
	end
end

local responseObj = {};
responseObj.success = true;
responseObj.info = "更改共享范围成功";

-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
