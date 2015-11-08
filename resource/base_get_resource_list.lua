#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_background_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_background_identity_id)
local cookie_token = tostring(ngx.var.cookie_background_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id的cookie信息参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id的cookie信息参数错误！\"}")
    return
end

--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":false,\"info\":\"token的cookie信息参数错误！\"}")
    return
end



--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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

local resdis_token = cache:hget("person_" .. cookie_person_id .. "_"  .. cookie_identity_id, "token")
if resdis_token ~= cookie_token then 
	ngx.say("{\"success\":false,\"info\":\"错误的验证信息！\"}")
    return
end 

--nid节点id
local nid = tostring(args["nid"])
--判断是否有资源类型参数
if nid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"节点参数错误！\"}")    
    return
end


--版本scheme_id
local scheme_id = tostring(args["scheme_id"])
--判断是否有资源类型参数
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"版本参数错误！\"}")    
    return
end

--搜索关键字
local keyword = tostring(args["keyword"])
--显示什么 0：全部 1：理想 2：本区 3：本校 4：教研室
local view = tostring(ngx.var.arg_view)

--判断是否有显示类型参数
if view == "nil" then
    ngx.say("{\"success\":false,\"info\":\"view参数错误！\"}")    
    return
end

--第几页
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")    
    return
end
--是否是根节点
local is_root = tostring(ngx.var.arg_is_root)
--判断是否有是否是根节点的参数
if is_root == "nil" then
    ngx.say("{\"success\":false,\"info\":\"is_root参数错误！\"}")
    return
end
--是否包含子节点
local cnode = tostring(ngx.var.arg_cnode)
if cnode == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cnode参数错误！\"}")
    return
end

--资源类型
local rtype = tostring(args["rtype"])
if rtype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"rtype参数错误！\"}")
    return
end

--应用类型
local app_type_id = tostring(args["app_type_id"])
if app_type_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"应用类型参数错误！\"}")
    return
end

--按谁排序 1：上传时间  2：文件大小 3：下载次数
local sort_num = tostring(args["sort_num"])
if sort_num == "nil" then
    ngx.say("{\"success\":false,\"info\":\"sort_num参数错误！\"}")
    return
end

--升序还是降序
local sort_type = tostring(args["sort_type"])
if sort_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"sort_type参数错误！\"}")
    return
end

--关键字
if keyword=="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword~=0 then
        keyword = ngx.decode_base64(keyword)..";"
    else
    	keyword = ""
    end
end

--后台没有群组，拼接条件只需要有person_id 为1.32. 34 的即可
local str_person = "filter=person_id,1,32,34;";

local str_rtype = ""
if rtype ~= "0" then 
	str_rtype = " filter=resource_type," .. rtype .. ";";
end  

if app_type_id ~= "0" then 
	app_type_id = " filter=app_type_id," .. app_type_id .. ";";
else 
	app_type_id = "";
end  

local structure_scheme = ""
if is_root == "1" then
	structure_scheme = "filter=scheme_id_int,"..scheme_id..";"
else
    if cnode == "0" then
        structure_scheme = "filter=structure_id,"..nid..";"
    else
       -- ngx.log(ngx.ERR,"----".."node_"..nid)
        local sid = cache:get("node_"..nid)
      --   local sids = Split(sid,",")
       -- for i=1,#sids do
         --   structure_scheme = structure_scheme..sids[i]..","
        -- end
      structure_scheme = "filter=structure_id,"..sid..";"
    end
end 

--升序降序的条件
local asc_desc = ""
if sort_num =="1" then
   asc_desc = "asc"
else
   asc_desc = "desc"
end
local sort_field = ""
if sort_type == "1" then --时间
	sort_field = "groupsort=ts "..asc_desc..";"
elseif sort_type == "2" then -- 大小
	sort_field = "groupsort=resource_size_int " .. asc_desc ..";"
elseif sort_type == "3"	then --下载次数
	sort_field = "groupsort=down_count " .. asc_desc ..";"
elseif sort_type == "4"	then --类型
	sort_field = "groupsort=resource_type " .. asc_desc ..";"
elseif sort_type == "5"	then --格式
	sort_field = "groupsort=resource_format " .. asc_desc ..";"
else --页数
	sort_field = "groupsort=resource_page " .. asc_desc ..";"
end

--UFT_CODE
local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        --str = string.gsub (str, " ", " ")
    end
    return str
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

ngx.log(ngx.ERR,"SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query =\';" .. keyword .. app_type_id ..	structure_scheme .. str_rtype ..str_person.."filter=RELEASE_STATUS,1,2;filter = res_type,1;sort=attr_desc:ts;maxmatches="..(offset+limit)..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX STATUS;--------------")

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query =\';" .. keyword .. app_type_id ..	structure_scheme .. str_rtype ..str_person.."filter=RELEASE_STATUS,1,2,3;filter = res_type,1;sort=attr_desc:ts;maxmatches="..(offset+limit)..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX STATUS;")
--ngx.log(ngx.ERR,res[1]["id"].."@@@@@@@@@@@@@@@@@@@@")


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
--local myPrime = require "resty.PRIME";


local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)

--[[
local resource_list = ""
for i=1,#res do
	local str = "{\"iid\":\"" .. res[i]["id"]..                	 "\",\"resource_id_int\":\"##\",\"resource_id_char\":\"##\",\"resource_title\":\"##\"," ..
			    		"\"resource_type_name\":\"##\",\"resource_format\":\"##\"," ..
			    		"\"resource_page\":\"##\",\"resource_size\":\"##\"," ..
			    		"\"create_time\":\"##\",\"down_count\":\"##\"," ..
			    		"\"file_id\":\"##\",\"thumb_id\":\"##\"," ..
			    		"\"preview_status\":\"##\",\"url_code\":\"##\"," ..
			    		"\"structure_id\":\"##\",\"scheme_id_int\":\"##\"," ..
			    		"\"person_name\":\"##\",\"width\":\"##\"," ..
			    		"\"height\":\"##\"," ..					
			    		"\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\"," ..
			    		"\"release_status\":\"##\","..
						"\"app_type_name\":\"@@\"}" 				
    local resource_info = cache:hmget("resource_" .. res[i]["id"], "resource_id_int","resource_id_char","resource_title","resource_type_name","resource_format",	 "resource_page","resource_size","create_time","down_count",
			    		"file_id","thumb_id","preview_status",
			    		"resource_title","structure_id","scheme_id_int",
			    		"person_name","width","height",
			    		"for_urlencoder_url","for_iso_url","release_status","app_type_id")
		
	for j=1,#resource_info do
		local app_type_id = resource_info[22]
		local app_typeids =myPrime.dec_prime(app_type_id);
		local app_type_name_tab = {};
		local app_type_name = "";
			  app_type_name_tab = Split(app_typeids,",");
		for i=1,#app_type_name_tab do
		   local apptypename = cache:hmget("t_base_apptype_"..scheme_id.."_"..app_type_name_tab[i],"app_type_name")
		   app_type_name = app_type_name..","..tostring(apptypename[1]);
		end

		app_type_name = string.sub(app_type_name,2,#app_type_name);
    	            str = string.gsub(str,"##",resource_info[j],1)
		str = string.gsub(str,"@@",app_type_name,1)

	end
    resource_list = resource_list..str..","
end
resource_list = string.sub(resource_list,0,#resource_list-1)

]]

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

local result = {} 
result["list"] = resourceJson
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))



--ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..resource_list.."]}")
