--[[
根据资源类型[资源、试卷、备课、微课]获取发布到区域均衡栏目下的资源
@Author  chenxg
@Date    2015-03-08
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
--参数
--区域均衡ID
local qyjh_id = args["qyjh_id"]
--是否分类检索资源 0：不分类 1：分类
local isfljs = args["isfljs"]
--在哪个页面展示资源 1：区域均衡 2：大学区 3：协作体 4：个人中心 5：资源淘 6：活动 7：环节
local page_type = args["page_type"] 
--传入的当前用户
local person_id = args["person_id"] 
local xzt_id = args["xzt_id"] 
--传入的资源类型ID 1：资源 3：试卷 4：备课 5：微课
local obj_type = args["obj_type"]
--传入的大学区、协作体、活动ID
local path_id = args["path_id"]
local hj_id = args["hj_id"]
--控制显示的数量
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
--1:我传播的资源 2:传播给我的资源
local scope = args["Scope"]


--资源/试卷/备课/微课类型
local rtype = ""
--关键字
local keyword = ""
--资源拼接条件开始
local str_rtype = ""
local structure_scheme = ""

--升序还是降序 
local asc_desc = ""

--排序 
--资源【1:时间2:大小3:下载次数4:类型5:格式 其他:页数】
--试卷【1:题数2:试卷类型3:存档时间】
--微课【1:教师2:播放次数3:平均分4:时间5:下载次数6:微课类型7:科目】
local sort_filed = ""
--科目
local subject_str = ""
--应用类型
local app_type_id = ""

--判断参数是否为空
if not isfljs or string.len(isfljs) == 0 
	--or not obj_type or string.len(obj_type) == 0 
   then
    --say("{\"success\":false,\"info\":\"参数错误！\"}")
	returnjson["info"] = "参数错误！"
	returnjson["zy_hot"] = {}
	returnjson["sj_hot"] = {}
	returnjson["wk_hot"] = {}
	returnjson["bk_hot"] = {}
	returnjson.success = "false"
	say(cjson.encode(returnjson))
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--加码
--[[function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end]]
--UFT_CODE
local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end

local perfilter = ""


--在哪个页面检索资源
local pathfilter = ""
if page_type == "4" then--个人中心
	if not scope or string.len(scope) == 0 
		or not person_id or string.len(person_id) == 0
	then
		say("{\"success\":false,\"info\":\"Scope或者person_id参数错误！\"}")
		return
	end
	
	local scopePamas =""
	if xzt_id == "-1" or xzt_id == "0" or not xzt_id or string.len(xzt_id)<=0 then 
		local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
		if xzts[1] and string.len(xzts[1])>2 then
			scopePamas = "filter=xzt_id"..string.sub(xzts[1],0,string.len(xzts[1])-1)..";"
		else
			scopePamas = "filter=xzt_id,-1;"
		end
	else
		scopePamas = "filter=xzt_id,"..xzt_id..";"
	end
	
	if scope == "1" then--我传播的 
		perfilter = "filter=person_id,"..person_id..";"..scopePamas
	elseif scope == "2" then--传播给我的
		perfilter = "!filter=person_id,"..person_id..";"..scopePamas
	else
		perfilter = scopePamas
	end
end
if page_type == "2" then--大学区
	pathfilter = "filter=pub_target,"..path_id..";"
elseif page_type == "3" then--协作体
	pathfilter = "filter=xzt_id,"..path_id..";"
	sort_filed = "groupsort=ts desc;"
elseif page_type == "6" or page_type == "7" then--活动 
--	pathfilter = "filter=hd_id,"..path_id..";"
--elseif page_type == "7" then--环节
	if hj_id ~="-1" and scheme_id ~= "nil" then
		pathfilter = "filter=hd_id,"..path_id..";filter=hj_id,"..hj_id..";"
	else
		pathfilter = "filter=hd_id,"..path_id..";"
	end
end
--检索哪类资源
local tablefilter = ""
if obj_type == "1" or obj_type == "4" then--资源、备课
	tablefilter = "t_base_publish_sphinxse"
elseif obj_type == "3" then--试卷
	tablefilter = "t_base_publish_paper_sphinxse"
elseif obj_type == "5" then--微课
	tablefilter = "t_base_publish_wk_sphinxse"
end

--====带节点的参数,现在只有个人中心和资源淘有，及page_type=4、5======
if page_type == "4" or page_type == "5" then
	--====================公共参数=========
		--nid节点id
		local nid = tostring(args["nid"])
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
		keyword = tostring(args["keyword"])
		if keyword=="nil" then
			keyword = ""
		else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
			if #keyword~=0 then
				keyword = ngx.decode_base64(keyword)..";"
			else
				keyword = ""
			end
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
		--升序还是降序
		local sort_num = tostring(args["sort_num"])
		if sort_num == "nil" then
			ngx.say("{\"success\":false,\"info\":\"sort_num参数错误！\"}")
			return
		end

		--按谁排序
		local sort_type = tostring(args["sort_type"])
		if sort_type == "nil" then
			ngx.say("{\"success\":false,\"info\":\"sort_type参数错误！\"}")
			return
		end

		
	--====================公共参数=========
	--====================资源参数=========
	if obj_type == "1" then
		--资源类型
		rtype = tostring(args["rtype"])
		if rtype == "nil" then
			ngx.say("{\"success\":false,\"info\":\"rtype参数错误！\"}")
			return
		end

		--应用类型
		app_type_id = tostring(args["app_type_id"])
		if app_type_id == "nil" then
			ngx.say("{\"success\":false,\"info\":\"应用类型参数错误！\"}")
			return
		end
	
	--====================资源参数=========
	--****资源条件****
		if rtype ~= "0" then 
			str_rtype = " filter=media_type," .. rtype .. ";";
		end  

		if app_type_id ~= "0" then 
			app_type_id = " filter=app_type_id," .. app_type_id .. ";";
		else 
			app_type_id = "";
		end  

		if is_root ~="-1" then
			if is_root == "1" then
				structure_scheme = "filter=scheme_id,"..scheme_id..";"
			else
				if cnode == "0" then
					structure_scheme = "filter=structure_id,"..nid..";"
				else
					local sid = cache:get("node_"..nid)
					structure_scheme = "filter=structure_id,"..sid..";"
				end
			end
		end		
		--升序降序的条件
		if sort_num =="1" then
		   asc_desc = "asc"
		else
		   asc_desc = "desc"
		end

		if sort_type == "1" then --时间
			sort_filed = "groupsort=ts "..asc_desc..";"
		elseif sort_type == "2" then -- 大小
			sort_filed = "groupsort=resource_size_int " .. asc_desc ..";"
		elseif sort_type == "3"	then --下载次数
			sort_filed = "groupsort=down_count " .. asc_desc ..";"
		elseif sort_type == "4"	then --类型
			sort_filed = "groupsort=resource_type " .. asc_desc ..";"
		elseif sort_type == "5"	then --格式
			sort_filed = "groupsort=resource_format " .. asc_desc ..";"
		else --页数
			sort_filed = "groupsort=resource_page " .. asc_desc ..";"
		end
	--****资源条件****
	end
	--#####################################################################################
	--=======试卷参数=====
	if obj_type == "3" then
		--试卷类型
		rtype = tostring(ngx.var.arg_ptype)
		--判断是否有资源类型参数
		if rtype == "nil" then
			ngx.say("{\"success\":false,\"info\":\"ptype参数错误！\"}")
			return
		end
	--=======试卷参数=====
	--****试卷条件****
		if rtype~="0" then
			str_rtype = " filter=paper_type,"..rtype..";"
		end
		--是否包含子根点的逻辑
		if is_root ~= "-1" then
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
		end
		--升序还是降序
		if sort_num=="1" then
			asc_desc = "asc"
		else
			asc_desc = "desc"
		end

		--排序 1:题数  2:试卷类型  3:存档时间
		if sort_type=="1" then
			sort_filed = "groupsort=question_count "..asc_desc..";"
		elseif sort_type=="2" then
			sort_filed = "groupsort=paper_type "..asc_desc..";"
		else
			sort_filed = "groupsort=ts "..asc_desc..";"
		end
		--****试卷条件****
	end
	--====================备课参数=========
	if obj_type == "4" then
		rtype = tostring(args["beike_type"])
		if rtype == "nil" then
			ngx.say("{\"success\":false,\"info\":\"beike_type参数错误！\"}")
			return
		end
		--****备课条件****
		if rtype ~= "0" then
			str_rtype = "filter=bk_type,"..rtype..";"
		end
		if is_root ~="-1" then
			if is_root == "1" then
				structure_scheme = "filter=scheme_id,"..scheme_id..";"
			else
				if cnode == "0" then
					structure_scheme = "filter=structure_id,"..nid..";"
				else
					local sid = cache:get("node_"..nid)
					structure_scheme = "filter=structure_id,"..sid..";"
				end
			end
		end
		--升序降序的条件
		if sort_num =="1" then
		   asc_desc = "asc"
		else
		   asc_desc = "desc"
		end

		if sort_type == "1" then --时间
			sort_filed = "groupsort=ts "..asc_desc..";"
		elseif sort_type == "2" then -- 大小
			sort_filed = "groupsort=resource_size_int " .. asc_desc ..";"
		elseif sort_type == "3"	then --下载次数
			sort_filed = "groupsort=down_count " .. asc_desc ..";"
		elseif sort_type == "4"	then --类型
			sort_filed = "groupsort=resource_type " .. asc_desc ..";"
		elseif sort_type == "5"	then --格式
			sort_filed = "groupsort=resource_format " .. asc_desc ..";"
		else --页数
			sort_filed = "groupsort=resource_page " .. asc_desc ..";"
		end
	end
	--====================微课参数=========
	if obj_type == "5" then
		--科目id
		--[[local subject_id = tostring(args["subject_id"])
		if subject_id == "nil" then
			ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
			return
		end
		]]
		--微课类型
		rtype = tostring(args["wk_type"])
		if rtype == "nil" then
			ngx.say("{\"success\":\"false\",\"info\":\"微课类型参数错误！\"}")
			return
		end
	
	--====================微课参数=========
	--****微课条件****
		if rtype ~= "0" then
			str_rtype = "filter=wk_type,"..rtype..";";
		end

		if nid ~="0" then
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

		end
		--升序还是降序
		if sort_num=="1" then
			asc_desc = "asc"
		else
			asc_desc = "desc"
		end 
		--排序
		if sort_type=="1" then
			sort_filed = "groupsort=teacher_name_py "..asc_desc..";"
		elseif sort_type=="2" then
		    sort_filed = "groupsort=play_count "..asc_desc..";"
		elseif sort_type=="3" then
		    sort_filed = "groupsort=score_average "..asc_desc..";"
		elseif sort_type=="4" then
		    sort_filed = "groupsort=update_ts "..asc_desc..";"   
		elseif sort_type=="5" then
		    sort_filed = "groupsort=download_count "..asc_desc..";"
		elseif sort_type== "6" then
		    sort_filed = "groupsort=wk_type "..asc_desc..";"
		elseif sort_type== "7" then
		    sort_filed = "groupsort=subject_id "..asc_desc..";"   
		end
		--[[
		if subject_id ~= "0" then
			subject_str = "filter=subject_id,"..subject_id..";";
		end
		]]
	--****微课条件****
	end	
end


--=================带节点的参数=================

local resource_hot_tab= {}
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
if isfljs =="0" then
	--**
	local sphinxSql = "SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='"..perfilter.."filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..qyjh_id..";"..pathfilter.."groupsort=ts desc;groupby=attr:obj_info_id;maxmatches="..(offset+limit)..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX STATUS;"
	ngx.log(ngx.ERR,"====*********>"..sphinxSql.."<*****====")
	res = mysql_db:query(sphinxSql)
	--**
else
	local sphinxSql = "SELECT SQL_NO_CACHE id FROM "..tablefilter.." WHERE query=\';".. keyword .. app_type_id ..structure_scheme .. str_rtype..perfilter..pathfilter..subject_str.."filter=b_delete,0;filter=obj_type,"..obj_type..";filter=pub_type,3;filter=qyjh_id,"..qyjh_id..";"..sort_filed.."groupby=attr:obj_info_id;maxmatches="..(offset+limit)..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX STATUS;"
	ngx.log(ngx.ERR,"cxg_log ======*****>"..sphinxSql.."<*****==========")
	res = mysql_db:query(sphinxSql)
	

end
local res1 = mysql_db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
--**************************
for i=1,#res do
  
   local  res_info_id = cache:hget("publish_"..res[i]["id"],"obj_info_id");
   local  obj_type = cache:hget("publish_"..res[i]["id"],"obj_type");
   local  xzt_id = cache:hget("publish_"..res[i]["id"],"xzt_id");
   local  hd_id = cache:hget("publish_"..res[i]["id"],"hd_id");
   if tostring(res_info_id) ~= "userdata: NULL" then
      local  res_tab = {}
	  local xzt_name=""
	  local hd_name=""
	   --如果获得的是微课列表
	   if obj_type =="5" then 
	      local thumb_id = "";
	      local wkds_value_null = cache:hmget("wkds_"..res_info_id,"wkds_id_int");
		  if wkds_value_null[1] ~= ngx.null then
		      local wkds_value = cache:hmget("wkds_"..res_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name",
			  "study_instr","teacher_name","play_count","score_average","create_time",
			  "download_count","downloadable","person_id","table_pk","group_id","content_json","teacher_name","wk_type");
			  
				local subject_name = ssdb:hget("t_resource_scheme_"..wkds_value[3],"subject_name")[1]  
				local subject_id = ssdb:hget("t_resource_scheme_"..wkds_value[3],"subject_id")[1]
			  
			  --获得缩略图id
			   local content_json = wkds_value[16]
                       local aa = ngx.decode_base64(content_json)
                       local data = cjson.decode(aa)
                       if #data.sp_list~=0 then

                          local resource_info_id = data.sp_list[1].id
                          if resource_info_id ~= ngx.null then
                           local thumbid = cache:hmget("resource_"..resource_info_id,"thumb_id")
                           thumb_id = thumbid[1]
                          end                              
                       else
                           thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                       end
				
		   --获得微课位置				
			 local structure_id = wkds_value[4]
			 local curr_path = ""
			 local structures = cache:zrange("structure_code_"..structure_id,0,-1)
			 for i=1,#structures do
				local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
				 curr_path = curr_path..structure_info[1].."->"
			 end
			 curr_path = string.sub(curr_path,0,#curr_path-2)
	   
			  res_tab["iid"]=res_info_id;
			  res_tab["wkds_id_int"]=wkds_value[1];
			  res_tab["wkds_id_char"]=wkds_value[2];
			  res_tab["obj_id_char"]=wkds_value[2];
			  res_tab["scheme_id_int"]=wkds_value[3];
			  res_tab["scheme_id"]=wkds_value[3];
			  res_tab["structure_id"]=wkds_value[4];
			  res_tab["wkds_name"]=wkds_value[5];
			  res_tab["study_instr"]=wkds_value[6];
			  res_tab["teacher_name"]=wkds_value[7];
			  res_tab["play_count"]=wkds_value[8];
			  res_tab["score_average"]=wkds_value[9];
			  res_tab["create_time"]=wkds_value[10];
			  res_tab["download_count"]=wkds_value[11];
			  res_tab["thumb_id"]=thumb_id;
			  res_tab["downloadable"]=wkds_value[12];
			  res_tab["person_id"]=wkds_value[13];
			  res_tab["table_pk"]=wkds_value[14];
			  res_tab["group_id"]=wkds_value[15];
			  res_tab["content_json"]=wkds_value[16];
			  res_tab["person_name"]=wkds_value[17];
			  res_tab["wk_type"]=wkds_value[18];
			  res_tab["parent_structure_name"]=curr_path;
			  res_tab["subject_name"]=subject_name;
			  res_tab["subject_id"]=subject_id;
			  res_tab["obj_type"]=obj_type;
			  --*****
				if tostring(xzt_id) ~= "userdata: NULL" and xzt_id ~= "" and xzt_id ~="-1" then
				--ngx.log(ngx.ERR,"===******===>"..xzt_id.."<=====******=====")
				local xzt = ssdb:hget("qyjh_xzt",xzt_id)
				if #xzt >=1 then
					xzt_name = cjson.decode(xzt[1]).name
				end
				end

				if tostring(hd_id) ~= "userdata: NULL" and hd_id~= "" and hd_id ~="-1" then
					local hd = ssdb:hget("qyjh_hd",hd_id)
					if #hd >=1 then
						hd_name = cjson.decode(hd[1]).active_name
					end
				end
				res_tab["xzt_name"]=xzt_name;
				res_tab["hd_name"]=hd_name;
			--*****
		  end
	   
	   else   
           --如果是查询试卷列表	   
		   if obj_type == "3" then
			 
			 local paper_type = cache:hget("paper_"..res_info_id,"paper_type");
			 local paper_id_int = cache:hget("paper_"..res_info_id,"paper_id_int");
			 local paper_id_char = cache:hget("paper_"..res_info_id,"paper_id_char");
			 res_tab["paper_id"] = paper_id_int; 
			 res_tab["paper_id_char"] = paper_id_char; 
			 res_tab["iid"] = res_info_id;
			 res_info_id = cache:hget("paper_"..res_info_id,"resource_info_id");
			 res_tab["paper_type"] = paper_type; 
			else
				res_tab["iid"] = res_info_id;
			end
		   
			local  res_info = cache:hmget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type","scheme_id_int","resource_id_int","person_id","app_type_id","resource_type","person_name","structure_id","resource_id_char")
			
			--根据版本ID获取该版本属于哪个学科    
			local subject_name = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_name")[1]
			local subject_id = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_id")[1]
			
			      
			res_tab["resource_title"] = res_info[1]    
			res_tab["resource_type_name"] = res_info[2]
			res_tab["resource_size"] = res_info[3]
			res_tab["create_time"] = res_info[4]
			res_tab["down_count"] = res_info[5]
			res_tab["file_id"] = res_info[6]    
			res_tab["width"] = res_info[7]
			res_tab["height"] = res_info[8]
			res_tab["resource_format"] = res_info[9]  
			res_tab["resource_page"] = res_info[10]
			res_tab["thumb_id"] = res_info[11]
			res_tab["preview_status"] = res_info[12]        
			res_tab["for_urlencoder_url"] = res_info[13]
			res_tab["for_iso_url"] = res_info[14]
			res_tab["resource_size_int"] = res_info[15]
			res_tab["beike_type"] = res_info[16]
			res_tab["url_code"] = urlEncode(res_info[1])
			res_tab["subject_name"] = subject_name
			res_tab["subject_id"] = subject_id
			res_tab["obj_type"] = obj_type
			res_tab["resource_id_int"] = res_info[18]
			res_tab["person_id"] = res_info[19]
			res_tab["app_type_id"] = res_info[20]
			res_tab["resource_type"] = res_info[21]
			res_tab["person_name"] = res_info[22]
			res_tab["structure_id"] = res_info[23]
			res_tab["obj_id_char"] = res_info[24]
			res_tab["scheme_id"] =res_info[17]
			local app_type_name = ""

			if res_info[20] ~= "-1" then
				--ngx.log(ngx.ERR,"====>"..res_info[17].."*"..res_info[20].."<====")			
				local res_person = ngx.location.capture("/dsideal_yy/apptype/get_apptypename?scheme_id="..res_info[17].."&app_type_id="..res_info[20])
				if res_person.status == 200 then
					app_type_name = res_person.body
				end
			end
			res_tab["app_type_name"] = app_type_name
			--*****
			if tostring(xzt_id) ~= "userdata: NULL" and xzt_id ~= "" and xzt_id ~="-1" then
			--ngx.log(ngx.ERR,"===******===>"..xzt_id.."<=====******=====")
			local xzt = ssdb:hget("qyjh_xzt",xzt_id)
			if #xzt >=1 then
				xzt_name = cjson.decode(xzt[1]).name
			end
			end

			if tostring(hd_id) ~= "userdata: NULL" and hd_id~= "" and hd_id ~="-1" then
				local hd = ssdb:hget("qyjh_hd",hd_id)
				if #hd >=1 then
					hd_name = cjson.decode(hd[1]).active_name
				end
			end
			res_tab["xzt_name"]=xzt_name;
			res_tab["hd_name"]=hd_name;
			--*****
	   end
        resource_hot_tab[i] = res_tab
  end
end
--**************************
returnjson.resource_hot_tab = resource_hot_tab
returnjson.success = "true"
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)