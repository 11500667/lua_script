#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-02-12
#描述：获得学生的微课
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
 local myts = require "resty.TS";

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

--接收参数
--版本号
local scheme_id = tostring(args["scheme_id"])
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end
--学生id
local student_id = tostring(args["student_id"])
if student_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end

--科目id
local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local structure_id = tostring(args["structure_id"])
if structure_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end

--搜索关键字
local keyword = tostring(args["keyword"])

--第几页
local pageNumber = tostring(args["pageNumber"])
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(args["pageSize"])
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
--是否是根节点
local is_root = tostring(args["is_root"])
if is_root == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"is_root参数错误！\"}")
    return
end

--按谁排序  1：教师  2：播放次数  3：平均分 4：时间 5：下载次数 6:微课类型 7:科目
local sort_type = tostring(args["sort_type"])
if sort_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_type参数错误！\"}")
    return
end
--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_order"])
if sort_num == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_num参数错误！\"}")
    return
end

--微课类型
local wk_type = tostring(args["wk_type"])
if wk_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"微课类型参数错误！\"}")
    return
end

--拼接查询条件
--微课类型
local wk_type_str ="";
if wk_type ~= "0" then
 wk_type_str = "filter=wk_type,"..wk_type..";";
end

--是否包含子节点
local cnode = tostring(args["cnode"])
if cnode == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"cnode参数错误！\"}")
    return
end
local structure_scheme = "";
if structure_id and string.len(structure_id)>0 and structure_id~="-1" then
    if is_root == "1" then
        if cnode == "1" then
            structure_scheme = "filter=scheme_id,"..scheme_id..";"
        else
      structure_scheme = "filter=structure_id,"..structure_id..";"
        end
    else
        if cnode == "0" then
            structure_scheme = "filter=structure_id,"..structure_id..";"
        else
            local sid = cache:get("node_"..structure_id)
            local sids = Split(sid,",")
            for i=1,#sids do
                structure_scheme = structure_scheme..sids[i]..","
            end
          structure_scheme = "filter=structure_id,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
        end
    end

end
--升序还是降序
local asc_desc = "";
if sort_num=="1" then
    asc_desc = "asc"
else
    asc_desc = "desc"
end 
--排序
local sort_filed="";
  if sort_type=="1" then
       sort_filed = "sort=attr_"..asc_desc..":teacher_name_py;"
    elseif sort_type=="2" then
       sort_filed = "sort=attr_"..asc_desc..":play_count;"
    elseif sort_type=="3" then
       sort_filed = "sort=attr_"..asc_desc..":score_average;"
    elseif sort_type=="4" then
       sort_filed = "sort=attr_"..asc_desc..":update_ts;"   
    elseif sort_type=="5" then
       sort_filed = "sort=attr_"..asc_desc..":download_count;"
	elseif sort_type== "6" then
	   sort_filed = "sort=attr_"..asc_desc..":wk_type;"
	elseif sort_type== "7" then
	   sort_filed = "sort=attr_"..asc_desc..":subject_id;"   
    end
	
--学生
local person_str="filter=student_id,"..student_id..";";

--structure_scheme = "filter=structure_id,"..structure_id..";"

if keyword =="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
  keyword = ""
    end
end
--科目
local subject_str ="";
if subject_id ~= "0" then
 subject_str = "filter=subject_id,"..subject_id..";";
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

ngx.log(ngx.ERR,"===========SELECT SQL_NO_CACHE id FROM t_wkds_wktostudent_sphinxse  WHERE query=\'"..keyword..subject_str..structure_scheme..person_str..wk_type_str..sort_filed.."filter=b_delete,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");
local wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_wktostudent_sphinxse  WHERE query=\'"..keyword..subject_str..structure_scheme..person_str..wk_type_str..sort_filed.."filter=b_delete,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");

--去第二个结果集中的Status中截取总个数
local wkds1 = db:read_result()
local _,s_str = string.find(wkds1[1]["Status"],"found: ")
local e_str = string.find(wkds1[1]["Status"],", time:")
local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local responseObj = {};
local wkds_tab = {};
local cjson = require "cjson"

  for j=1,#wkds do
      local tab = {};
	  --去ssdb中获得微课id
	  local wktostudent_info = ssdb_db:multi_hget( "wktostudent_"..wkds[j]["id"],"wkds_id","create_time");
	  
	  local wkds_value = cache:hmget("wkds_"..wktostudent_info[2],"wkds_id_int","wkds_id_char","scheme_id",
	  "structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","downloadable","person_id","group_id","content_json","wk_type","wk_type_name","subject_id");
	  tab.id = wktostudent_info[2];
	  tab.wkds_id_int = wkds_value[1];
	  tab.wkds_id_char = wkds_value[2];
	  tab.scheme_id_int = wkds_value[3];
	  tab.structure_id = wkds_value[4];
	  tab.wkds_name = wkds_value[5];
	  tab.study_instr = wkds_value[6];
	  tab.teacher_name = wkds_value[7];
	  tab.play_count = wkds_value[8];
	  tab.score_average = wkds_value[9];
	  tab.create_time = wktostudent_info[4];
	  tab.download_count = wkds_value[11];
	  --获得thumb_id
	  local thumb_id = "";
	  local content_json = wkds_value[15];
	  ngx.log(ngx.ERR,"****"..wktostudent_info[2].."*****");
	    ngx.log(ngx.ERR,"****"..wktostudent_info[2].."*****"..content_json);
      local aa = ngx.decode_base64(content_json)
      local data = cjson.decode(aa)
         if #data.sp_list~=0 then
         local resource_info_id = data.sp_list[1].id
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
	  
	  tab.thumb_id = thumb_id;
	  tab.downloadable = wkds_value[12];
	  tab.person_id = wkds_value[13];
	  tab.group_id = wkds_value[14];
	  tab.content_json = wkds_value[15];
	  tab.wk_type = wkds_value[16];
	  tab.wk_type_name = wkds_value[17];
	  tab.subject_id = wkds_value[18];
	  --根据subject_id获得subject_name
	  local subject_info = ssdb_db:multi_hget( "subject_"..wkds_value[18],"subject_name");
	  tab.subject_name = subject_info[2];
	 wkds_tab[j] = tab;
  end

responseObj.success = true;
responseObj.list= wkds_tab;
responseObj.totalPage = totalPage;
responseObj.totalRow = totalRow;
responseObj.pageNumber =pageNumber;
responseObj.pageSize =pageSize;

-- 5.将table对象转换成json
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
ngx.say(responseJson);












