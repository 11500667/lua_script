#将系统菜单去身份 by huyue 2015-07-11

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

local query_level_sql = "select max(level) level from t_sys_menu_new";

local query_level_res = mysql_db:query(query_level_sql);

local level = query_level_res[1]["level"];
local temp="";

for m=1,level do



	--查询所有重复的菜单
	local query_sql = "select  menu_id,menu_name,target_url, count(1)  as count from t_sys_menu  group by target_url,menu_name,level having count<>1 and level="..m.."  order by count desc";
	ngx.log(ngx.ERR,"menu_log----------->"..query_sql);

	local query_res = mysql_db:query(query_sql);

	for i=1,#query_res do
		local menu_name = query_res[i]["menu_name"];
		local target_url = query_res[i]["target_url"];
		--查询一组

		local sql1 = "select  menu_id,menu_name,target_url from t_sys_menu where  menu_name='"..menu_name.."' and target_url='"..target_url.."' and level ="..m;
		ngx.log(ngx.ERR,"menu_log----------->"..sql1);
		local query_res1 = mysql_db:query(sql1);
		
		for j =1,#query_res1 do 
			--重复的只留下第一个
			local menu_id_new = query_res1[1]["menu_id"];
			if j == 1 then 
			
			else 
				
				local menu_id = query_res1[j]["menu_id"];
				temp= temp..","..menu_id
				--将中间表的数据更新， 并且删除menu表中数据
				local sql2 = "update t_sys_role_menu set menu_id ="..menu_id_new.." where menu_id="..menu_id;
				ngx.log(ngx.ERR,"menu_log----------->"..sql2);
				local query_res2 = mysql_db:query(sql2);
				local sql4="update t_sys_menu set parent_id ="..menu_id_new.." where parent_id="..menu_id;
				local query_res4 = mysql_db:query(sql4);
				ngx.log(ngx.ERR,"menu_log----------->"..sql4);
				local sql3 = "delete from t_sys_menu where menu_id ="..menu_id;
				ngx.log(ngx.ERR,"menu_log----------->"..sql3);
				local query_res3 = mysql_db:query(sql3);

			end
		
		end
		
	end

end
--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["menu_id"] = temp

result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
