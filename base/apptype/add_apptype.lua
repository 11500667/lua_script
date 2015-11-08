#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

function PrimeNumberSet()
    local reverse = {} --以数据为key，数据在set中的位置为value
    local set = {};  
    --一个数组，其中的value就是要管理的数据
    return setmetatable(set,
    {__index = {
          insert = function(set,value)
              if not reverse[value] then
                    table.insert(set,value)
                    reverse[value] = table.getn(set)
              end
          end,

          remove = function(set,value)
              local index = reverse[value]
              if index then
                    reverse[value] = nil
                    local top = table.remove(set) --删除数组中最后一个元素
                    if top ~= value then
                        --若不是要删除的值，则替换它
                        reverse[top] = index
                        set[index] = top
                    end
              end
          end,

          find_value = function(set,value)
              local index = set[value]
             return index;
          end,

          find_key = function(set,value)
              local index = reverse[value]
             return index;
          end,
    }
  })
end

function getNewAppID(n)
    -- body
    local s = PrimeNumberSet()
    local tmp={2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97};
      for i =1,#tmp do
          s:insert(tmp[i]);
      end
      local key = s:find_key(n);
      ngx.log(ngx.ERR,"key="..key)
      local value = s:find_value(key+1);

    return value
end

--参数：scheme_id
if args["scheme_id"]==nil or args["scheme_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"1参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数scheme_id不能为空！");
    return
end
local scheme_id = tostring(args["scheme_id"]);

--参数：app_type_name
if args["app_type_name"]==nil or args["app_type_name"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数app_type_name不能为空！");
    return
end
local app_type_name = tostring(args["app_type_name"]);

--ngx.say("scheme_id"..scheme_id.."app_type_name"..app_type_name);

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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
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
local apptype_tab = {}; 
local  sel_scheme_sql = "SELECT SCHEME_ID_CHAR FROM T_RESOURCE_SCHEME WHERE SCHEME_ID = "..scheme_id;

-- 查询SCHEME_ID_CHAR记录
local results, err, errno, sqlstate = db:query(sel_scheme_sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end
local  scheme_id_char = results[1]["SCHEME_ID_CHAR"];
--ngx.log(ngx.ERR,"scheme_id_char"..results[1]["SCHEME_ID_CHAR"]);
local app_type_id = cache:incr("t_base_apptype_pk");
local max_prime_id_sql  = "SELECT MAX(APP_PRIME_ID) AS APP_PRIME_ID FROM T_BASE_APPTYPE WHERE SCHEME_ID = "..scheme_id;

local results_prime, err, errno, sqlstate = db:query(max_prime_id_sql);
if not results_prime then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local app_prime_id;
local max_prime_id = results_prime[1]["APP_PRIME_ID"];
ngx.log(ngx.ERR,"max_prime_id="..tostring(max_prime_id))
if tostring(max_prime_id) == "userdata: NULL" then
    app_prime_id =2 
else
    app_prime_id = getNewAppID(max_prime_id);
end



ngx.log(ngx.ERR,"app_prime_id============="..app_prime_id);
local insert_app_type = "INSERT INTO T_BASE_APPTYPE(APP_TYPE_ID,APP_PRIME_ID,APP_TYPE_NAME,SCHEME_ID,SCHEME_ID_CHAR,B_USE,TS) VALUES ("..app_type_id..","..app_prime_id..",'"..app_type_name.."',"..scheme_id..",'"..scheme_id_char.."',1,1111)";


--ngx.say("insert_app_type="..insert_app_type);
apptype_tab.app_type_name= app_type_name;
apptype_tab.scheme_id = scheme_id;
apptype_tab.scheme_id_char = scheme_id_char;
apptype_tab.b_use= b_use;
local res, err, errno, sqlstate =db:query(insert_app_type)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

-- 查询已经添加的媒体类型
local set_app = "SELECT APP_PRIME_ID,APP_TYPE_NAME FROM T_BASE_APPTYPE WHERE SCHEME_ID = "..scheme_id.." AND B_USE = 1 ORDER BY APP_PRIME_ID";
local ht_set_app = "SELECT APP_PRIME_ID,APP_TYPE_NAME,B_USE FROM T_BASE_APPTYPE WHERE SCHEME_ID = "..scheme_id.." ORDER BY APP_PRIME_ID";

local results, err, errno, sqlstate = db:query(set_app);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local ht_results, err, errno, sqlstate = db:query(ht_set_app);
if not ht_results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end


local app_type = {};
local ht_app_type = {};

local appids="";
for i=1,#results do
    local tab1 = {};
    tab1["app_type_id"] = results[i]["APP_PRIME_ID"];
     appids = appids..","..results[i]["APP_PRIME_ID"];
    tab1["app_type_name"] = results[i]["APP_TYPE_NAME"];
    app_type[i] = tab1;

end


for i=1,#ht_results do
    local ht_tab = {};
    ht_tab["app_type_id"] = ht_results[i]["APP_PRIME_ID"];
    ht_tab["app_type_name"] = ht_results[i]["APP_TYPE_NAME"];
    ht_tab["b_use"] = ht_results[i]["B_USE"];
    ht_app_type[i] = ht_tab;
end
    cache:set("appids_scheme_"..scheme_id,string.sub(appids,2,#appids));
    local jsonData = cjson.encode(app_type)
    cache:set("apptype_scheme_"..scheme_id,jsonData)


    local HtjsonData = cjson.encode(ht_app_type)
    cache:set("ht_apptype_scheme_"..scheme_id,HtjsonData)
    cache:hmset("t_base_apptype_"..scheme_id.."_"..app_prime_id,apptype_tab)

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
local ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--操作缓存
ngx.log(ngx.ERR,"{\"success\":true,\"info\":\"操作成功\"}");
 ngx.say("{\"success\":\"true\"}");  
