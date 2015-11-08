local bureau_id = tostring(ngx.var.cookie_background_bureau_id)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--结点ID
local nid = tostring(ngx.var.arg_nid)
--判断是否有结点ID参数
if nid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"nid参数错误！\"}")
    return
end
--版本号
local scheme_id = tostring(ngx.var.arg_scheme_id)
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id丢失！\"}")
    return
end
--试卷类型
local ptype = "0"
--试卷类型
local paper_app_type = "0"

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
--判断是否有包含子节点的参数
if cnode == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cnode参数错误！\"}")
    return
end
--按谁排序  1：上传时间  2：文件大小  3：下载次数
local sort_type = "3"

--升序还是降序   1：ASC   2:DESC
local sort_num = "2"

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--搜索关键字
--local keyword = tostring(ngx.var.arg_keyword)
local keyword = tostring(args["keyword"])
if keyword=="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    keyword = ngx.decode_base64(keyword)..";"
end

--拼组的条件
local str_group = ""
if view=="1" then
    str_group = " IF(person_id=1,1,0)"
elseif view=="2" then
    str_group = " IF(group_id="..bureau_id..",1,0)"
elseif view=="-1" then
    str_group = " IF(group_id=1,1,0)"
else
    str_group = " IF(group_id="..view..",1,0)"
end

local str_ptype = ""
if ptype~="0" then
    str_ptype = " filter=paper_type,"..ptype..";"
end

local str_paper_app_type = ""
if paper_app_type ~="0" then
    str_paper_app_type = " filter=paper_app_type,"..paper_app_type ..";"
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

--是否包含子根点的逻辑
local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id,"..scheme_id..";"
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

--排序 1:题数  2:试卷类型  3:存档时间
local sort_filed = ""
if sort_type=="1" then
    sort_filed = "groupsort=question_count "..asc_desc..";"
elseif sort_type=="2" then
    sort_filed = "groupsort=paper_type "..asc_desc..";"
elseif sort_type=="4" then
     sort_filed = "groupsort=paper_app_type "..asc_desc..";"
else
    sort_filed = "groupsort=ts "..asc_desc..";"
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local str_maxmatches = pageNumber*pageSize

local res = db:query("SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ptype..str_paper_app_type.."filter=b_delete,0;select=("..str_group..") as match_qq;filter= match_qq, 1;"..sort_filed.."groupby=attr:structure_id;groupby=attr:paper_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        --str = string.gsub (str, " ", " ")
    end
    return str
end

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local paper_info = ""
for i=1,#res do
    local str = "{\"iid\":\""..res[i]["id"].."\",\"paper_id\":\"##\",\"paper_name\":\"##\",\"ti_num\":\"##\",\"create_time\":\"##\",\"paper_source\":\"##\",\"preview_status\":\"##\",\"extenstion\":\"##\",\"file_id\":\"##\",\"page\":\"##\",\"parent_structure_name\":\"##\",\"paper_id_char\":\"##\",\"paper_id_int\":\"##\",\"person_id\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"structure_id_int\":\"##\",\"scheme_id_int\":\"##\",\"paper_app_type\":\"##\",\"paper_app_type_name\":\"##\",\"url_code\":\"##\",\"person_name\":\"##\",\"org_name\":\"##\",\"tuijian\":\"##\"}"
    local paper_value = cache:hmget("paper_"..res[i]["id"],"paper_id_char","paper_name","question_count","create_time","paper_type","preview_status","extension","file_id","paper_page","structure_id","paper_id_char","paper_id_int","person_id","for_urlencoder_url","for_iso_url","paper_type","paper_type","paper_app_type","paper_app_type_name")
    if paper_value[5]=="2" then
	local resource_info_id = cache:hmget("paper_"..res[i]["id"],"resource_info_id")[1]
    --local resource_info = cache:hmget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
	local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
	paper_value[6] = resource_info[2]
	paper_value[14] = resource_info[6]
	paper_value[15] = resource_info[4]
	paper_value[8] = resource_info[8]
	paper_value[9] = resource_info[10]
	paper_value[16] = resource_info[12]
	paper_value[17] = resource_info[14]


    local structure_id = paper_value[10]
    local curr_path = ""

    local structures = cache:zrange("structure_code_"..structure_id,0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
       curr_path = curr_path..structure_info[1].."->"
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)

    paper_value[10] = curr_path

    end
    if paper_value[1]~=ngx.null then
        for j=1,#paper_value do
	        str = string.gsub(str,"##",paper_value[j],1)
        end
		
		 local url_code = urlencode(paper_value[2]);
		 str = string.gsub(str,"##",url_code,1)
		 
		 --添加上传人和上传机构
		 local person_id = paper_value[13];
         local person_name = "";
	     local org_name = "";
	    if person_id=="32" or person_id=="34" or person_id=="-1" or person_id=="0" then
	        org_name = "未知";
		    person_name = "未知"
	     elseif person_id =="1" then
	        org_name = "东师理想";
		    person_name = "东师理想";
	     else
	    --根据人员id获得对应的组织机构名称 
        local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..person_id.."&identity_id=5")
		 org_name = org_name_body.body
		 person_name = cache:hget("person_"..person_id.."_5","person_name");
	end
	  str = string.gsub(str,"##",person_name,1)
	  str = string.gsub(str,"##",org_name,1)
	  local tuijian = ssdb_db:zexists("tuijian_sj_"..bureau_id,res[i]["id"])
	  str = string.gsub(str,"##",tostring(tuijian[1]),1)
		 
        paper_info = paper_info..str..","
    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

paper_info = string.sub(paper_info,0,#paper_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..paper_info.."]}")

