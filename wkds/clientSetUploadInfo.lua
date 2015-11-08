#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-10
#描述：修改微课中正在上传资源个数的方法
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

 --连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--传参数
if args["jsonStr"] == nil or args["jsonStr"] == "" then
    ngx.say("{\"success\":false,\"info\":\"jsonStr参数错误！\"}")
    return
end
local jsonStr  = tostring(args["jsonStr"]);
ngx.log(ngx.ERR,"===================================================================="..jsonStr)
local cjson = require "cjson";
local jsonStr = cjson.decode(jsonStr);

local obj_id_int  = jsonStr.obj_id_int;

local add_list = jsonStr.add_upload_list;
local del_list = jsonStr.del_upload_list;
--获得type,1资源 2微课 3 备课包里面的资源 4 备课资源
local type_id;

local new_wkds_upload = "";

local add_str_new = "";
for i=1,#add_list do
	local add_map ={};
	add_map.file_id =  add_list[i]["file_id"];
	add_map.file_name =  add_list[i]["file_name"];
	add_map.upload_type =  add_list[i]["upload_type"];
	add_map.size =  add_list[i]["size"];
	ssdb_db:multi_hset("upload_res_"..add_list[i]["file_id"],add_map);
	add_str_new = add_str_new..",".."upload_res_"..add_list[i]["file_id"];
	type_id = add_list[i]["type"];
end


local add_str;

if type_id == "2" then
	add_str= ssdb_db:get("upload_wkds_"..obj_id_int);
 else
    add_str= ssdb_db:get("upload_bk_"..obj_id_int);
 end
 
add_str = tostring(add_str[1]);

if #add_str==0 and #add_list >0 then
  add_str_new = string.sub(add_str_new,2,#add_str_new);
end

add_str = add_str..add_str_new;
local add_upload = Split(add_str,",");
for j=1,#del_list do
      local file_id  = del_list[j]["file_id"];
	  ssdb_db:multi_del("upload_res_"..file_id);
	  for m=1,#add_upload do 
		 if m<=#add_upload  then
			 if "upload_res_"..file_id == add_upload[m] then
				 table.remove(add_upload,m);
				 ngx.log(ngx.ERR,"删除了一个");
			 end 
		 end
	  end
	  type_id = del_list[j]["type"];
end


 for n=1,#add_upload do 
    new_wkds_upload = new_wkds_upload..","..add_upload[n];
 end

if #del_list== 0 then
   new_wkds_upload = add_str;
else
   new_wkds_upload = string.sub(new_wkds_upload,2,#new_wkds_upload);
end
ngx.log(ngx.ERR,"===================================================================="..type_id)
if type_id =="3" then
    ngx.log(ngx.ERR,"------------------------".."upload_bk_"..obj_id_int.."--------------"..new_wkds_upload)
    ssdb_db:set("upload_bk_"..obj_id_int,new_wkds_upload);
else
	ssdb_db:set("upload_wkds_"..obj_id_int,new_wkds_upload);
end
local resultJson={};
resultJson.success = true;
local responseJson = cjson.encode(resultJson);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say(responseJson);
