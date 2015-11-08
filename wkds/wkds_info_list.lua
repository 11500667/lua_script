#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"token参数错误！\"}")
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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
    ngx.say("{\"success\":false,\"info\":\"nid参数错误！\"}")
    return
end
--版本号
local scheme_id = tostring(args["scheme_id"])
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end
--搜索关键字
local keyword = tostring(args["keyword"])
--显示什么 0：全部 1：理想 2：本区 3：本校 4：教研室
local view = tostring(args["view"])
--判断是否有显示类型参数
if view == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"view参数错误！\"}")    
    return
end
--第几页
local pageNumber = tostring(args["pageNumber"])
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")    
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
    ngx.say("{\"success\":\"false\",\"info\":\"is_root参数错误！\"}")
    return
end
--按谁排序  1：教师  2：播放次数  3：平均分 4：时间 5：下载次数 6:微课类型
local sort_type = tostring(args["sort_type"])
--判断是否有排序的参数
if sort_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_order"])
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
--判断显示的范围 1：云微课 2：我的微课 3：云大赛
local wkds_type = tostring(args["wkds_type"])
if wkds_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"wkds_type参数错误！\"}")
    return
end

--业务类型   1：收藏 2：我推荐 3：推荐给我 4：我评论 5：反馈 6：我的上传 7：我的共享 8:我的回收站  0：全部
local bType = tostring(args["bType"])
--判断是否有排序的参数
if bType == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"业务类型参数错误！\"}")
    return
end
--微课类型
local wk_type = tostring(args["wk_type"])
--ngx.log(ngx.ERR,"WKDS_777777777777"..wk_type)
--判断是否有排序的参数
if wk_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"微课类型参数错误！\"}")
    return
end
local wk_type_str ="";
if wk_type ~= "0" then
    wk_type_str = "filter=wk_type,"..wk_type..";";
end

local bType_str = ""
local str_group = ""
local person_str =""
--判断是云微课还是我的微课
if wkds_type == "1" then
    --拼组的条件
    if view=="0" then
        str_group = "IF(person_id="..cookie_person_id..",1,0) "
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
    elseif view=="6" then
        str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")..",1,0)"
    elseif view=="7" then
        str_group = " IF(group_id="..cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")..",1,0)"
    else
        str_group = " IF(group_id="..view..",1,0)"
    end


    if view =="0" then
        str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;groupby=attr:wkds_id_int;" 
    else
        str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;groupby=attr:wkds_id_int;" 
    end

elseif wkds_type == "2" then
    person_str = "filter=person_id,"..cookie_person_id..";"
    --拼我的微课的条件
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
        str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;groupby=attr:wkds_id_int;"

    end
end

local pack_type = tostring(args["pack_type"])

--是否包含子节点
local cnode = tostring(args["cnode"])

local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id,"..scheme_id..";"
    else
        structure_scheme = "filter=structure_id,"..nid..";"
    end
else
    if cnode == "2" then
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

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "asc"
else
    asc_desc = "desc"
end 

--排序
local sort_filed = ""
--if view =="0" then

    if sort_type=="1" then
        sort_filed = "groupsort=teacher_name_py "..asc_desc..";groupby=attr:wkds_id_int;"
        --sort_filed = "sort=attr_"..asc_desc..":teacher_name_py;"
    elseif sort_type=="2" then
        sort_filed = "groupsort=play_count "..asc_desc..";groupby=attr:wkds_id_int;"
        --  sort_filed = "sort=attr_"..asc_desc..":play_count;"
    elseif sort_type=="3" then
        sort_filed = "groupsort=score_average "..asc_desc..";groupby=attr:wkds_id_int;"
        --  sort_filed = "sort=attr_"..asc_desc..":score_average;"
    elseif sort_type=="4" then
        sort_filed = "groupsort=ts "..asc_desc..";groupby=attr:wkds_id_int;"
        -- sort_filed = "sort=attr_"..asc_desc..":ts;"   
    elseif sort_type=="5" then
        sort_filed = "groupsort=download_count "..asc_desc..";groupby=attr:wkds_id_int;"
        --sort_filed = "sort=attr_"..asc_desc..":download_count;"

    elseif sort_type== "6" then
        sort_filed = "groupsort=wk_type "..asc_desc..";groupby=attr:wkds_id_int;"
    end
--[[
elseif bType == "0" then

    if sort_type=="1" then
        sort_filed = "groupsort=teacher_name_py "..asc_desc..";"
        --sort_filed = "sort=attr_"..asc_desc..":teacher_name_py;"
    elseif sort_type=="2" then
        sort_filed = "groupsort=play_count "..asc_desc..";"
        --  sort_filed = "sort=attr_"..asc_desc..":play_count;"
    elseif sort_type=="3" then
        sort_filed = "groupsort=score_average "..asc_desc..";"
        --  sort_filed = "sort=attr_"..asc_desc..":score_average;"
    elseif sort_type=="4" then
        sort_filed = "groupsort=ts "..asc_desc..";"
        -- sort_filed = "sort=attr_"..asc_desc..":ts;"   
    elseif sort_type=="5" then
        sort_filed = "groupsort=download_count "..asc_desc..";"
        --sort_filed = "sort=attr_"..asc_desc..":download_count;"
    elseif sort_type== "6" then
        sort_filed = "groupsort=wk_type "..asc_desc..";"

    end
else

    if sort_type=="1" then
        sort_filed = "sort=attr_"..asc_desc..":teacher_name_py;"
    elseif sort_type=="2" then
        sort_filed = "sort=attr_"..asc_desc..":play_count;"
    elseif sort_type=="3" then
        sort_filed = "sort=attr_"..asc_desc..":score_average;"
    elseif sort_type=="4" then
        sort_filed = "sort=attr_"..asc_desc..":ts;"   
    elseif sort_type=="5" then
        sort_filed = "sort=attr_"..asc_desc..":download_count;"
    elseif sort_type== "6" then
        sort_filed = "sort=attr_"..asc_desc..":wk_type;"

    end

end
]]
--微课还是微课程

local w_type = tostring(args["w_type"])
if w_type == "nil" then
   w_type = 1;
end
local w_type_str = "";
if w_type ~= "0" then
 w_type_str= "filter=w_type,"..w_type..";";
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
--ngx.say("3bType_str="..bType_str)  
--[[
local wkds = ""
wkds = db:query("SELECT SQL_NO_CACHE id FROM t_pack_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";select=("..str_group..") as match_qq;filter= match_qq, 1;"..sort_filed.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

ngx.say("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";"..str_group..person_str..bType_str..sort_filed.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--]]
local str_delete = "";
if bType == "10" then
   str_delete = "2";
elseif  bType == "0" then
    str_delete = "0,2";
else
   str_delete = "0";
end
ngx.log(ngx.ERR,"@@@@@@@@@@@@@@@@@@@@@SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";"..str_group..person_str..bType_str..sort_filed..w_type_str.."filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;@@@@@@@@@@@@@@@@@@@@@")
local wkds = ""
wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";"..str_group..person_str..bType_str..wk_type_str..sort_filed..w_type_str.."filter=isdraft,0;filter=check_status,0,1;filter=b_delete,"..str_delete..";maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local cjson     = require "cjson"
--去第二个结果集中的Status中截取总个数
local wkds1     = db:read_result()
local _,s_str   = string.find(wkds1[1]["Status"],"found: ")
local e_str     = string.find(wkds1[1]["Status"],", time:")
local totalRow  = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

-- shenjian 2015-06-05 加入审核状态的处理 begin
local chkStatusTable = nil;
if bType == "7" then
    local objIdTable = {};
    
    for index = 1, #wkds do
        local myInfoId = wkds[index]["id"];
        local wkdsIdInt = cache: hget("wkds_" .. myInfoId, "wkds_id_int");

        table.insert(objIdTable, wkdsIdInt);
    end

    local objType = 5;
    if #objIdTable > 0 then
        local checkInfoModel = require "multi_check.model.CheckInfo";
        chkStatusTable = checkInfoModel: getCheckStatusByObjIdInt(objType, objIdTable);
    end
end
-- shenjian 2015-06-05 加入审核状态的处理 end

local wkds_info = ""
for i=1,#wkds do

    local str = "{\"id\":\""..wkds[i]["id"].."\",\"wkds_id_int\":\"##\",\"wkds_id_char\":\"##\",\"scheme_id_int\":\"##\",\"structure_id\":\"##\",\"wkds_name\":\"##\",\"study_instr\":\"##\",\"teacher_name\":\"##\",\"play_count\":\"##\",\"score_average\":\"##\",\"create_time\":\"##\",\"download_count\":\"##\",\"thumb_id\":\"##\",\"downloadable\":\"##\",\"person_id\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\",\"content_json\":\"##\",\"wk_type\":\"##\",\"wk_type_name\":\"##\",\"type_id\":\"##\",\"uploader_id\":\"##\",\"w_type\":\"##\",\"parent_structure_name\":\"##\",\"person_name\":\"##\",\"org_name\":\"##\",\"is_multi_check\":\"##\",\"now_status\":\"##\"}"

    local wkds_value_null = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int")
    if wkds_value_null[1] ~=ngx.null then

        local wkds_value = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id","w_type")
        local  thumb_id = ""
        for j=1,#wkds_value do

            if j==12 then 
                --解析json数据获得第一个视频的缩略图，如果没有显示默认的缩略图
                local content_json = wkds_value[17]
                local aa = ngx.decode_base64(content_json)
                local data = cjson.decode(aa)
                if #data.sp_list~=0 then

                    local resource_info_id = data.sp_list[1].id;
                    if resource_info_id ~= ngx.null then
                        local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id,"thumb_id")
                        if tostring(thumbid[2]) ~= "userdata: NULL" then
                            thumb_id = thumbid[2]
                        end
                    end                              
                else
                    thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                end

                if not thumb_id or string.len(thumb_id) == 0 then
                    thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                end
                str = string.gsub(str,"##",thumb_id,1)
            else
				--ngx.log(ngx.ERR, "[sj_log] -> index: [", j, "], wkds_info_id: [", wkds[i]["id"], "]");
                str = string.gsub(str,"##",wkds_value[j],1)
            end    
        end     
        local structure_id = wkds_value[4]
        local curr_path = ""

        local structures = cache:zrange("structure_code_"..structure_id,0,-1)
        for i=1,#structures do
            local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
            curr_path = curr_path..structure_info[1].."->"
        end
        curr_path = string.sub(curr_path,0,#curr_path-2)
        str = string.gsub(str,"##",curr_path,1)

        --上传人 上传机构
        local person_id = wkds_value[21];
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

        -- shenjian 2015-06-05 加入审核状态的处理 begin
        if chkStatusTable ~= nil then
            local chkStatusStr = chkStatusTable[wkds_value[1]];
            if chkStatusStr ~= nil and chkStatusStr ~= ngx.null and chkStatusStr ~= "" then
                str = string.gsub(str, "##", "true", 1);
                str = string.gsub(str, "##", chkStatusStr, 1);
            else
                str = string.gsub(str, "##", "false", 1);
                str = string.gsub(str, "##", "未知" , 1);
            end
        else
            str = string.gsub(str, "##", "false", 1);
            str = string.gsub(str, "##", "未知" , 1);
        end
        -- shenjian 2015-06-05 加入审核状态的处理 end

        wkds_info = wkds_info..str..","

    end
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

wkds_info = string.sub(wkds_info,0,#wkds_info-1)
local json_list = "{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..wkds_info.."]}";
ngx.say(json_list)


