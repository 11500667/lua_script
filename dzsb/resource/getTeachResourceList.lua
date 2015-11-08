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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local pageSize = args["pageSize"]

-- 判断是否有pageSize参数
if pageSize == nil then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

local pageNumber = args["pageNumber"]
-- 判断是否有pageNumber参数
if pageNumber==nil  then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end

local person_id = args["person_id"]
-- 判断是否有person_id参数
if person_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

--根据人员id获得学校id

local school_id = cache:hget("person_"..person_id.."_5","xiao")
local is_root = args["is_root"]
-- 判断是否有is_root参数
if is_root == nil  then
    ngx.say("{\"success\":false,\"info\":\"is_root参数错误！\"}")
    return
end

local scheme_id = args["scheme_id"]
-- 判断是否有scheme_id参数
if scheme_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end

local structure_id = args["structure_id"]
-- 判断是否有structure_id参数
if structure_id == nil  then
    ngx.say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end

local cnode= args["cnode"];
-- 判断是否有type参数
if cnode == nil  then
    ngx.say("{\"success\":false,\"info\":\"cnode参数错误！\"}")
    return
end

local sql_scheme_structure = "";
local sql_keyword = "";
--拼接节点
if is_root== "1" then
   sql_scheme_structure = " and scheme_id ="..scheme_id;
else
   if cnode == "1" then
        local structure_ids = "";	
          --获得该节点的所有子节点
	    local sid = cache:get("node_"..structure_id)
        local sids = Split(sid,",")
        for i=1,#sids do
           structure_ids = structure_ids..sids[i]..","
        end 
        sql_scheme_structure = " and structure_id in ("..string.sub(structure_ids,0,#structure_ids-1)..")";
   else
        sql_scheme_structure = " and structure_id ="..structure_id;
   end
end

local keyword = args["keyword"];
-- 判断是否有keyword参数
if keyword == nil then
    ngx.say("{\"success\":false,\"info\":\"keyword参数错误！\"}")
    return
end

--拼接关键字		   
if #keyword ~= 0 then
	sql_keyword = " and resource_title like '%".. ngx.decode_base64(keyword).."%' ";
end

local resource_category= args["resource_category"];
-- 判断是否有type参数
if resource_category == nil  then
    ngx.say("{\"success\":false,\"info\":\"resource_category参数错误！\"}")
    return
end
	
local sql = "select resource_id,resource_title,resource_size,file_id,thumb_id,create_person,extension,down_count,update_logo from t_bag_resource_info where b_use =1 and resource_category = "..resource_category..sql_keyword..sql_scheme_structure.." and (is_share ="..school_id.." or create_person="..person_id..")";
sql = sql.." order by ts desc";

local sql_count = "select count(*) as count from t_bag_resource_info where b_use =1 and resource_category = "..resource_category..sql_keyword..sql_scheme_structure.." and (is_share ="..school_id.." or create_person="..person_id..")";

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--local str_maxmatches = pageNumber*pageSize
local sql_limit = " limit "..offset..","..limit;

ngx.log(ngx.ERR,"========"..sql..sql_limit.."==========");
local res = db:query(sql..sql_limit);
local res_count = db:query(sql_count);

local totalRow = res_count[1]["count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);

local responseObj = {};
local res_tab = {};
 responseObj.success = true;
 
 for i=1,#res do
    local tab = {};
	tab.resource_id = res[i]["resource_id"];
	tab.resource_title =  res[i]["resource_title"];
	tab.create_person =  res[i]["create_person"];
	local person_name = cache:hget("person_"..res[i]["create_person"].."_5","person_name")
	tab.person_name = person_name;
	tab.create_time =  res[i]["create_time"];
	tab.file_id =  res[i]["file_id"];
	tab.thumb_id =  res[i]["thumb_id"];
	tab.resource_size =  res[i]["resource_size"];
	tab.down_count =  res[i]["down_count"];
	tab.update_logo =  res[i]["update_logo"];
    res_tab[i]=tab
end
responseObj.list= res_tab;
responseObj.totalPage = totalPage;
responseObj.totalRow = totalRow;
responseObj.pageNumber =pageNumber;
responseObj.pageSize =pageSize;
-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)

ngx.say(responseJson)
