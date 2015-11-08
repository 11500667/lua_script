#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
  ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
  return
end

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end


--大赛id
if args["file_id"] == nil or args["file_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
  return
end
local file_id = args["file_id"]




local querysql = "select id,resource_id_int,resource_id_char,resource_title,resource_type_name,resource_format,resource_page,resource_size,resource_size_int,create_time,down_count,file_id,thumb_id,resource_type,structure_id,person_id,person_name,identity_id,group_id,preview_status,scheme_id_int,ts,thumb_status,update_ts,for_urlencoder_url,for_iso_url,width,height,parent_structure_name,release_status,res_type,bk_type,bk_type_name,material_type,m3u8_status,m3u8_url,app_type_id,stage_id,subject_id,view_count,from_kp from t_resource_info where file_id='"..file_id.."';"
local query, err, errno, sqlstate = db:query(querysql)
	ngx.log(ngx.ERR,querysql)
	if not query then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end




local returnjson = {}
returnjson.success = true
returnjson.id                   =query[1]["id"]                   
returnjson.resource_id_int      =query[1]["resource_id_int"]      
returnjson.resource_id_char     =query[1]["resource_id_char"]     
returnjson.resource_title       =query[1]["resource_title"]       
returnjson.resource_type_name   =query[1]["resource_type_name"]   
returnjson.resource_format      =query[1]["resource_format"]      
returnjson.resource_page        =query[1]["resource_page"]        
returnjson.resource_size        =query[1]["resource_size"]        
returnjson.resource_size_int    =query[1]["resource_size_int"]    
returnjson.create_time          =query[1]["create_time"]          
returnjson.down_count           =query[1]["down_count"]           
returnjson.file_id              =query[1]["file_id"]              
returnjson.thumb_id             =query[1]["thumb_id"]             
returnjson.resource_type        =query[1]["resource_type"]        
returnjson.structure_id         =query[1]["structure_id"]         
returnjson.person_id            =query[1]["person_id"]            
returnjson.person_name          =query[1]["person_name"]          
returnjson.identity_id          =query[1]["identity_id"]          
returnjson.group_id             =query[1]["group_id"]             
returnjson.preview_status       =query[1]["preview_status"]       
returnjson.scheme_id_int        =query[1]["scheme_id_int"]        
returnjson.ts                   =query[1]["ts"]                   
returnjson.thumb_status         =query[1]["thumb_status"]         
returnjson.update_ts            =query[1]["update_ts"]            
returnjson.for_urlencoder_url   =query[1]["for_urlencoder_url"]   
returnjson.for_iso_url          =query[1]["for_iso_url"]          
returnjson.width                =query[1]["width"]                
returnjson.height               =query[1]["height"]               
returnjson.parent_structure_name=query[1]["parent_structure_name"]
returnjson.release_status       =query[1]["release_status"]       
returnjson.res_type             =query[1]["res_type"]             
returnjson.bk_type              =query[1]["bk_type"]              
returnjson.bk_type_name         =query[1]["bk_type_name"]         
returnjson.material_type        =query[1]["material_type"]        
returnjson.m3u8_status          =query[1]["m3u8_status"]          
returnjson.m3u8_url             =query[1]["m3u8_url"]             
returnjson.app_type_id          =query[1]["app_type_id"]          
returnjson.stage_id             =query[1]["stage_id"]             
returnjson.subject_id           =query[1]["subject_id"]           
returnjson.view_count           =query[1]["view_count"]           
returnjson.from_kp              =query[1]["from_kp"]              
cjson.encode_empty_table_as_object(false)
db: set_keepalive(0, v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))

ngx.print(cjson.encode(returnjson))








