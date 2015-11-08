
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询试题列表
-- 作者：刘全锋
-- 日期：2015年8月28日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end



local cookie_person_id = tostring(ngx.var.cookie_background_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_background_identity_id)

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


--结点ID
local nid = tostring(args["nid"]);


--判断是否有结点ID参数
if nid == "nil" then
    ngx.say("{\"success\":false,\"info\":\"结点ID参数错误！\"}")
    return
end
local scheme_id = tostring(args["scheme_id"])
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id丢失！\"}")
    return
end

--难度
local nd_id = tostring(args["nd_id"])
--判断是否有资源类型参数
if nd_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"难度参数错误！\"}")    
    return
end
--题型
local qtype = tostring(args["qtype"])
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

local keyword = tostring(args["keyword"])
--显示什么 0：全部 1：理想 2：本区 3：本校 4：教研室
local view = tostring(args["view"])
--判断是否有显示类型参数
if view == "nil" then
    ngx.say("{\"success\":false,\"info\":\"view参数错误！\"}")    
    return
end
--第几页
local pageNumber = tostring(args["pageNumber"])
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(args["pageSize"])
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")    
    return
end
--是否是根节点
local is_root = tostring(args["is_root"])
--判断是否有是否是根节点的参数
if is_root == "nil" then
    ngx.say("{\"success\":false,\"info\":\"is_root参数错误！\"}")
    return
end
--是否包含子节点
local cnode = tostring(args["cnode"])
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


local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100


local res = db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ndid..str_qtype.."filter=b_in_paper,0;filter=b_delete,0;select=("..str_group..") as match_qq;filter= match_qq, 1;groupsort=update_ts desc;groupby=attr:question_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")



ngx.log(ngx.ERR,"=====>SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ndid..str_qtype.."filter=b_in_paper,0;filter=b_delete,0;select=("..str_group..") as match_qq;filter= match_qq, 1;groupsort=update_ts desc;groupby=attr:question_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;<====");


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

    local question_json = tostring(cache:hmget("question_"..res[i]["id"],"json_question")[1])
		
	if question_json ~= "userdata: NULL" and question_json ~= "" then

		local jsonQuesObj = cjson.decode(ngx.decode_base64(question_json));
		local strucIdInt  = jsonQuesObj["structure_id"];
		local strucPath   = strucService: getStrucPath(strucIdInt);
		jsonQuesObj["structure_path"] = strucPath;

		local jsonEncodeStr = cjson.encode(jsonQuesObj);

		local create_person = tostring(cache:hmget("question_"..res[i]["id"],"create_person")[1])
		question_info = question_info .. "{\"id\":\"" .. res[i]["id"] .. "\",\"json_question\":" .. jsonEncodeStr .. ",\"create_person\":\"".. create_person .."\"},"
	end
end
question_info = string.sub(question_info,0,#question_info-1);


--放回连接池
cache:set_keepalive(0,v_pool_size);
DBUtil: keepDbAlive(db);


ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")
