--[[
学科管理员游戏列表
@Author chuzheng
@data 2015-2-14
--]]
--应用json
--[[local cjson = require \"cjson\"
 --连接ssdb服务器
local ssdblib = require \"resty.ssdb\"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then        
	say("{\"success\":false,\"info\":\""..err.."\"}")        
	return
end

--连接mysql数据库
local mysql = require \"resty.mysql\"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--接受前台的参数
local request_method = ngx.var.request_method
local args = nil
if \"GET\" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--当前学生id
local person_id = ngx.var.cookie_person_id
--搜索关键字
local keyword = args["keyword"]
-- 学科id
local subjectid = args["subject_id"]
--第几页
local pageNumber = args["pageNumber"]
--一页显示多少
local pageSize = args["pageSize"]

--判断是否有第几页的参数
if not pageNumber or string.len(pageNumber)==0 then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")    
    return
end
if pageNumber == \"0\" then
    pageNumber = \"1\"
end

--判断是否有一页显示多少条的参数
if not pageSize or string.len(pageSize)==0 then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")    
    return
end

--游戏分类
local categoryid = args["categoryid"]
if not categoryid or string.len(categoryid)==0 then
	categoryid=""
else	
	categoryid="filter=GAME_CATEGORY_ID,"..categoryid..";"
end
--游戏适用范围
local applicationrange = args["applicationrange"]
if not applicationrange or string.len(applicationrange)==0 then
	applicationrange=""
else	
	applicationrange="filter=GAME_APPLICATIONRANGE_ID,"..applicationrange..";"
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100
--关键字处理
if not keyword or string.len(keyword)==0 then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= \"0\" then
        keyword = ngx.decode_base64(keyword)..";"
    else
		keyword = ""
    end
end

--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_order"])
--判断是否有排序的参数
if sort_num == \"nil\" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_order排序参数错误！\"}")
    return
end
--升序还是降序
local asc_desc = ""
if sort_num=="1\" then
    asc_desc = \"asc\"
else
    asc_desc = \"desc\"
end 

--排序内容
local sort_filed=args["sort_filed"]
local sortfiled = ""
if not sort_filed or string.len(sort_filed)==0 then
	ngx.say("{\"success\":\"false\",\"info\":\"sort_filed排序对象错误！\"}")
    return
else
	sortfiled = \"sort=attr_"..asc_desc..":"..sort_filed..";"
end


local game = ""
game = db:query("SELECT SQL_NO_CACHE id FROM t_game_info_sphinxse  WHERE query=\'"..keyword..categoryid..applicationrange..sortfiled.."filter=B_DELETE,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--status中截取总个数

local game1 = db:read_result()
local _,s_str = string.find(game1[1]["Status"],"found: ")
local e_str = string.find(game1[1]["Status"],", time:")
local totalRow = string.sub(game1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local pages={}

for i=1,#game do
	--ngx.say(game[i]["id"])
	local tab={}
	local gamecount =ssdb:multi_hget("yxx_game_info_"..game[i]["id"],"ID","GAME_NAME","CREATE_TIME","GAME_THUMB","GAME_TYPE","PLAYCOUNT")
	if not gamecount then
		say("{\"success\":flase,\"info\":\"查询作业内容失败！\"}")
        return
	end
	tab["id"]=gamecount[2]
	tab["gamename"]=gamecount[4]
	tab["createtime"]=gamecount[6]
	tab["gamethumb"]=gamecount[8]
	tab["gametype"]=gamecount[10]
	tab["playcount"]=gamecount[12]
	local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID\",
	{
		--body="id="..person_id
		args={id=person_id}
	})
	local person
	if student.status == 200 then
		person= cjson.decode(student.body).list
	else
		say("{\"success\":false,\"info\":\"查询班级失败！\"}")
		return
	end
	
	
	local count=ssdb:zcount("yxx_game_play_byclass_"..gamecount[2].."_"..person[1].classID,"","")
	tab["classcount"]=count[1]
	
	pages[i]=tab
end ]]
--local jsonData=cjson.encode(pages)
--[[ 						local pages={}
						for i=1,6 do
							local tab={}
							tab["game_id"]="110\"
							tab["game_name"]="王志铁swf游戏\"
							tab["game_type"]=1
							tab["person_number"]=0
							tab["classmate_number"]=40
							tab["game_upload_author"]="2014-12-01\"
							tab["type_id"]="1\"
							tab["is_two_dimension"]="1\"
							tab["game_url"]="game-test01.swf\"
							tab["game_image"]="img1.jpg\"
							pages[i]=tab
						end 
						local result={}
						result["success"]=true
						result["totalRow"]=6
						result["totalPage"]=1
						result["pageNumber"]=1
						result["pageSize"]=20
						result["list"]=pages
						cjson.encode_empty_table_as_object(false)
						local resultjson=cjson.encode(result)
						ngx.say(resultjson)
 ]]--[[ --mysql放回连接池
db:set_keepalive(0,v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size) ]]

--[[
@Author cuijinlong
@date 2015-4-24
--]]

--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
if args["subject_id"] == nil or args["subject_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"必要的参数subject_id不能为空！\"}");
	return;
end
local subject_id = args["subject_id"];
local game_name = args["game_name"];
local page_size = tonumber(args["page_size"]);
local page_number = tonumber(args["page_number"]);
local android_ios = args["android_ios"];
local type_id = args["game_type_id"];
local sort_type = args["sort_type"] and args["sort_type"] or "-1";
local sort_order = args["sort_order"] and args["sort_order"] or "-1";
local gameModel = require "yxx.game.model.GameModel";
--学生获得我的错题列表
local return_json = gameModel:game_list(subject_id,game_name,type_id,android_ios,sort_type,sort_order,page_size,page_number);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_json);
say(responseJson);