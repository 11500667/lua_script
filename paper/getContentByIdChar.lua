local paper_id_char = getParamByName("paper_id_char");
if paper_id_char == nil or paper_id_char == "" then
    ngx.say("{\"success\":false,\"info\":\"paper_id_char不能为空\"}")
    return
end


local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

--����redis������
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cacheUtil = require "common.CacheUtil";

local function getOptionCountByInfoId(infoId)
    --ngx.log(ngx.ERR, "######### [infoId] - > ", infoId);
    local jsonQuesBase64 = cache: hget("question_" .. infoId, "json_question");
    if string.isBlank(jsonQuesBase64) then
        return 0; 
    end
    local jsonQuesStr    = ngx.decode_base64(jsonQuesBase64);
    local jsonQuesObj    = cjson.decode(jsonQuesStr);
    --ngx.log(ngx.ERR,"#########2"..jsonQuesObj.option_count.."########");
    local optionCount    = jsonQuesObj.option_count;
    if optionCount == nil or optionCount == "" then
        return 0;
    end

    return tonumber(optionCount);
end

local res = {}
local list1 = {};
local list = {};

local result = {}
result.success = true;

--���paper_id_charȥ�����л��json_content�Ծ����ϸ��Ϣ
local redis_paper = cache:hget("paperinfo_"..paper_id_char,"json_content");

local json_content = redis_paper;
--json_content = ngx.decode_base64(json_content);

if  json_content == ngx.null then
    ngx.say("{\"success\":false,\"info\":\"试卷的数据不正确\"}")    
    return
else
    -- ngx.log(ngx.ERR,"-------------------"..json_content)
    -- ngx.log(ngx.ERR,ngx.decode_base64(json_content));
    local data = cjson.decode(ngx.decode_base64(json_content));
    local subjectId     = data["subject_id"];
    local quesTypeArray = data["tx"];
    local quesList      = data["ti"];

    -- 用来存储题型与客观主观题之间关系的HASH
    local kgZgHash  = {};
    for index, quesType in ipairs(quesTypeArray) do
        local quesTypeId = tonumber(quesType["qt_id"]);
        -- ngx.log(ngx.ERR, "[sj_log] -> [getContentByIdChar] -> type of quesTypeId : [", type(quesTypeId), "]");
        local isKgZg = cacheUtil: hget("qt_list_" .. subjectId .. "_" .. quesTypeId, "qt_type");

        kgZgHash[quesTypeId] = isKgZg;
    end

    local kgQuesList = {};
    local zgQuesList = {};
    for index, question in ipairs(quesList) do
        local infoId = question["id"];
        local fileId = question["t_id"];
        local qtId   = tonumber(question["qt_id"]);
        local kgZg   = kgZgHash[qtId];
        local optionCount = getOptionCountByInfoId(infoId);

        local tempQuesObj = {};
        tempQuesObj["id"]           = infoId;
        tempQuesObj["t_id"]         = fileId;
        tempQuesObj["qt_id"]        = qtId;
        tempQuesObj["option_count"] = optionCount;
        -- ngx.log(ngx.ERR, "[sj_log] -> [getContentByIdChar] -> tonumber(kgZg) == 1 -> [", (tonumber(kgZg) == 1),"], kgZg -> [", kgZg, "], type of qtId : [", type(qtId), "]");
        if tonumber(kgZg) == 1 then -- 1客观题， 2主观题
            table.insert(kgQuesList, tempQuesObj);
        else
            table.insert(zgQuesList, tempQuesObj);
        end
    end

    result["objective"]  = kgQuesList;
    result["subjective"] = zgQuesList;

    --[[
    local m = 0;
    local n = 0;
    if #data.ti ~= 0 then
        if #data.tx ~= 0 then
            for j=1,#data.ti do

                local qt_id = tonumber(data.ti[j].qt_id)
                --ngx.log(ngx.ERR,"qt_id"..qt_id)

                for i=1,#data.tx do 

                    local qt_id2 = tonumber(data.tx[i].qt_id)
                    local oneortwo = data.tx[i].oneortwo
                    --ngx.log(ngx.ERR,"-------------------"..qt_id2)
                    --ngx.log(ngx.ERR,"======================"..oneortwo)
                    if qt_id2==qt_id then
                        if oneortwo == "1" and qt_id ~= 14 and qt_id ~= 6 then
                            local tab = {};
                            n = n+1;
                            local id = data.ti[j].id
                            local t_id = data.ti[j].t_id
                            tab.id =id ;
                            tab.t_id = t_id;

                            tab.qt_id=qt_id;
                            -- subjective.oneortwo = oneortwo
                            local optionCount = getOptionCountByInfoId(id);
                            tab.option_count = optionCount;
                            list1[n] = tab
                        else

                            local tab = {};
                            m = m+1;

                            local id = data.ti[j].id

                            --ngx.log(ngx.ERR,"===========================id"..id)

                            local t_id = data.ti[j].t_id

                            --ngx.log(ngx.ERR,"========================t_id"..t_id)

                            tab.id =id ;
                            tab.t_id = t_id;
                            tab.qt_id=qt_id;
                            local optionCount = getOptionCountByInfoId(id);
                            tab.option_count = optionCount;

                            list[m] = tab

                        end
                        break 
                    end
                end

            end   
        end
    end
    ]]
end


--ngx.log(ngx.ERR,"objective========"..#objective);


--[[ local result = {}
result.success = true;
--ngx.log(ngx.ERR,"objective========"..#objective);
result["objective"] =list1;
result["subjective"] = list;]]


-- ��redis���ӹ黹�����ӳ�
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

ngx.print(cjson.encode(result));























