--[[
查看作业内容
@Author chuzheng
@date 2014-12-30
--]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获取前台传过来的参数
local request_method = ngx.var.request_method
local args, err
if request_method == "GET" then
    args, err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args, err = ngx.req.get_post_args()
end

if not args then
    say("{\"success\":false,\"info\":\"" .. err .. "\"}")
    return
end


local zy_id = args["zy_id"]
--主观题是0，客观题是1，非格式化试卷是2，资源是3
local query_type = args["query_type"]
--传学生id 有的话就是老师的接口了
if not zy_id or string.len(zy_id) == 0 or not query_type or string.len(query_type) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\"" .. err .. "\"}")
    return
end

--取ssdb中作业的信息
local str = ssdb:hget("homework_zy_content", zy_id)
if string.len(str[1]) == 0 then
    say("{\"success\":false,\"info\":\"读取作业信息失败！\"}")
    return
end

local param = cjson.decode(str[1])

local json = ""
--主观题
if query_type == "0" then
    json = param.zg
end
--客观题
if query_type == "1" then
    json = param.kg
end
--非格式化试卷
if query_type == "2" then
    local id = (param.fgsh)[1].iid
    local paper_type = (param.fgsh)[1].paper_type
    local papers = ngx.location.capture("/dsideal_yy/ypt/paper/getInfoByPaperId",
        {
            args = { id = id, paper_type = paper_type }
        })
    local paper
    if papers.status == 200 then
        paper = cjson.decode(papers.body)
    else
        ngx.say("{\"success\":false,\"info\":\"查询试卷信息失败\"}")
        return
    end
    paper["paper_file_id"] = paper.file_id
    local tab = {}
    tab[1] = paper
    json = tab
    --say(cjson.encode(paper))
end
--资源
if query_type == "3" then
    zy = param.zy_fj_list
    local zyids = ""
    for i = 1, #zy do
        if string.len(zyids) == 0 then
            zyids = zy[i].iid
        else
            zyids = zyids .. "," .. zy[i].iid
        end
    end
    --ngx.log(ngx.ERR,"###############"..zyids);
    if string.len(zyids) > 0 then
        local zys = ngx.location.capture("/dsideal_yy/resource/getResourceInfoByInfoId", {
            --body="resource_info_ids="..zyids
            args = { resource_info_ids = zyids }
        })

        if zys.status == 200 then
            json = cjson.decode(zys.body).list
        else
            say("{\"success\":false,\"info\":\"查询资源失败！\"}")
            return
        end
    else
        json = {}
    end
end
cjson.encode_empty_table_as_object(false)
local jsonData = cjson.encode(json)
say("{\"success\": \"true\",\"zy_content\": \"" .. param.zy_content .. "\",\"zy_name\":\"" .. param.zy_name .. "\",\"is_download\":\"" .. param.is_download .. "\",\"is_look_answer\":\"" .. param.is_look_answer .. "\",\"table_List\":" .. jsonData .. "}")
ssdb:set_keepalive(0, v_pool_size)
