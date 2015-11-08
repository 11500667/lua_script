#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获取redis中该用户的token
local redis_token,err = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"token")
if not redis_token then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--验证cookie中的token和redis中存的token是否相同
if redis_token ~= cookie_token then
    ngx.say("{\"success\":\"false\",\"info\":\"错误的验证信息！\"}")
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
local nid = tostring(args["nid"])
--判断是否有结点ID参数
if nid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--版本号
local scheme_id = tostring(args["scheme_id"])
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id丢失！\"}")
    return
end
--搜索关键字
local keyword = tostring(args["keyword"])
--显示什么 0：全部 1：理想 2：本区 3：本校 4：教研室
local view = tostring(args["view"])
--判断是否有显示类型参数
if view == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
--第几页
local pageNumber = tostring(args["pageNumber"])
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(args["pageSize"])
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
--是否是根节点
local is_root = tostring(args["is_root"])
--判断是否有是否是根节点的参数
if is_root == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--按谁排序  1：上传时间  2：文件大小  3：下载次数
local sort_type = tostring(args["sort_type"])
--判断是否有排序的参数
if sort_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_num"])
--判断是否有排序的参数
if sort_num == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end


if keyword =="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
	keyword = ""
    end
end
--拼组的条件
local str_group = ""
if view=="0" then
    str_group = "IF(person_id="..cookie_person_id..",1,0) "
    local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
    for i=1,#group_list do
        str_group = str_group.." OR IF(group_id="..group_list[i]..",1,0)"
    end
elseif view=="1" then
    --str_group = " IF(group_id=1,1,0)"
    str_group = " IF(person_id=1,1,0)"
elseif view=="2" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")..",1,0)"
elseif view=="3" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")..",1,0)"
elseif view=="4" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")..",1,0)"
elseif view=="5" then
    str_group = "IF(person_id="..cookie_person_id..",1,0) AND IF(group_id=2,1,0)"
elseif view=="6" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")..",1,0)"
elseif view=="7" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")..",1,0)"
elseif view=="-1" then
    str_group = " IF(group_id=1,1,0)"
else
    str_group = " IF(group_id="..view..",1,0)"
end


local res_type = tostring(args["res_type"])

--如果是资源库拼的就是资源类型的条件，如果是备课库拼的就是备课类型
local str_rtype = ""
if res_type == "1" then
    --资源类型
    local rtype = tostring(args["rtype"])
    --判断是否有资源类型参数
    if rtype == "nil" then
        ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
    end
    if rtype~="0" then
        str_rtype = " filter=resource_type,"..rtype..";"
    end
else
    
    local beike_type = tostring(args["beike_type"])
    --判断是否有备课类型参数
    if beike_type == "nil" then
        ngx.say("{\"success\":false,\"info\":\"beike_type参数错误！\"}")
        return
    end
    if beike_type~="0" then
        str_rtype="filter=bk_type,"..beike_type..";"
    end 
end

--Split方法
local function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
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
--是否包含子节点
local cnode = tostring(args["cnode"])

local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id_int,"..scheme_id..";"
    else
	structure_scheme = "filter=structure_id,"..nid..";"
    end
else
    if cnode == "0" then
        structure_scheme = "filter=structure_id,"..nid..";"
    else
        local sid = cache:get("node_"..nid)
        local sids = Split(sid,",")
        for i=1,#sids do
            structure_scheme = structure_scheme..sids[i]..","
        end
      structure_scheme = "filter=structure_id,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
    end
end

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    --asc_desc = "sort=attr_asc:"
    asc_desc = "asc"
else
    --asc_desc = "sort=attr_desc:"
    asc_desc = "desc"
end 

--排序
local sort_filed = ""
if sort_type=="1" then
    --sort_filed = asc_desc.."ts;"
    sort_filed = "groupsort=ts "..asc_desc..";"
elseif sort_type=="2" then
    --sort_filed = asc_desc.."resource_size_int;"
    sort_filed = "groupsort=resource_size_int "..asc_desc..";"
elseif sort_type=="3" then
    --sort_filed = asc_desc.."down_count;"
    sort_filed = "groupsort=down_count "..asc_desc..";"
elseif sort_type=="4" then
    --sort_filed = asc_desc.."resource_type;"
    if res_type=="1" then
        sort_filed = "groupsort=resource_type "..asc_desc..";"
    else
	sort_filed = "groupsort=bk_type "..asc_desc..";"
    end
elseif sort_type=="5" then
    --sort_filed = asc_desc.."resource_format;"
    sort_filed = "groupsort=resource_format "..asc_desc..";"
else
    --sort_filed = asc_desc.."resource_page;"
    sort_filed = "groupsort=resource_page "..asc_desc..";"
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

--local str_maxmatches = pageNumber*100
local str_maxmatches = "10000"
local res = ""


--if res_type=="1" then
   --res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=res_type,"..res_type..";"..str_rtype.."select=("..str_group..") as match_qq;filter= match_qq, 1;"..sort_filed.."groupby=attr:structure_id;groupby=attr:resource_id_int;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
    res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=res_type,"..res_type..";"..str_rtype.."select=("..str_group..") as match_qq;filter= match_qq, 1;filter=release_status,1,3;"..sort_filed.."groupby=attr:file_id;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
--[[
else
    local beike_type = tostring(args["beike_type"])
    local bk_type = "";
    if beike_type~="0" then
        bk_type="filter=bk_type,"..beike_type..";"
    end
    res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=res_type,"..res_type..";filter=person_id,"..cookie_person_id..";"..str_rtype..bk_type..sort_filed.."groupby=attr:structure_id;groupby=attr:resource_id_int;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
end
]]
--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local resource_info = ""
for i=1,#res do
    local cbanba = res[i]["id"]
    local str = "{\"iid\":\""..res[i]["id"].."\",\"resource_id_int\":\"##\",\"resource_title\":\"##\",\"resource_type_name\":\"##\",\"resource_format\":\"##\",\"resource_page\":\"##\",\"resource_size\":\"##\",\"create_time\":\"##\",\"down_count\":\"##\",\"file_id\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"structure_id\":\"##\",\"scheme_id_int\":\"##\",\"person_name\":\"##\",\"width\":\"##\",\"height\":\"##\",\"bk_type_name\":\"##\",\"beike_type\":\"##\",\"resource_size_int\":\"##\",\"resource_type\":\"##\",\"person_id\":\"##\",\"material_type\":\"##\",\"resource_id_char\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"url_code\":\"##\",\"parent_structure_name\":\"##\"}"
    local resource_value_null = cache:hmget("resource_"..res[i]["id"],"resource_id_int")
    if tostring(resource_value_null[1]) ~= "userdata: NULL" then
        local resource_value = cache:hmget("resource_"..res[i]["id"],"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","person_name","width","height","bk_type_name","beike_type","resource_size_int","resource_type","person_id","material_type","resource_id_char","for_urlencoder_url","for_iso_url")
        for j=1,#resource_value do
          --  if j > 23 then
		--str = string.gsub(str,"##",ngx.encode_base64(resource_value[j]),1)
		  --      str = string.gsub(str,"##",resource_value[j],1)
	      --  else
    	        str = string.gsub(str,"##",resource_value[j],1)
	      --  end
	end
    local structure_id = resource_value[12]
    local curr_path = ""

    local structures = cache:zrange("structure_code_"..structure_id,0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
       curr_path = curr_path..structure_info[1].."->"
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)



	local url_str = urlencode(resource_value[2])
        str = string.gsub(str,"##",url_str,1)
        str = string.gsub(str,"##",curr_path,1)


    resource_info = resource_info..str..","


    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

resource_info = string.sub(resource_info,0,#resource_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..resource_info.."]}")
