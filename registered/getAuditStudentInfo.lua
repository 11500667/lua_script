#ngx.header.content_type = "text/plain;charset=utf-8"

--根据学校ID获取该学校应审核的教师列表
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
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--学校id
if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id = args["school_id"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--审核标志
local sqlwhere = "";
if args["b_use"] == nil or args["b_use"] == "" then
    sqlwhere = " WHERE bureau_id  = '"..school_id.."'"
else
	local b_use = args["b_use"]
	sqlwhere = " WHERE bureau_id  = '"..school_id.."' AND b_use='"..b_use.."'"
end

--班级查询
if args["class_id"] == nil or args["class_id"] == "" then

else
	local class_id = args["class_id"]
	sqlwhere = sqlwhere.." AND class_id='"..class_id.."' "
end




local school_open_register, err, errno, sqlstate = db:query("SELECT open_register FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")
ngx.log(ngx.ERR,"SELECT open_register FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")
if not school_open_register then
  ngx.log(ngx.ERR,"{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
ngx.log(ngx.ERR,"SELECT open_register FROM t_base_organization WHERE org_id = \'"..school_id.."\';  ")



local res_count = db:query("SELECT count(1) as count FROM t_base_student "..sqlwhere..";")
ngx.log(ngx.ERR,"SELECT count(1) as count FROM t_base_student "..sqlwhere..";")
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local students, err, errno, sqlstate = db:query("SELECT student_id,student_name,xb_name,class_id,stu_tel,b_use FROM t_base_student "..sqlwhere.." order by student_id DESC LIMIT "..offset..","..limit..";")
ngx.log(ngx.ERR,"SELECT student_id,student_name,xb_name,class_id,stu_tel FROM t_base_student "..sqlwhere.." order by student_id DESC LIMIT "..offset..","..limit..";")
if not students then
  ngx.log(ngx.ERR,"{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  return
end


local personArray = {}
for i=1,#students do
  local ssdb_info = {};
  ssdb_info["student_id"] = students[i]["student_id"];
  ssdb_info["student_name"]= students[i]["student_name"];
  ssdb_info["xb_name"] = students[i]["xb_name"];
  ssdb_info["class_id"]= students[i]["class_id"];
  ssdb_info["stu_tel"] = students[i]["stu_tel"];
  ssdb_info["b_use"] = students[i]["b_use"];
  table.insert(personArray, ssdb_info);
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson["open_register"] = school_open_register[1]["open_register"]
returnjson["totalRow"] = totalRow
returnjson["totalPage"] = totalPage
returnjson["pageNumber"] = pageNumber
returnjson["pageSize"] = pageSize
returnjson.list = personArray
cjson.encode_empty_table_as_object(false)

db: set_keepalive(0, v_pool_size)

ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))
