--[[
@Author chuzheng
@date 2014-12-23
--]]
local say = ngx.say
local cjson = require "cjson"
--引用模块
local ssdblib = require "resty.ssdb"

--获取前台传过来的参数
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

local zy_id = args["zy_id"]

if not zy_id or string.len(zy_id) == 0  then
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

--查询作业信息


local zycontent=ssdb:hget("homework_zy_content",zy_id)
if  not  zycontent then
	say("{\"success\":false,\"info\":\"作业查询失败！\"}")
	return
end
if string.len(zycontent[1])>0 then
	local zycon=cjson.decode(zycontent[1])


	if zycon.paper_list and (zycon.paper_list)[1] then 
		
		if (zycon.paper_list)[1].paper_source and (zycon.paper_list)[1].paper_source=="2" then
			
			 local id  = (zycon.paper_list)[1].iid
        		 paper_type = (zycon.paper_list)[1].paper_type
			

                         local papers=ngx.location.capture("/dsideal_yy/ypt/paper/getInfoByPaperId",
                         {
                                 args={id=id,paper_type=paper_type}
                         })
                         local paper
                         if papers.status == 200 then
                                 paper = cjson.decode(papers.body)
                                 --paper[1]["paper_type"]=paper_type
                         else
                                 ngx.say("{\"success\":false,\"info\":\"查询试卷信息失败\"}")
                                 return
                         end
        		 paper["paper_file_id"]=paper.file_id
			 paper["paper_type"]=paper_type
        		 local tab={}
        		 tab[1]=paper
        		 zycon.paper_list=tab
			
		end
	end

	say(cjson.encode(zycon))
else
	say("{\"success\":false,\"info\":\"作业查询失败！\"}") 
end

ssdb:set_keepalive(0,v_pool_size)
