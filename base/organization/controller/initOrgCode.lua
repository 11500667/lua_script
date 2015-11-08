--初始化org_code by huyue 2015-07-29
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

local ok, err, errno, sqlstate = db:connect{
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

function updateOrg(org_id,orgCode)

local sql="update t_base_organization set org_code = '"..orgCode.."' where org_id="..org_id;
ngx.log(ngx.ERR,sql);

local res = db:query(sql);

end



function findOrgId(org_code, parentId, org_name, orgId,i)

	if parentId and parentId ~= 0 and parentId ~= -1 then

	local sql =  "select  org_id,parent_id,org_name from t_base_organization where org_id = "..parentId;

	local res = db:query(sql);

	--local org_code;
	--local orgId;
	local parentId;
	local org_name;

	if res and res[1] then 
		--org_code = res[1]["org_code"];
		org_id = res[1]["org_id"];
		org_code = org_id.."_"..org_code;
		
		parentId = res[1]["parent_id"];
		org_name = res[1]["org_name"];
	end
	findOrgId(org_code, parentId, org_name, orgId,i);

	else
		org_code = "_"..org_code.."_";
		updateOrg(orgId,org_code);

	end

end


local sql="select org_id,parent_id,org_name,org_type,area_id from t_base_organization order by org_id";

local res = db:query(sql);

for i=1,#res do

local org_type = res[i]["org_type"];
local area_id = res[i]["area_id"];
local org_id = res[i]["org_id"];
if tonumber(org_type) == 2 then
   local query_sql = "select org_id from t_base_organization where area_id="..area_id.." and org_type=1"
   
   ngx.log(ngx.ERR,query_sql);
   local query_res=  db:query(query_sql);
	   if query_res~=nil and query_res[1] ~=nil and query_res[1]["org_id"]~=nil then
		  local parent_id = query_res[1]["org_id"];
		   local update_sql="update t_base_organization set parent_id="..parent_id.." where org_id="..org_id;
		   db:query(update_sql);
	   
	   end
end


end

for i=1,#res do
	local orgId = res[i]["org_id"];
	local org_code = res[i]["org_code"];
	if org_code ==nil then
		org_code="";
	end
	org_code=org_code..orgId;
	local parentId = res[i]["parent_id"];
	local org_name = res[i]["org_name"];
	
	
	findOrgId(org_code, parentId, org_name, orgId,i);
	
end



local result = {} 

result["success"] = true
db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);

ngx.print(cjson.encode(result))




