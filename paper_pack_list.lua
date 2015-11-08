local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--第几页
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
--难度
local nd_id = tostring(ngx.var.arg_nd_id)
--判断是否有资源类型参数
if nd_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"难度参数错误！\"}")
    return
end
--题型
local qtype = tostring(ngx.var.arg_qtype)
--判断是否有资源类型参数
if qtype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"题型参数错误！\"}")
    return
end
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--搜索关键字
--local keyword = tostring(ngx.var.arg_keyword)
local keyword = tostring(args["keyword"])
--包ID
local pack_id = tostring(ngx.var.arg_pack_id)
--判断是否有资源类型参数
if pack_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pack_id参数错误！\"}")
    return
end

--拼难度的条件
local str_ndid = ""
if nd_id~="0" then
    str_ndid = " filter=question_difficult_id,"..nd_id..";"
end
--拼题型的条件
local str_qtype = ""
if qtype~="0" then
    str_qtype = " filter=question_type_id,"..qtype..";"
end
--关键字
if keyword=="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword~=0 then
        keyword = ngx.decode_base64(keyword)..";"
    else
        keyword = ""
    end
end
local str_pack = " filter=paper_id_int,"..pack_id..";"


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

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100

--ngx.say("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..str_ndid..str_qtype..str_pack.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local res = db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse WHERE query=\'"..keyword..str_ndid..str_qtype..str_pack.."filter=b_delete,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local question_info = ""
for i=1,#res do
    local question_json = tostring(cache:hmget("question_"..res[i]["id"],"json_question")[1])
    question_info = question_info.."{\"id\":\""..res[i]["id"].."\",\"json_question\":"..ngx.decode_base64(question_json).."},"
end
question_info = string.sub(question_info,0,#question_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")




