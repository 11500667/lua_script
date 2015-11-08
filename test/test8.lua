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

local cjson = require "cjson"
local TS = require "resty.TS"

ngx.say(TS.getTs())


local province_tab = {}
local province_res= db:query("select id,provincename from t_gov_province")
for i=1,#province_res do
	local province = {}
	local province_id = province_res[i]["id"]
	local province_name = province_res[i]["provincename"]
	
	local city_tab = {}	
	local city_res= db:query("select id,cityname from t_gov_city where provinceid='"..province_id.."'")	
	for j=1,#city_res do
		local city = {}
		local city_id = city_res[j]["id"]
		local city_name = city_res[j]["cityname"]					
		local district_tab = {}
		local district_res= db:query("select id,districtname from t_gov_district where cityid='"..city_id.."'")
		for k=1,#district_res do
			local district = {}
			local district_id = district_res[k]["id"]
			local district_name = district_res[k]["districtname"]
			district["area_id"] = district_id
			district["area_name"] = district_name
			district_tab[k] = district
		end		
		city["city_id"] = city_id
		city["city_name"] = city_name
		city["area"] = district_tab
		city_tab[j] = city
	end
	province["province_id"] = province_id
	province["province_name"] = province_name
	province["city"] = city_tab
	province_tab[i] = province
end

local reslut = {}

reslut["province"] = province_tab

--ngx.print(cjson.encode(reslut))


local test = {}

test.success  = true
test.id = "1"
test.name = "a"
test["age"] = "18"
ngx.print(cjson.encode(test))

