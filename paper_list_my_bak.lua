local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
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
local ptype = tostring(ngx.var.arg_ptype)
--判断是否有资源类型参数
if ptype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"ptype参数错误！\"}")
    return
end
--第几页
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--是否是根节点
local is_root = tostring(ngx.var.arg_is_root)
--判断是否有是否是根节点的参数
if is_root == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
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
local sort_type = tostring(ngx.var.arg_sort_type)
--判断是否有排序的参数
if sort_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(ngx.var.arg_sort_num)
--判断是否有排序的参数
if sort_num == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--搜索关键字
--local keyword = tostring(ngx.var.arg_keyword)
local keyword = tostring(args["keyword"])
if keyword=="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    keyword = ngx.decode_base64(keyword)..";"
end
--业务类型   1：收藏 2：我推荐 3：推荐给我 4：我评论 5：反馈 6：我的上传 0：全部
local bType = tostring(ngx.var.arg_bType)
--判断是否有排序的参数
if bType == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"业务类型参数错误！\"}")
    return
end
local person_str = "filter=person_id,"..cookie_person_id..";"
local bType_str = ""
local str_group = ""
if bType~="0" then
    bType_str = "filter=TYPE_ID,"..bType..";"
    if bType=="3" then
        person_str = ""
        local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
        for i=1,#group_list do
            str_group = str_group.." IF(group_id="..group_list[i]..",1,0) OR"
        end
        local sheng = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")
        local shi = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
        local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
        local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
        local bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
        str_group = str_group.." IF(group_id="..sheng..",1,0) OR IF(group_id="..shi..",1,0) OR IF(group_id="..qu..",1,0) OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
        str_group = str_group.." IF(person_id="..cookie_person_id..",1,0)"
        str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;"
    end
else
    person_str = ""
        local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
        for i=1,#group_list do
            str_group = str_group.." IF(group_id="..group_list[i]..",1,0) OR"
        end
        local sheng = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")
        local shi = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
        local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
        local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
        local bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
        str_group = str_group.." IF(group_id="..sheng..",1,0) OR IF(group_id="..shi..",1,0) OR IF(group_id="..qu..",1,0) OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
        str_group = str_group.." IF(person_id="..cookie_person_id..",1,0)"
        str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;"
end

local str_ptype = ""
if ptype~="0" then
    str_ptype = " filter=paper_type,"..ptype..";"
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
    asc_desc = "sort=attr_asc:"
    --asc_desc = "asc"
else
    asc_desc = "sort=attr_desc:"
    --asc_desc = "desc"
end

--排序 1:题数  2:试卷类型  3:存档时间
local sort_filed = ""
if sort_type=="1" then
    sort_filed = asc_desc.."question_count;"
    --sort_filed = "groupsort=question_count "..asc_desc..";"
elseif sort_type=="2" then
    sort_filed = asc_desc.."paper_type;"
    --sort_filed = "groupsort=paper_type "..asc_desc..";"
else
    sort_filed = asc_desc.."ts;"
    --sort_filed = "groupsort=ts "..asc_desc..";"
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

local str_maxmatches = pageNumber*pageSize


local res = db:query("SELECT SQL_NO_CACHE id FROM t_sjk_paper_my_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ptype..sort_filed..bType_str..person_str..str_group.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local paper_info = ""
for i=1,#res do
    local str = "{\"iid\":\""..res[i]["id"].."\",\"paper_id\":\"##\",\"paper_name\":\"##\",\"ti_num\":\"##\",\"create_time\":\"##\",\"paper_source\":\"##\",\"preview_status\":\"##\",\"extenstion\":\"##\",\"file_id\":\"##\",\"page\":\"##\",\"parent_structure_name\":\"##\",\"paper_id_char\":\"##\",\"paper_id_int\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\",\"person_id\":\"##\",\"identity_id\":\"##\",\"owner_id\":\"##\",\"type_id\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\"}"
    local paper_value = cache:hmget("mypaper_"..res[i]["id"],"paper_id_char","paper_name","question_count","create_time","paper_type","preview_status","extension","file_id","paper_page","parent_structure_name","paper_id_char","paper_id_int","table_pk","group_id","person_id","identity_id","owner_id","type_id","for_urlencoder_url","for_iso_url")
    
    if paper_value[5]=="2" then
        local resource_info_id = cache:hmget("mypaper_"..res[i]["id"],"resource_info_id")[1]
        local resource_info = cache:hmget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page")
        paper_value[6] = resource_info[1]
        paper_value[19] = resource_info[3]
	paper_value[20] = resource_info[2]
        paper_value[8] = resource_info[4]
	paper_value[9] = resource_info[5]
    end

    if paper_value[1]~=ngx.null then
        for j=1,#paper_value do
            --if j > 18 then
                --str = string.gsub(str,"##",ngx.encode_base64(paper_value[j]),1)
            --else
                str = string.gsub(str,"##",paper_value[j],1)
            --end
        end
        paper_info = paper_info..str..","
    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

paper_info = string.sub(paper_info,0,#paper_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..paper_info.."]}")
