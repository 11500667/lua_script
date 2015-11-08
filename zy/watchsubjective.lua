--[[
学生查看自己的主观题
@Author chuzheng
@Date 2015-1-5
--]]
local say = ngx.say
local cjson = require "cjson"

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


local student_id = ngx.var.cookie_person_id
local zy_id = args["zy_id"]

if not zy_id or string.len(zy_id) == 0 then
         say("{\"success\":false,\"info\":\"参数错误！\"}")
         return
end
--引用模块
local ssdblib = require "resty.ssdb"
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local path,err = ssdb:hscan("homework_answersubjective_"..student_id.."_"..zy_id,"","",200)

if not path then
	say("{\"success\":false,\"info\":\"学生主观题查询失败！\"}")
end
local paths=""
if path[1]~="ok" then
	for j=1,#path,2 do
		if string.len(paths)==0 then
			paths=path[j]
		else
			paths=paths..","..path[j]
		end
	end
end
		
--改动* start 获得资源IDS组装资源的详细信息返回给页面
	local ids=""
	local json = {}
	local img_resource_ids = ssdb:hscan("zy_zg_answer_img"..student_id.."_"..zy_id,"","",200)
	local noimg_resource_ids = ssdb:hscan("zy_zg_answer_noimg"..student_id.."_"..zy_id,"","",200)
	--获得resoruce_ids res_id2id1,res_id2
	--获得资源list:[{iid:"223","resource_name":"张三"}{iid:"224","resource_name":"李四"}]
	if img_resource_ids[1]~="ok" then
		for i=1,#img_resource_ids,2 do 
			if string.len(ids) ==0 then
				ids=img_resource_ids[i+1]
			else
				ids=ids..","..img_resource_ids[i+1]
			end	
		end
	end
	
	if noimg_resource_ids[1]~="ok" then
		for i=1,#noimg_resource_ids,2 do 
			if string.len(ids) ==0 then
				ids=noimg_resource_ids[i]
			else
				ids=ids..","..noimg_resource_ids[i]
			end	
		end
	end
	local resource_ids={}
	local flag_1 = 1
	if img_resource_ids[1]~="ok" then
		--ngx.log(ngx.ERR, "------------------------------------img_resource_ids@："..#img_resource_ids.."：@------------------------------------")
		for j=1 ,#img_resource_ids,2 do 
			resource_ids[flag_1]= img_resource_ids[j+1]
			flag_1 = flag_1 + 1
		end
	end
	if noimg_resource_ids[1]~="ok" then
		--ngx.log(ngx.ERR, "------------------------------------img_resource_ids@："..#noimg_resource_ids.."：@------------------------------------")
		for i=1,#noimg_resource_ids,2 do 
			resource_ids[flag_1]= noimg_resource_ids[i]
			flag_1 = flag_1 + 1
		end
	end
	
	if string.len(ids)>0 then
        --ngx.log(ngx.ERR,"###############"..ids.."################");
		local zy_answer_res = ngx.location.capture("/dsideal_yy/resource/getResourceInfoByInfoId",{
			args={resource_info_ids=ids}
		})
		if zy_answer_res.status == 200 then
            ngx.log(ngx.ERR,"###############".. cjson.encode(zy_answer_res.body).."################");
			json = cjson.decode(zy_answer_res.body).list
			local flag = 1
			--ngx.log(ngx.ERR, "------------------------------------resource_ids@："..#resource_ids.."：@------------------------------------")
			for i=1,#resource_ids do
				json[flag]["resource_info_id"] = resource_ids[i]
				flag=flag+1
			end
		else
			say("{\"success\":false,\"info\":\"查询资源失败！\"}")
			return
		end
	else
		json={}	
	end
	cjson.encode_empty_table_as_object(false)
	local jsonData=cjson.encode(json)	
	say("{\"success\": \"true\",\"table_List\":"..jsonData.."}")
--改动* end 


--say("{\"success\":true,\"path\":\""..ngx.encode_base64(paths).."\"}")
ssdb:set_keepalive(0,v_pool_size)
