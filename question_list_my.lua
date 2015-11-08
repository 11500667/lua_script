local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--local SSDBUtil = require "common.SSDBUtil";

--local ssdb = SSDBUtil:getDb();

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
--版本号
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
--业务类型  1：收藏 2：我推荐 3：推荐给我 4：我评论 5：反馈 6：我的上传 7：我的共享 0：全部
local bType = tostring(ngx.var.arg_bType)
--判断是否有排序的参数
if bType == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"业务类型参数错误！\"}")
    return
end
local person_str = "filter=create_person,"..cookie_person_id..";"
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
		
		local shi_str = "";
		local qu_str = "";
		if shi ~= "0" then
		   shi_str = "OR IF(group_id="..shi..",1,0)";
		end
		if qu ~= "0" then
		   qu_str = "OR IF(group_id="..qu..",1,0)";
		end
		
        str_group = str_group.." IF(group_id="..sheng..",1,0) "..shi_str..qu_str.." OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
        str_group = str_group.." IF(create_person="..cookie_person_id..",1,0)"
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
	
	local shi_str = "";
	local qu_str = "";
	if shi ~= "0" then
	   shi_str = "OR IF(group_id="..shi..",1,0)";
	end
	if qu ~= "0" then
	   qu_str = "OR IF(group_id="..qu..",1,0)";
	end
	
    str_group = str_group.." IF(group_id="..sheng..",1,0) "..shi_str..qu_str.." OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
    str_group = str_group.." IF(create_person="..cookie_person_id..",1,0)"
    str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;"
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
local str_maxmatches = pageNumber*100

local str_delete = "";
if bType == "10" then
   str_delete = "2";
elseif  bType == "0" then
    str_delete = "0,2";
else
   str_delete = "0";
end

local res = db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_my_info_sphinxse WHERE query=\'"..keyword..structure_scheme..str_ndid..str_qtype..bType_str..person_str..str_group.."filter=b_delete,"..str_delete..";groupsort=ts desc;groupby=attr:question_id_char;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

-- shenjian 2015-06-04 加入审核状态的处理 begin
local chkStatusTable = nil;
local cjson = require "cjson";
if bType == "7" then
    local objIdTable = {};
    for index = 1, #res do
        local myInfoId   = res[index]["id"];
        local jsonQuesStr = cache: hget("myquestion_" .. myInfoId, "json_question");
        local jsonQues    = cjson.decode(ngx.decode_base64(jsonQuesStr));
        table.insert(objIdTable, jsonQues["question_id_char"]);
    end
    
    ngx.log(ngx.ERR, "[sj_log]-> [question_my_list] -> objIdTable : [", cjson.encode(objIdTable), "]");
    local objType = 2;
    if #objIdTable > 0 then
        local checkInfoModel = require "multi_check.model.CheckInfo";
        chkStatusTable = checkInfoModel: getCheckStatusByObjIdChar(objType, objIdTable);
    end
end
-- shenjian 2015-06-04 加入审核状态的处理 end

local cjson         = require "cjson";
local strucService  = require "base.structure.services.StructureService";
local question_info = ""
for i=1,#res do
    -- ngx.log(ngx.ERR, "====我的试卷===> 序号：", i, " ----> ", res[i]["id"], "<=== 错误的ID ===");
    local question_json = cache:hmget("myquestion_"..res[i]["id"],"id","type_id","table_pk","json_question","group_id","uploader_id")

    local jsonQuesObj = cjson.decode(ngx.decode_base64(question_json[4]));
    local strucIdInt  = jsonQuesObj["structure_id"];
    --ngx.log(ngx.ERR, "[sj_log] -> [question_list] -> strucIdInt ->[", strucIdInt, "]");
    local strucPath   = strucService: getStrucPath(strucIdInt);
    jsonQuesObj["structure_path"] = strucPath;
    local jsonEncodeStr = cjson.encode(jsonQuesObj);

    local l_group_id = ""
    if question_json[5]~=ngx.null then
        l_group_id = question_json[5]
    end

    if question_json[1]~=ngx.null then
        --上传人，上传机构
        local person_id = question_json[6];
        local person_name="--";
        local org_name = "";
        if person_id=="32" or person_id=="34" or person_id=="-1" or person_id=="0" then
            org_name = "未知";
            person_name="未知";
        elseif person_id =="1" then
            org_name = "东师理想";
            person_name="东师理想";
        else
            person_name = cache:hget("person_"..person_id.."_5","person_name");
            --根据人员id获得对应的组织机构名称 
            local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..person_id.."&identity_id=5")
            org_name = org_name_body.body
        end

        -- shenjian 2015-06-04 加入审核状态的处理 begin
        local chkStatusStr = "未知";
        local isMultiCheck = "false";

        local isDsidealCheck = "false";
        local chkDsidealStr = "未知";



        local jsonQuesStr  = question_json[4];
        local jsonQues     = cjson.decode(ngx.decode_base64(jsonQuesStr));

		local question_id_char = jsonQues.question_id_char;
		local structure_id_int = jsonQues.structure_id;
				
		local ssdblib = require "resty.ssdb"
		local ssdb = ssdblib:new()
		local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
		if not ok then
			say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end

        local result = ssdb:hget(question_id_char.."_"..structure_id_int,"check_status");
		

        if result[1]~="" then
            if tonumber(result[1])==1 then
                chkDsidealStr = "全国-审核通过";
            elseif tonumber(result[1])==2 then
                chkDsidealStr = "全国-待审核";
            elseif tonumber(result[1])==3 then
                chkDsidealStr = "全国-审核未通过";
            end
            isDsidealCheck = true;
        else

            if chkStatusTable ~= nil then
                local tempChkStatusStr = chkStatusTable[jsonQues["question_id_char"]];
                --ngx.log(ngx.ERR, "[sj_log] -> [question_list] -> questionIdChar:[", jsonQues["question_id_char"], "], tempChkStatusStr :[", tempChkStatusStr, "] ");
                if tempChkStatusStr ~= nil and tempChkStatusStr ~= ngx.null and tempChkStatusStr ~= "" then
                    isMultiCheck = "true";
                    chkStatusStr = tempChkStatusStr;
                else
                    isMultiCheck = "false";
                end
            else
                isMultiCheck = "false";
            end
        end


        -- shenjian 2015-06-04 加入审核状态的处理 end

        question_info = question_info.."{\"id\":\""..question_json[1].."\",\"type_id\":\""..question_json[2].."\",\"table_pk\":\""..question_json[3].."\",\"group_id\":\""..l_group_id.."\",\"create_person\":\""..question_json[6].."\",\"person_name\":\""..person_name.."\",\"org_name\":\""..org_name.."\",\"json_question\":"..jsonEncodeStr..",\"is_multi_check\":\"" .. tostring(isMultiCheck) .. "\",\"now_status\":\"" .. chkStatusStr .. "\",\"is_dsideal_check\":\"" .. tostring(isDsidealCheck) .. "\",\"dsideal_status\":\"" .. chkDsidealStr .. "\"},"
end
end
if #question_info~=0 then
    question_info = string.sub(question_info,0,#question_info-1)
end
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")
