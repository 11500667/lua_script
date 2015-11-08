--[[
清除区域均衡的所有数据
@Author  chenxg
@Date    2015-03-12
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
ssdb:set_timeout(3000) --不设置也可以, 默认2000
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取mysql数据库连接
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
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end

--参数
local region_id = args["region_id"]
if not region_id or string.len(region_id) == 0 then
    say("{\"success\":false,\"info\":\"region_id参数错误！\"}")
    return
end

--======删除区域均衡信息开始=======
ssdb:hdel("qyjh_news_registid",region_id)
ssdb:hdel("qyjh_open",region_id)
ssdb:hdel("qyjh_qyjhs",region_id)
ssdb:hclear("qyjh_qyjh_tj_"..region_id)
ssdb:zclear("qyjh_org_uploadcount")
ssdb:zclear("qyjh_hd_uploadcount")
ssdb:zclear("qyjh_qyjh_tea_uploadcount_"..region_id)
ssdb:zclear("qyjh_qyjh_xzt_djl_"..region_id)
ssdb:zclear("qyjh_qyjh_org_uploadcount_"..region_id)
ssdb:zclear("qyjh_qyjh_dtrs_"..region_id)
ssdb:zclear("qyjh_qyjh_xzt_sort_"..region_id)
ssdb:zclear("qyjh_dxq_djl_"..region_id)
--======删除区域均衡信息结束=======================================


--======删除活动信息开始======
ssdb:zclear("qyjh_qyjh_hds_"..region_id.."_1")
ssdb:zclear("qyjh_qyjh_hds_"..region_id.."_2")
ssdb:zclear("qyjh_qyjh_hds_"..region_id.."_3")
ssdb:zclear("qyjh_qyjh_hds_"..region_id.."_4")
ssdb:zclear("qyjh_qyjh_hds_"..region_id.."_5")
ssdb:zclear("qyjh_qyjh_hds_"..region_id)
ssdb:hclear("qyjh_hd")
ssdb:zclear("qyjh_hd_pls")
--======删除活动信息结束======


--======删除协作体信息开始======
ssdb:hclear("qyjh_xzt_tj")
ssdb:hclear("qyjh_dxq_xzts")
ssdb:hclear("qyjh_xzt_teas")
ssdb:hclear("qyjh_xzt_org_teas")
ssdb:hclear("qyjh_tea_xzts")
ssdb:hclear("qyjh_xzt_manager")
ssdb:hclear("qyjh_manager_xzts")

local allxztids = ssdb:zrrange("qyjh_qyjh_xzts_"..region_id,0,100000)
if #allxztids>=2 then
	for i=1,#allxztids,2 do
		local xzt_id = allxztids[i]
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id)
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id.."_1")
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id.."_2")
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id.."_3")
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id.."_4")
		ssdb:zclear("qyjh_xzt_hds_"..xzt_id.."_5")
		ssdb:zclear("qyjh_xzt_tea_uploadcount_"..xzt_id)
	end
end
ssdb:hclear("qyjh_xzt")
ssdb:zclear("qyjh_qyjh_xzts_"..region_id)
--======删除协作体信息结束======

--======删除大学区信息开始======
ssdb:hclear("qyjh_dxq_tj")

ssdb:hclear("qyjh_dxq_manager")
ssdb:hclear("qyjh_manager_dxqs")
ssdb:hclear("qyjh_dxq_org_dtrs")
ssdb:hclear("qyjh_dxq_dtrs")
ssdb:hclear("qyjh_dtr_dxq")
ssdb:hclear("qyjh_org_dxq")

local alldxqids = ssdb:zrrange("qyjh_qyjh_dxqs_"..region_id,0,100000)
if #alldxqids>=2 then
	for i=1,#alldxqids,2 do
		local dxq_id = alldxqids[i]
		local dxq = ssdb:hget("qyjh_dxq",dxq_id)
		if not dxq and #dxq>0 then
			local temp = cjson.decode(dxq[1])
			ssdb:hclear("qyjh_tea_xzts_"..dxq_id)
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id)
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id.."_1")
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id.."_2")
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id.."_3")
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id.."_4")
			ssdb:zclear("qyjh_dxq_xzt_hds_"..dxq_id.."_5")

			ssdb:zclear("qyjh_dxq_hds_"..dxq_id)
			ssdb:zclear("qyjh_dxq_hds_"..dxq_id.."_1")
			ssdb:zclear("qyjh_dxq_hds_"..dxq_id.."_2")
			ssdb:zclear("qyjh_dxq_hds_"..dxq_id.."_3")
			ssdb:zclear("qyjh_dxq_hds_"..dxq_id.."_4")
			ssdb:zclear("qyjh_dxq_hds_"..dxq_id.."_5")
			
			ssdb:zclear("qyjh_dxq_org_uploadcount_"..dxq_id)
			ssdb:zclear("qyjh_dxq_xzt_djl_"..dxq_id)
			ssdb:zclear("qyjh_xzt_sort_"..dxq_id)
			ssdb:zclear("qyjh_dxq_tea_uploadcount_"..dxq_id)
			
			ssdb:hclear("qyjh_dxq_orgs_"..dxq_id)
			
			ssdb:zclear("qyjh_manager_dxqs_"..temp.person_id)
		end
	end
	ssdb:hclear("qyjh_dxq")
	ssdb:zclear("qyjh_qyjh_dxqs_"..region_id)
end
--======删除大学区信息结束======

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
say("{\"success\":\"true\",\"info\":\"删除区域均衡信息成功！\"}")