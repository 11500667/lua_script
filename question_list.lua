#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--结点ID
local nid = tostring(ngx.var.arg_nid)
--判断是否有结点ID参数
if nid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"结点ID参数错误！\"}")
    return
end
local scheme_id = tostring(ngx.var.arg_scheme_id)
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id丢失！\"}")
    return
end
--难度
local nd_id = tostring(ngx.var.arg_nd_id)
--判断是否有资源类型参数
if nd_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"难度参数错误！\"}")
    return
end
--题型
local qtype = tostring(ngx.var.arg_qtype)
--判断是否有资源类型参数
if qtype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"题型参数错误！\"}")
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
--搜索关键字
--local keyword = tostring(ngx.var.arg_keyword)
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

--拼组的条件
local str_group = ""
if view=="0" then
    str_group = "IF(create_person="..cookie_person_id..",1,0) "
    local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id)
    for i=1,#group_list do
        str_group = str_group.." OR IF(group_id="..group_list[i]..",1,0)"
    end
elseif view=="1" then
    str_group = " IF(group_id=1,1,0)"
elseif view=="2" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")..",1,0)"
elseif view=="3" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")..",1,0)"
elseif view=="4" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")..",1,0)"
elseif view=="5" then
    str_group = "IF(create_person="..cookie_person_id..",1,0) AND IF(group_id=2,1,0)"
elseif view=="6" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")..",1,0)"
elseif view=="7" then
    str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")..",1,0)"
elseif view=="-1" then
    str_group = " IF(group_id=1,1,0)"
else
    str_group = " IF(group_id="..view..",1,0)"
end

--拼难度的条件
local str_ndid = ""
if nd_id~="0" then
    str_ndid = " filter=question_difficult_id,"..nd_id..";"
end
--拼题型的条件
local str_qtype = ""
if qtype~="0" then
    str_qtype = " filter=question_type_id,"..qtype..";"
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


local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id_int,"..scheme_id..";"
    else
        structure_scheme = "filter=structure_id_int,"..nid..";"
    end
else
    if cnode == "0" then
        structure_scheme = "filter=structure_id_int,"..nid..";"
    else
        local sid = cache:get("node_"..nid)
        local sids = Split(sid,",")
        for i=1,#sids do
            structure_scheme = structure_scheme..sids[i]..","
        end
        structure_scheme = "filter=structure_id_int,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
    end
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
local str_maxmatches = 100000

ngx.log(ngx.ERR,"###########".."SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ndid..str_qtype.."filter=b_in_paper,0;filter=b_delete,0;select=("..str_group..") as match_qq;filter= match_qq, 1;groupsort=ts desc;groupby=attr:question_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;".."###############")

local res = db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ndid..str_qtype.."filter=b_in_paper,0;filter=b_delete,0;select=("..str_group..") as match_qq;filter= match_qq, 1;groupsort=ts desc;groupby=attr:question_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local cjson         = require "cjson";
local strucService  = require "base.structure.services.StructureService";
local question_info = ""
for i=1,#res do
    --ngx.log(ngx.ERR, "[errrrr] -> [", res[i]["id"], "]");
    local question_json = tostring(cache:hmget("question_"..res[i]["id"],"json_question")[1])
    if question_json ~= "userdata: NULL" then
        local jsonQuesObj = cjson.decode(ngx.decode_base64(question_json));
        local strucIdInt  = jsonQuesObj["structure_id"];
        --ngx.log(ngx.ERR, "[sj_log] -> [question_list] -> strucIdInt ->[", strucIdInt, "]");
        local strucPath   = strucService: getStrucPath(strucIdInt);
        jsonQuesObj["structure_path"] = strucPath;

        local jsonEncodeStr = cjson.encode(jsonQuesObj);

        local create_person = tostring(cache:hmget("question_"..res[i]["id"],"create_person")[1])
        local person_id = create_person;

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
            local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..      person_id.."&identity_id=5")
            org_name = org_name_body.body
            person_name = cache:hget("person_"..person_id.."_5","person_name");
        end

        question_info = question_info.."{\"id\":\""..res[i]["id"].."\",\"json_question\":"..jsonEncodeStr..",\"create_person\":\""..create_person.."\",\"person_name\":\""..person_name.."\",\"org_name\":\""..org_name.."\"},"
    end
end
question_info = string.sub(question_info,0,#question_info-1)

ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")
