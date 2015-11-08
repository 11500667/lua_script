--[[
格式化试卷信息
@Author chuzheng
@data 2015-2-3
-]]

--引用json
local cjson = require "cjson"

--接受前台的参数
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取试卷id
local paper_id_char = args["paper_id_char"]
--判断参数是否为空
if not paper_id_char or string.len(paper_id_char)==0 then
    ngx.say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--调用基础数据接口获取所有的题


local papers=ngx.location.capture("/dsideal_yy/ypt/paper/getContentByIdChar",
    {
        body="paper_id_char="..paper_id_char
        --args={paper_id_char=paper_id_char}
    })
local paper
if papers.status == 200 then
    paper = cjson.decode(papers.body)
    --paper[1]["paper_type"]=paper_type
else
    ngx.say("{\"success\":false,\"info\":\"查询试卷信息失败\"}")
    return
end
local n=1
local tabs={}
--ngx.say(cjson.encode(paper))
if table.getn(paper.subjective)>0 then
    for i=1,#(paper.subjective) do
        local tab={}
        tab["question_type_id"]=(paper.subjective)[i].qt_id
        tab["file_id"]=(paper.subjective)[i].t_id
        tab["sort_id"]=n
        tab["kg_zg"]="2"
        --tab["question_id_char"]=(paper.subjective)[i].id
        --	ngx.say((paper.subjective)[i].id)
        --调用基础数据接口获取答案
        --local papers=ngx.location.capture("/dsideal_yy/ypt/paper/getAnswerById",
        --{
        --args={id=(paper.subjective)[i].id}
        --body="id="..(paper.subjective)[i].id
        --})
        --local answer
        --if papers.status == 200 then
        --answer = cjson.decode(papers.body)
        --else
        --ngx.say("{\"success\":false,\"info\":\"读取题的答案失败！\"}")
        --return
        --end
        tab["question_answer"]=""--ngx.encode_base64(answer.answer)
        --tab["question_id_char"]=answer.question_id_char
        tab["question_id_char"]=(paper.subjective)[i].id
        tab["option_count"]=(paper.subjective)[i].option_count
        tabs[n]=tab
        n=n+1

    end
end
if table.getn(paper.objective)>0 then
    for i=1,#(paper.objective) do
        local tab={}
        tab["question_type_id"]=(paper.objective)[i].qt_id
        tab["file_id"]=(paper.objective)[i].t_id
        -- ngx.log(ngx.ERR,"#########1"..(paper.subjective)[i].option_count.."########");
        tab["option_count"]=(paper.objective)[i].option_count
        tab["sort_id"]=n
        tab["kg_zg"]="1"
        tab["question_id_char"]=(paper.objective)[i].id
        --调用基础数据接口获取答案
        local papers=ngx.location.capture("/dsideal_yy/ypt/paper/getAnswerById",
            {
                --args={id=(paper.objective)[i].id}
                body="id="..(paper.objective)[i].id
            })
        local answer
        if papers.status == 200 then
            answer = cjson.decode(papers.body)
        else
            ngx.say("{\"success\":false,\"info\":\"读取题的答案失败！\"}")
            return
        end
        tab["question_answer"]=ngx.encode_base64(answer.answer)
        --tab["question_id_char"]=answer.question_id_char

        tabs[n]=tab
        n=n+1

    end
end


cjson.encode_empty_table_as_object(false)
local result={}
result["success"]=true
result["table_List"]=tabs

local resultjson=cjson.encode(result)


ngx.say(resultjson)


