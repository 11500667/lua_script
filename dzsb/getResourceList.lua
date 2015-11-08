#ngx.header.content_type = "text/plain;charset=utf-8"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--结点ID
local structure_id = tostring(args["structure_id"])
--判断是否有结点ID参数
if structure_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"structure_id丢失\"}")
    return
end

--根据结构id获得对应的scheme_id_int和is_root

local structure_info = cache:hmget("t_resource_structure_"..structure_id,"is_root","scheme_id_int");

local is_root = structure_info[1];
local scheme_id = structure_info[2];

--第几页
local pageNumber = tostring(args["pageNumber"])
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"第几页参数丢失！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(args["pageSize"])
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"一页显示多少条参数丢失！\"}")    
    return
end

--UFT_CODE
local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
    end
    return str
end

local structure_scheme = ""
if is_root == "1" then
    structure_scheme = "filter=scheme_id_int,"..scheme_id..";"
else 
    local sid = cache:get("node_"..structure_id)
    local sids = Split(sid,",")
    for i=1,#sids do
       structure_scheme = structure_scheme..sids[i]..","
    end
    structure_scheme = "filter=STRUCTURE_ID,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
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

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100

--ngx.log(ngx.ERR,"SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query=\'"..structure_scheme.."filter=res_type,1;filter=group_id,1;filter=release_status,1,3;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");
local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query=\'"..structure_scheme.."filter=res_type,1;filter=group_id,1;filter=release_status,1,3;sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local responseObj = {};
local res_tab = {};
 responseObj.success = true;

 local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)
--[[
for i=1,#res do
     local tab = {};
	 --根据资源id去查找缓存
	--ngx.log(ngx.ERR,"=====================res[1][id]"..res[i]["id"])
	 local res_info = cache:hmget("resource_"..res[i]["id"],"resource_title","thumb_id","file_id","resource_format");
	tab.resource_title =  res_info[1];
	tab.thumb_id =  res_info[2];
	tab.file_id =  res_info[3];
	tab.extension =  res_info[4];
	res_tab[i]=tab
end
]]
responseObj.list= resourceJson;
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
--将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
ngx.say(responseJson);