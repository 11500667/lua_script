--[[
删除协作体
@Author  chenxg
@Date    2015-01-19
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
local xzt_id = args["xzt_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
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
local hxzt = ssdb:hget("qyjh_xzt",xzt_id)
local xzt = cjson.decode(hxzt[1])
xzt.b_delete = 1

local ok, err = ssdb:hset("qyjh_xzt", xzt_id, cjson.encode(xzt))

if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--删除区域均衡和协作体的对应关系
local qyjh_xzts = ssdb:hget("qyjh_qyjh_xzts",xzt.qyjh_id)
local xztids = string.gsub(qyjh_xzts[1], ","..xzt_id..",", ",")

ngx.log(ngx.ERR, "===> qyjh_id ===>", xzt.qyjh_id, "===> xztids ===> ", xztids)
local result = ssdb:hset("qyjh_qyjh_xzts", xzt.qyjh_id, xztids)
local cjson_s = require "cjson"
ngx.log(ngx.ERR, "===> result  ===> ", cjson_s.encode(result));
--[[local ok, err = ssdb:hset("qyjh_qyjh_xzts", qyjh_id, xztids)
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end]]
--删除大学区和协作体的对应关系
local dxq_xzts = ssdb:hget("qyjh_dxq_xzts",xzt.dxq_id)
dxq_xzts[1] = string.gsub(dxq_xzts[1], ","..xzt_id..",", ",")
local ok, err = ssdb:hset("qyjh_dxq_xzts", xzt.dxq_id, dxq_xzts[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--删除协作体和管理员的对应关系
ssdb:hdel("qyjh_xzt_manager", xzt_id)
ssdb:hdel("qyjh_manager_xzts", xzt.person_id)
--删除协作体点击量
ssdb:zdel("qyjh_qyjh_xzt_djl_"..xzt.qyjh_id, xzt_id)
ssdb:zdel("qyjh_dxq_xzt_djl_"..xzt.dxq_id, xzt_id)


--存储区域均衡下协作体数量开始
--[[local xztcount = ssdb:hget("qyjh_qyjh_tj_"..xzt.qyjh_id,"xzt_tj")
xztcount = tonumber(xztcount[1])
ssdb:hset("qyjh_qyjh_tj_"..xzt.qyjh_id,"xzt_tj",xztcount-1)]]
ssdb:hincr("qyjh_qyjh_tj_"..xzt.qyjh_id,"xzt_tj", -1)
--存储区域均衡下协作体数量结束

--存储大学区下协作体数量开始
--[[local dxztcount = ssdb:hget("qyjh_dxq_tj_"..xzt.dxq_id,"xzt_tj")
dxztcount = tonumber(dxztcount[1])
ssdb:hset("qyjh_dxq_tj_"..xzt.dxq_id,"xzt_tj",dxztcount-1)]]
ssdb:hincr("qyjh_dxq_tj_"..xzt.dxq_id,"xzt_tj", -1)
--存储大学区下协作体数量结束
--存储大学区下协作体数量开始2015.02.02添加
--[[local dxztcount = ssdb:hget("qyjh_dxq_tj",xzt.dxq_id.."_".."xzt_tj")
dxztcount = tonumber(dxztcount[1])
ssdb:hset("qyjh_dxq_tj",xzt.dxq_id.."_".."xzt_tj",dxztcount-1)]]
ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_".."xzt_tj", -1)
--存储大学区下协作体数量结束

--删除协作体的统计信息开始
ssdb:hdel("qyjh_xzt_tj_"..xzt_id,"xx_tj")
ssdb:hdel("qyjh_xzt_tj_"..xzt_id,"js_tj")
ssdb:hdel("qyjh_xzt_tj_"..xzt_id,"zy_tj")
ssdb:hdel("qyjh_xzt_tj_"..xzt_id,"hd_tj")
--删除协作体的统计信息结束
--删除协作体的统计信息开始陈续刚2015.02.02添加
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."xx_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."js_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."zy_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."hd_tj")
--删除协作体的统计信息结束
--return
say("{\"success\":true,\"info\":\"协作体删除成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
