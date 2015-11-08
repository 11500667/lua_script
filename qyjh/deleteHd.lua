--[[
删除大学区
@Author  chenxg
@Date    2015-02-09
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
--参数 
local hd_id = args["hd_id"]

--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--存储详细信息
local hhd = ssdb:hget("qyjh_hd",hd_id)
local hd = cjson.decode(hhd[1])
hd.b_delete = 1
hd_type = hd.hd_type
qyjh_id = hd.qyjh_id

	local res_hd, err = ngx.location.capture("/deleteHDForGBT", {
		args = {hd_confid = hd.hd_confid}
	})
	if res_hd.status == 200 then
		--say("{\"success\":true,\"info\":\"连接高百特删除活动成功！\"}")
		--**************************
		local ok, err = ssdb:hset("qyjh_hd", hd_id, cjson.encode(hd))
		if not ok then
		   say("{\"success\":false,\"info\":\""..err.."\"}")
		   return
		else
			--删除活动相关联的信息
			--存储活动跟大学区对应关系信息
			if hd.page_type == "3" then 
				local hdxq = ssdb:hget("qyjh_dxq",hd.dxq_id)
				local dxq = cjson.decode(hdxq[1])
				path_id = hd.dxq_id
				
				ssdb:zdel("qyjh_dxq_hds_"..path_id,hd_id)
				ssdb:zdel("qyjh_dxq_hds_"..path_id.."_"..hd_type,hd_id)
				--大学区下活动数量
				ssdb:hincr("qyjh_dxq_tj_"..path_id,"hd_tj",-1)
				ssdb:hincr("qyjh_dxq_tj_"..path_id.."_"..hd_type,"hd_tj",-1)
			--存储活动跟协作体对应关系信息
			elseif hd.page_type == "4" then 
				local hxzt = ssdb:hget("qyjh_xzt",hd.xzt_id)
				local xzt = cjson.decode(hxzt[1])
				path_id = hd.xzt_id
				
				ssdb:zdel("qyjh_xzt_hds_"..path_id,hd_id)	
				ssdb:zdel("qyjh_xzt_hds_"..path_id.."_"..hd_type,hd_id)			
				--大学区活动数量-1
				ssdb:hincr("qyjh_dxq_tj_"..xzt.dxq_id,"hd_tj",-1)
				ssdb:hincr("qyjh_dxq_tj_"..xzt.dxq_id.."_"..hd_type,"hd_tj",-1)
				--协作体活动数量-1
				ssdb:hincr("qyjh_xzt_tj_"..path_id,"hd_tj",-1)
				ssdb:hincr("qyjh_xzt_tj_"..path_id.."_"..hd_type,"hd_tj",-1)
			end

			--(1)存储活动跟区域均衡对应关系信息
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id,hd_id)
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_"..hd_type,hd_id)
			--活动数量
			ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"hd_tj",-1)
			ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id.."_"..hd_type,"hd_tj",-1)
			
			say("{\"success\":true,\"info\":\"删除活动成功！\"}")
		end

		--**************************
	else
		say("{\"success\":false,\"info\":\"连接高百特删除活动失败！\"}")
		return
	end





--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
