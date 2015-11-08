ngx.log(ngx.ERR,"����ϵͳ��װ��λ����������Ա��ʼ��")
--��ȡ����
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
  args = ngx.req.get_uri_args();
else
  ngx.req.read_body();
  args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--bureau_id����
if args["bureau_id"] == nil or args["bureau_id"] == "" then
  ngx.print("{\"success\":false,\"info\":\"bureau_id��������\"}")
  return
end
local title = args["bureau_id"]
print(title)

-- ��ȡ���ݿ�����
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
  
  ngx.log(ngx.ERR, "=====> �������ݿ�ʧ��!");
  return;
end




local returnjson = {}
local res, err, errno, sqlstate = db:query("select province_id,city_id,district_id from t_base_organization where org_id = "..title..";")
ngx.log(ngx.ERR,"select province_id,city_id,district_id from t_base_organization where org_id = "..title..";")
if not res then
  
  ngx.log(ngx.ERR, "err: ".. err);
  return
end
local result = false
if res == nil then
  returnjson.success = false
  returnjson.info = "��ѯ���ݿ�ʧ��"
else
  local provinceId=res[1]["province_id"]
  local cityId=res[1]["city_id"]
  local districtId=res[1]["district_id"]

  local isqlprId = "INSERT INTO t_sys_config (id,name,value) VALUES ('3','provinceId',"..provinceId..");"
  local resprId, err, errno, sqlstate = db:query(isqlprId)
  if not resprId then
    
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end

  local isqlcyId = "INSERT INTO t_sys_config (id,name,value) VALUES ('4','cityId',"..cityId..");"
  local rescyId, err, errno, sqlstate = db:query(isqlcyId)
  if not rescyId then
    
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end

  local isqldsId = "INSERT INTO t_sys_config (id,name,value) VALUES ('5','districtId',"..districtId..");"
  local resdsId, err, errno, sqlstate = db:query(isqldsId)
  if not resdsId then
    
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end

  local isqlduId = "INSERT INTO t_sys_config (id,name,value) VALUES ('6','bureauId',"..title..");"
  local resduId, err, errno, sqlstate = db:query(isqlduId)
  if not resduId then
    
    ngx.log(ngx.ERR, "err: ".. err);
    return
  end
  returnjson.success = true
end


-- ��mysql���ӹ黹�����ӳ�
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
  ngx.log(ngx.ERR, "====>��Mysql���ݿ����ӹ黹���ӳس���");
end
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))








