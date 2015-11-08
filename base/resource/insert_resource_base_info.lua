#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-01-06
#描述：上传资源
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


 --连接redis
local redis = require "resty.redis"
local cache = redis:new();
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

	
--2.获得参数
--固定参数
local uuid =  require "resty.uuid";
local resource_id_char = uuid.new();
local create_time = ngx.localtime();
 local myts = require "resty.TS";
local ts =  myts.getTs();
local ResourceUtil 	= require "base.resource.model.ResourceUtil";



--local pinyin = "";
local down_count = 0;
local resource_page = 0;
local resource_size = -1;
local resource_size_int = -1;
local thumb_id = -1;
local for_urlencoder_url = -1;
local for_iso_url = -1;
local width = 0;
local height = 0;
local parent_structure_name = -1;
local material_type = -1;
local m3u8_url = -1;
local b_use = 1;
local file_md5 = -1;
local file_sha1 = -1;
local thumb_md5 = -1;
local thumb_sha1 = -1;
local product_id = -1;
local is_single = 1;
local check_status = 0; --0：不需要审核 1:审核通过 2：待审核 3：审核未通过
local check_message = "";
local old_file_path = "";
local is_multifile = 0;
local type_id = 6;

--传参数
--获得资源名称
if args["resource_title"] == nil or args["resource_title"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_title参数错误！\"}")
    return
end
local resource_title = args["resource_title"]
ngx.log(ngx.ERR, " ===> resource_title original ===> ", resource_title);

--获得扩展名
if args["resource_format"] == nil or args["resource_format"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_format参数错误！\"}")
    return
end
local resource_format = args["resource_format"]
--获得文件的id
if args["file_id"] == nil or args["file_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误！\"}")
    return
end
local file_id = args["file_id"]
--获得上传人名称
if args["person_name"] == nil or args["person_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_name参数错误！\"}")
    return
end
local person_name = args["person_name"]
person_name = ngx.decode_base64(person_name);
--获得结构id
if args["structure_id"] == nil or args["structure_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"structure_id参数错误！\"}")
    return
end
local structure_id = args["structure_id"]

--获得备课类型名称

 if args["bk_type_name"] == nil or args["bk_type_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bk_type_name参数错误！\"}")
    return
end
local bk_type_name = args["bk_type_name"]

--获得备课类型
 if args["beike_type"] == nil or args["beike_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"beike_type参数错误！\"}")
    return
end
local beike_type = args["beike_type"]

--获得人员id
 if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--获得m3u8状态
 if args["m3u8_status"] == nil or args["m3u8_status"] == "" then
    ngx.say("{\"success\":false,\"info\":\"m3u8_status参数错误！\"}")
    return
end
local m3u8_status = args["m3u8_status"]

--获得应用类型
 if args["app_type_id"] == nil or args["app_type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"app_type_id参数错误！\"}")
    return
end
local app_type_id = args["app_type_id"]

--获得res_type
 if args["res_type"] == nil or args["res_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"res_type参数错误！\"}")
    return
end
local res_type = args["res_type"]
--获得身份
 if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]
--获得group_id
 if args["group_id"] == nil or args["group_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local group_id = args["group_id"]


local subject_id = -1;
local stage_id = -1;

if tostring(args["subject_id"]) ~= "nil"  then
  subject_id = args["subject_id"]
end


if tostring(args["stage_id"]) ~= "nil"  then
  ngx.log(ngx.ERR,"进来了")
  stage_id = args["stage_id"]
end

local pinyin = "";
--需要计算的参数


local response = ngx.location.capture("/getQuanPin", {
	method = ngx.HTTP_GET,
	args = { name = resource_title}
});

if response.status == 200 then
   pinyin=response.body;
else
   ngx.say("{\"success\":false,\"info\":\"11查询失败！\"}")
   return
end

resource_title = ngx.decode_base64(resource_title);
ngx.log(ngx.ERR, " ===> resource_title base64 decode_base64 ===> ", resource_title);

--根据扩展名获得各个属性
local extension_info =  cache:hmget("t_resource_extension_"..resource_format,"mediatype_name","preview_status","thumb_status","thumb_id","mediatype_id");
local resource_type = extension_info[5];
local resource_type_name = extension_info[1];
local preview_status = extension_info[2];
local thumb_status = extension_info[3];
local thumb_id = extension_info[4];

--1:表示已发布的资源 2：表示待发布的资源 3：待删除的资源 4:表示已删除
local release_status = 1;
local source_id = 2;
if group_id == "1" then
      release_status = 2;
	  source_id = 1;
end

--local resource_id_int = "";
--根据结构id获得各个属性
local scheme_id_char ="";
local structure_code="";
local scheme_id_int=0;
local structure_id_char="";



if structure_id ~= "-1" then
    local structure_info= cache:hmget("t_resource_structure_"..structure_id,"structure_id_char","structure_code","scheme_id_int","scheme_id_char");
    scheme_id_char = structure_info[4];
    structure_code =structure_info[2];
    scheme_id_int = structure_info[3];
    structure_id_char = structure_info[1];
	--通过版本id获得对应的学科id和学段id
	local sql_subject = "SELECT subject_id,stage_id FROM t_resource_scheme WHERE scheme_id ="..scheme_id_int;
	local subject_info = db:query(sql_subject);
	subject_id = subject_info[1]["subject_id"];
	stage_id = subject_info[1]["stage_id"];
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
--resource缓存
local info_tab = {};
local myinfo_tab = {};

info_tab.resource_id_char = resource_id_char;
info_tab.resource_title = resource_title;
info_tab.resource_type = resource_type;
info_tab.resource_type_name = resource_type_name;
info_tab.resource_format = resource_format;
info_tab.resource_page = resource_page;
info_tab.resource_size = resource_size;
info_tab.resource_size_int = resource_size_int;
info_tab.create_time = create_time;
info_tab.down_count = down_count;
info_tab.file_id = file_id;
info_tab.thumb_id = thumb_id;
info_tab.person_name = person_name;
info_tab.structure_id = structure_id;
info_tab.scheme_id_int = scheme_id_int;
info_tab.preview_status = preview_status;
info_tab.for_urlencoder_url = for_urlencoder_url;
info_tab.for_iso_url = for_iso_url;
info_tab.width = width;
info_tab.height = height;
info_tab.bk_type_name = bk_type_name;
info_tab.beike_type = beike_type;
info_tab.parent_structure_name = parent_structure_name;
info_tab.release_status = release_status;
info_tab.person_id = person_id;
info_tab.material_type = material_type;
info_tab.m3u8_status = m3u8_status;
info_tab.m3u8_url = m3u8_url;
info_tab.app_type_id = app_type_id;
info_tab.res_type = res_type;
info_tab.subject_id = subject_id;
info_tab.stage_id = stage_id;

--myresource缓存
myinfo_tab.resource_id_char =resource_id_char;
myinfo_tab.resource_title =resource_title;
myinfo_tab.resource_type =resource_type;
myinfo_tab.resource_type_name =resource_type_name;
myinfo_tab.resource_format =resource_format;
myinfo_tab.resource_page =resource_page;
myinfo_tab.resource_size =resource_size;
myinfo_tab.resource_size_int =resource_size_int;
myinfo_tab.create_time =create_time;
myinfo_tab.down_count =down_count;
myinfo_tab.file_id =file_id;
myinfo_tab.thumb_id =thumb_id;
myinfo_tab.person_name =person_name;
myinfo_tab.structure_id =structure_id;
myinfo_tab.scheme_id_int =scheme_id_int;
myinfo_tab.type_id =type_id;
myinfo_tab.preview_status =preview_status;
myinfo_tab.for_urlencoder_url =for_urlencoder_url;
myinfo_tab.for_iso_url =for_iso_url;
myinfo_tab.table_pk = resource_id_int;
myinfo_tab.width =width;
myinfo_tab.height =height;
myinfo_tab.group_id =group_id;
myinfo_tab.parent_structure_name =parent_structure_name;
myinfo_tab.bk_type_name =bk_type_name;
myinfo_tab.beike_type =beike_type;
myinfo_tab.m3u8_status =m3u8_status;
myinfo_tab.m3u8_url =m3u8_url;
myinfo_tab.app_type_id =app_type_id;
myinfo_tab.res_type =res_type;
myinfo_tab.subject_id =subject_id;
myinfo_tab.stage_id =stage_id;
myinfo_tab.person_id =person_id;


ngx.log(ngx.ERR,"++++++++++++++++++++++++++++"..stage_id.."++++++++++++++++++++++++++++")
local resource_id_int = ssdb_db:incr("t_resource_base_pk")[1];
local resource_info_id = ssdb_db:incr("t_resource_info_pk")[1];

local in_base = "INSERT INTO t_resource_base(RESOURCE_ID_INT,RESOURCE_ID_CHAR,RESOURCE_TITLE,RESOURCE_SIZE,RESOURCE_SIZE_INT,RESOURCE_TYPE,RESOURCE_TYPE_NAME,RESOURCE_CATEGORY,CREATE_TIME,CREATE_PERSON,B_USE,UPDATE_LOGO,TS,SOURCE_ID,EXTENSION,FILE_ID,FILE_MD5,FILE_SHA1,THUMB_ID,THUMB_MD5,THUMB_SHA1,PINYIN,PRODUCT_ID,SCHEME_ID_CHAR,SCHEME_ID,STRUCTURE_CODE,STRUCTURE_ID_CHAR,STRUCTURE_ID,MATERIAL_TYPE,IS_SINGLE,PREVIEW_STATUS,DOWN_COUNT,CHECK_STATUS,CHECK_MESSAGE,THUMB_STATUS,PERSON_NAME,WIDTH,HEIGHT,RESOURCE_PAGE,OLD_FILE_PATH,is_multifile,parent_name,FOR_URLEncoder_Url,FOR_ISO_Url,RES_TYPE,BK_TYPE,BK_TYPE_NAME,RELEASE_STATUS,M3U8_STATUS,M3U8_URL,SUBJECT_ID,STAGE_ID) VALUES ("..resource_id_int..",'"..resource_id_char.."','"..resource_title.."','"..resource_size.."',"..resource_size_int..","..resource_type..",'"..resource_type_name.."',"..resource_type..",'"..create_time.."',"..person_id..","..b_use..",'"..resource_id_char.."',"..ts..","..source_id..",'"..resource_format.."','"..file_id.."',"..file_md5..",'"..file_sha1.."','"..thumb_id.."','"..thumb_md5.."','"..thumb_sha1.."','"..pinyin.."',"..product_id..",'"..scheme_id_char.."',"..scheme_id_int..",'"..structure_code.."','"..structure_id_char.."',"..structure_id..","..material_type..","..is_single..","..preview_status..","..down_count..","..check_status..",'"..check_message.."','"..thumb_status.."','"..person_name.."',"..width..","..height..","..resource_page..",'"..old_file_path.."',"..is_multifile..",'"..parent_structure_name.."','"..for_urlencoder_url.."','"..for_iso_url.."',"..res_type..","..beike_type..",'"..bk_type_name.."',"..release_status..","..m3u8_status..",'"..m3u8_url.."',"..subject_id..","..stage_id..") ";

    local res, err, errno, sqlstate = db:query(in_base)
	 if not res then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end

	--获得resource_id_int
  -- local resource_id_int = res.insert_id;
    info_tab.resource_id_int = resource_id_int;
    myinfo_tab.resource_id_int =resource_id_int;
	local resource_my_info_id ="";
local in_info = "INSERT into t_resource_info(ID,RESOURCE_ID_INT,RESOURCE_ID_CHAR,RESOURCE_TITLE,RESOURCE_TYPE_NAME,RESOURCE_FORMAT,RESOURCE_PAGE,RESOURCE_SIZE,RESOURCE_SIZE_INT,CREATE_TIME,DOWN_COUNT,FILE_ID,THUMB_ID,RESOURCE_TYPE,STRUCTURE_ID,PERSON_ID,IDENTITY_ID,GROUP_ID,PREVIEW_STATUS,SCHEME_ID_INT,TS,THUMB_STATUS,UPDATE_TS,PERSON_NAME,WIDTH,HEIGHT,FOR_URLEncoder_Url,FOR_ISO_Url,PARENT_STRUCTURE_NAME,RES_TYPE,BK_TYPE,BK_TYPE_NAME,RELEASE_STATUS,MATERIAL_TYPE,M3U8_STATUS,M3U8_URL,APP_TYPE_ID,SUBJECT_ID,STAGE_ID)VALUES (" .. resource_info_id .. ","..resource_id_int..",'"..resource_id_char.."','"..resource_title.."','"..resource_type_name.."','"..resource_format.."',"..resource_page..",'"..resource_size.."',"..resource_size_int..",'"..create_time.."',"..down_count..",'"..file_id.."','"..thumb_id.."',"..resource_type..","..structure_id..","..person_id..","..identity_id..","..group_id..","..preview_status..","..scheme_id_int..","..ts..","..thumb_status..","..ts..",'"..person_name.."',"..width..","..height..",'"..for_urlencoder_url.."','"..for_iso_url.."','"..parent_structure_name.."',"..res_type..","..beike_type..",'"..bk_type_name.."',"..release_status..","..material_type..","..m3u8_status..",'"..m3u8_url.."',"..app_type_id..","..subject_id..","..stage_id..") ";
 
   local res_info, err, errno, sqlstate = db:query(in_info)
	 if not res_info then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
   --获得resource_info_id
 --  local resource_info_id = "";
	--写入resource的缓存
	--cache:hmset("resource_"..resource_info_id,info_tab);
	
     info_tab.id = resource_info_id;
	local result = ResourceUtil:setResourceInfo(info_tab)
	
	if result==true then
	  --  ngx.say("成功")
	else
	    ngx.say("{\"success\":false,\"info\":\"操作失败\"}")
	end
	
	if group_id =="2" then
	 --   ngx.say("jinlaile");
	      resource_my_info_id=ssdb_db:incr("t_resource_my_info_pk")[1];
	    local in_myinfo = "INSERT INTO t_resource_my_info(ID,RESOURCE_ID_INT,RESOURCE_ID_CHAR,RESOURCE_TITLE,RESOURCE_TYPE,RESOURCE_SIZE_INT,RESOURCE_FORMAT,PERSON_ID,IDENTITY_ID,RESOURCE_PAGE,TS,DOWN_COUNT,TYPE_ID,UPDATE_TS,STRUCTURE_ID,SCHEME_ID_INT,PREVIEW_STATUS,THUMB_STATUS,FOR_URLEncoder_Url,FOR_ISO_Url,TABLE_Pk,RESOURCE_TYPE_NAME,FILE_ID,THUMB_ID,CREATE_TIME,RESOURCE_SIZE,WIDTH,HEIGHT,PARENT_STRUCTURE_NAME,RES_TYPE,BK_TYPE,BK_TYPE_NAME,M3U8_STATUS,M3U8_URL,APP_TYPE_ID,SUBJECT_ID,STAGE_ID)VALUES ("..resource_my_info_id..","..resource_id_int..",'"..resource_id_char.."','"..resource_title.."',"..resource_type..","..resource_size_int..",'"..resource_format.."',"..person_id..","..identity_id..","..resource_page..","..ts..","..down_count..","..type_id..","..ts..","..structure_id..","..scheme_id_int..","..preview_status..","..thumb_status..",'"..for_urlencoder_url.."','"..for_iso_url.."',"..resource_id_int..",'"..resource_type_name.."','"..file_id.."','"..thumb_id.."','"..create_time.."','"..resource_size.."',"..width..","..height..",'"..parent_structure_name.."',"..res_type..","..beike_type..",'"..bk_type_name.."',"..m3u8_status..",'"..m3u8_url.."',"..app_type_id..","..subject_id..","..stage_id..")";
		--ngx.say("in_myinfo"..in_myinfo);
		local res_myinfo, err, errno, sqlstate = db:query(in_myinfo)
	     if not res_myinfo then
	     --  ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	       return
         end
		--获得resource_my_info_id
		-- resource_my_info_id= res_myinfo.insert_id;
		--添加myrsource缓存
		--cache:hmset("myresource_"..resource_my_info_id,myinfo_tab);
        myinfo_tab.id = resource_my_info_id;
	    local result_my = ResourceUtil:setResourceMyInfo(myinfo_tab)
	
	    if result_my==true then
	       --  ngx.say("成功")
	    else
	       ngx.say("{\"success\":false,\"info\":\"操作失败\"}")
	    end
	
		
	end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.print("{\"success\":true,\"resource_info_id\":\""..resource_info_id.."\",\"resource_myinfo_id\":\""..resource_my_info_id.."\",\"resource_id_int\":\""..resource_id_int.."\"}")











