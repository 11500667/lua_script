--保存菜单权限 by huyue 2015-07-31

--1.获得参数方法
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
cjson.encode_empty_table_as_object(false);
-- 获取数据库连接
local mysql = require "resty.mysql";
local mysql_db, err = mysql : new();
if not mysql_db then
  ngx.log(ngx.ERR, err);
  return;
end

mysql_db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = mysql_db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }
 
  
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

if args["role_id"] == nil or args["role_id"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"role_id参数错误！\"}");
  return;
end
local role_id = args["role_id"];

local menu_id_new = tostring(args["menu_id_new"]); 
if args["menu_id_new"] == nil or args["menu_id_new"] == "" then
	menu_id_new="";
end


	
local menu_id_new_tab= Split(menu_id_new,",");



local query_menu_old_sql="select MENU_ID from  t_sys_role_menu where role_id="..role_id;
ngx.log(ngx.ERR,"hy_log-------->查询角色菜单"..query_menu_old_sql);

local query_menu_old_res=mysql_db:query(query_menu_old_sql);

local menu_id_old_tab={};
for i=1,#query_menu_old_res do 
	--local res={};
	--res["MENU_ID"]=query_menu_old_res[i]["MENU_ID"];
	menu_id_old_tab[i]=query_menu_old_res[i]["MENU_ID"];
end


local addMenuId = Split(menu_id_new,",");

local delMenuId=menu_id_old_tab;


local add_remove={};
for i, v in ipairs(addMenuId) do
  for j, value in ipairs(menu_id_old_tab) do

      if tonumber(v)  == tonumber(value) then

      add_remove[tostring(v)]=true;
 
      end
  end

end


local i = 1
while i <= #addMenuId do
  if add_remove[tostring(addMenuId[i])] then

    table.remove(addMenuId, i)
  else
    i = i + 1
  end
end



local del_remove={};

for i, v in ipairs(delMenuId) do
  for j, value in ipairs(menu_id_new_tab) do
    --  ngx.log(ngx.ERR,v.."-----"..value);
      if tonumber(v)  == tonumber(value) then
      del_remove[tostring(v)]=true;
      end
  end

end

local j = 1
while j <= #delMenuId do
  if del_remove[tostring(delMenuId[j])] then

    table.remove(delMenuId, j)
  else
    j = j + 1
  end
end

for m=1,#addMenuId do
	local insert_sql = "insert into t_sys_role_menu set role_id="..role_id..",menu_id="..addMenuId[m];
	ngx.log(ngx.ERR,"hy_log插入角色权限"..insert_sql);
	mysql_db:query(insert_sql);
end

for m=1,#delMenuId do
	local del_sql = "delete from t_sys_role_menu where role_id="..role_id.." and menu_id="..delMenuId[m];
	ngx.log(ngx.ERR,"hy_log删除角色权限"..del_sql);
	mysql_db:query(del_sql);
end


--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
