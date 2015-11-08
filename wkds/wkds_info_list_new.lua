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
--按谁排序  1：教师  2：播放次数  3：平均分 4：时间 5：下载次数
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

--业务类型   1：收藏 2：我推荐 3：推荐给我 4：我评论 5：反馈 6：我的上传 7：我的共享  0：全部
local bType = tostring(args["bType"])
--判断是否有排序的参数
if bType == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"业务类型参数错误！\"}")
    return
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
	   else
	       str_group = " IF(group_id="..view..",1,0)"
    	end
     str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;" 
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
                local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
                local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
                local bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
                str_group = str_group.." IF(group_id="..qu..",1,0) OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
                str_group = str_group.." IF(person_id="..cookie_person_id..",1,0)"
                str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;"
           end
        else
           person_str = ""
           local group_list = cache:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real")
           for i=1,#group_list do
               str_group = str_group.." IF(group_id="..group_list[i]..",1,0) OR"
           end
           local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
           local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
           local bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
           str_group = str_group.." IF(group_id="..qu..",1,0) OR IF(group_id="..xiao..",1,0) OR IF(group_id="..bm..",1,0) OR "
           str_group = str_group.." IF(person_id="..cookie_person_id..",1,0)"
           str_group = "select=("..str_group..") as match_qq;filter= match_qq, 1;"
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
ngx.log(ngx.ERR,"@@@@@@@@@@@@@@@@@@@@@SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";"..str_group..person_str..bType_str..sort_filed.."filter=isdraft,0;filter=check_status,0,1;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;@@@@@@@@@@@@@@@@@@@@@")
local wkds = ""
wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..keyword..structure_scheme.."filter=type,"..wkds_type..";"..str_group..person_str..bType_str..sort_filed.."filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local wkds1 = db:read_result()
local _,s_str = string.find(wkds1[1]["Status"],"found: ")
local e_str = string.find(wkds1[1]["Status"],", time:")
local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local cjson = require "cjson"
     
      --存放微课大赛的数组
      local wkdsArray={}
      for i=1,#wkds do
         local tab1 = {}
          local str = "{\"id\":\""..wkds[i]["id"].."\",\"wkds_id_int\":\"##\",\"wkds_id_char\":\"##\",\"scheme_id_int\":\"##\",\"structure_id\":\"##\",\"wkds_name\":\"##\",\"study_instr\":\"##\",\"teacher_name\":\"##\",\"play_count\":\"##\",\"score_average\":\"##\",\"create_time\":\"##\",\"download_count\":\"##\",\"thumb_id\":\"##\",\"downloadable\":\"##\",\"person_id\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\"}"
          local wkds_value_null = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int")
          if wkds_value_null[1] ~=ngx.null then

                local  thumb_id = ""
               local wkds_value = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json")
               for j=1,#wkds_value do

                   if j==12 then

                       local content_json = wkds_value[17]
                       local aa = ngx.decode_base64(content_json)
                       local data = cjson.decode(aa)
                       if #data.sp_list~=0 then

                          local resource_info_id = data.sp_list[1].id
                          if resource_info_id ~= ngx.null then
                           local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id,"thumb_id")
                           thumb_id = thumbid[2]
                          end                              
                       else
                           thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                       end
                     
                   end
                
               end
                   tab1["id"] = wkds[i]["id"]
                   tab1["wkds_id_int"] = wkds_value[1]
                   tab1["wkds_id_char"] = wkds_value[2]
                   tab1["scheme_id_int"] = wkds_value[3]
                   tab1["structure_id"] = wkds_value[4]
                   tab1["wkds_name"] = wkds_value[5]
                   tab1["study_instr"] = wkds_value[6]
                   tab1["teacher_name"] = wkds_value[7]
                   tab1["play_count"] = wkds_value[8]
                   tab1["score_average"] = wkds_value[9]
                   tab1["create_time"] = wkds_value[10]
                   tab1["download_count"] = wkds_value[11]
                   tab1["thumb_id"] = thumb_id
                   tab1["downloadable"] = wkds_value[13]
                   tab1["person_id"] = wkds_value[14]
                   tab1["table_pk"] = wkds_value[15]
                   tab1["group_id"] = wkds_value[16]
              
          end
          wkdsArray[i] = tab1
      end

         -- local tabs={}
          local tab = {}
        
          tab["success"]="true"
          tab["totalRow"]=totalRow
          tab["totalPage"]=totalPage
          tab["pageNumber"]=pageNumber
          tab["pageSize"]=pageSize
         --  table.insert(tab2,wkdsArray)
          tab["list"]=wkdsArray
         
         -- tab["list"]=wkdsArray
     --     table.insert(tabs,tab);  

   --[[    local  reserved = {

         ["while"] = true,    ["end"] = true,

        ["function"] = true, ["local"] = wkdsArray

}
]]        cjson.encode_empty_table_as_object(false)
          local jsonData = cjson.encode(tab)
        -- ngx.say(#jsonData);
        ngx.log(ngx.ERR,"********************"..jsonData.."****************************")
       -- local str = jsonData.sub(jsonData,2,#jsonData-1);
        -- ngx.say(jsonData.sub(jsonData,2,#jsonData-1))
      -- str = string.gsub(jsonData,"{}","[]")
      --放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
          ngx.say(jsonData)
     --    ngx.say(#jsonData.list);

