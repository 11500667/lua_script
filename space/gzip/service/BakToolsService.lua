--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/6
-- Time: 16:26
-- To change this template use File | Settings | File Templates.
-- 备课工具,通过解析前台模块的json串，取出备课工具中小模块的请求参数，然后请求模块中的数据进行压缩
-- 注意：（初步想法 登录与不登录共存于一个gzip文件） 目前备课工具有六个块

local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"
local cjson = require "cjson"
local baseService = require("space.gzip.service.BakToolsBaseService");
--local TableUtil = require("social.common.table")
local _M = {}

local function isLogin()
    local cookie_person_id = ngx.var.cookie_person_id
    local cookie_identity_id = ngx.var.cookie_identity_id
    log.debug("cookie 中是否有值.")
    log.debug(cookie_person_id)
    log.debug(cookie_identity_id)
    if cookie_person_id == nil or cookie_identity_id == nil then
        return false
    else
        return true;
    end
end

----- 我的云盘.
-- "self_setting" : {
-- "msg_num" : 10
-- },
local function my_yp_info(param, person_id, identity_id, login)
    log.debug("my_yp_info")
    local msg_num = param['msg_num']

    local is_Login = isLogin();

    if not is_Login then
        log.debug("重新设置cookie")
        ngx.header['Set-Cookie'] = { 'person_id=' .. person_id .. '; path=/', 'identity_id=' .. identity_id .. '; path=/' }
    end

    local data = ngx.location.capture("/dsideal_yy/ypt/cloud/getRootFileInfo?person_id=" .. person_id)
    local result_t = {}
    if data.status == 200 then
        local _data = cjson.decode(data.body)
        local structure_id = _data.fileRootId;
        local url = "/dsideal_yy/ypt/cloud/getResourceForYpList?mediatype=1&structureId=" .. structure_id .. "&is_root=1&upload_type=0&pageSize=" .. msg_num .. "&pageNumber=1&keyword=&sort_type=1&sort_num=2&is_cnode=0&view=0&stime=0&etime=&person_id=" .. person_id .. "&apply_type=1"
        local result = ngx.location.capture(url)
        if result.status == 200 then
            cjson.encode_empty_table_as_object(false)
            result_t = cjson.decode(result.body)
        end
    end

    if not is_Login then
        ngx.header['Set-Cookie'] = {}
    end
    return result_t;
end


--- 我的资源
-- "self_setting" : {
-- "stage_id" : "5",
-- "subject_id" : "6",
-- "stage_name" : "5Yid5Lit",
-- "subject_name" : "5pWw5a2m",
-- "scheme_id" : 23,
-- "isroot" : 1,
-- "nid": 6052,
-- "nname" : "5Lq65pWZ6K++5qCH5a6e6aqM54mI",
-- "msg_num" : 5
-- }

--url = url_path_action_login + "/space/getResourceMyList?res_type=1&bType=7&rtype=0&nid=" + settings.self_setting.nid +
--        "&is_root="+settings.self_setting.isroot+"&cnode=1&sort_type=1&sort_num=2&pageSize=" + settings.self_setting.msg_num +
--        "&pageNumber=1&scheme_id=" + settings.self_setting.scheme_id +
--        "&app_type_id=0&random_num=" + creatRandomNum()+"&person_id="+person_id+"&identity_id="+identity_id;
local function my_resource_info(param, person_id, identity_id, login)
    local scheme_id = param['scheme_id']
    local isroot = param['isroot']
    local nid = param['nid']
    local msg_num = param['msg_num']
    local bType;
    bType = (login == "0" and 7) or 0 --未登录是7 登录是0
    local url = "/dsideal_yy/space/getResourceMyList?res_type=1&bType=" .. bType .. "&rtype=0&nid=" .. nid ..
            "&is_root=" .. isroot .. "&cnode=1&sort_type=1&sort_num=2&pageSize=" .. msg_num ..
            "&pageNumber=1&scheme_id=" .. scheme_id .. "&app_type_id=0&person_id=" .. person_id .. "&identity_id=" .. identity_id;
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t
end

--- 我的试卷
local function my_paper_info(param, person_id, identity_id, login)
    log.debug("my_paper_info")
    local nid = param['nid']
    local msg_num = param['msg_num']
    local isroot = param['isroot']
    local scheme_id = param['scheme_id']
    local bType = (login == "0" and 7) or 0 --未登录是7 登录是0
    local url = "/dsideal_yy/space/getPaperMyList?paper_app_type=0&res_type=1&btype=" .. bType .. "&view=0&ptype=0&nid=" .. nid ..
            "&is_root=" .. isroot .. "&cnode=1&sort_type=3&sort_num=2&pageSize=" .. msg_num ..
            "&pageNumber=1&scheme_id=" .. scheme_id .. "&person_id=" .. person_id .. "&identity_id=" .. identity_id;
    log.debug(url);
    local data = ngx.location.capture(url)
    --    log.debug(data)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t
end

--- 我的备课
local function my_beike_info(param, person_id, identity_id, login)
    log.debug("my_beike_info")
    local nid = param['nid']
    local msg_num = param['msg_num']
    local isroot = param['isroot']
    local scheme_id = param['scheme_id']
    local bType = (login == "0" and 7) or 0 --未登录是7 登录是0
    local url = "/dsideal_yy/space/getResourceMyList?res_type=2&view=0&bType=" .. bType .. "&rtype=0&nid=" .. nid .. "&is_root=" .. isroot .. "&cnode=1&sort_type=1&sort_num=2&pageSize=" .. msg_num ..
            "&pageNumber=1&scheme_id=" .. scheme_id .. "&beike_type=0&app_type_id=0&person_id=" .. person_id .. "&identity_id=" .. identity_id;
    log.debug(url)
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t
end

--- 我的微课.
local function my_weike_info(param, person_id, identity_id, login)
    log.debug("my_weike_info start.")
    local nid = param['nid']
    local msg_num = param['msg_num']
    local isroot = param['isroot']
    local scheme_id = param['scheme_id']
    local bType = (login == "0" and 7) or 0 --未登录是7 登录是0
    local url;
    log.debug(param);
    if identity_id == "5" then
        url = "/dsideal_yy/space/getwkdslist?view=-1&nid=" .. nid ..
                "&is_root=" .. isroot .. "&cnode=1&sort_type=4&sort_order=2&pageSize=" .. msg_num ..
                "&pageNumber=1&keyword=&scheme_id=" .. scheme_id ..
                "&wkds_type=2&bType=" .. bType .. "&wk_type=0&person_id=" .. person_id .. "&identity_id=" .. identity_id;
    elseif identity_id == "6" then
        if not isLogin() then --如果没登录，设置cookie
            log.debug("重新设置cookie")
            ngx.header['Set-Cookie'] = { 'person_id=' .. person_id .. '; path=/', 'identity_id=' .. identity_id .. '; path=/' }
        end
        url = "/dsideal_yy/ypt/wkds/getPublishWk?nid=0&student_id=" .. person_id .. "&subject_id=0&is_root=0&cnode=0&sort_type=4&sort_order=2&pageSize=" .. msg_num .. "&pageNumber=1&keyword=&scheme_id=0&wk_type=0"
    end
    log.debug("weike info url = " .. url)
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t
end

--- 我的作业
local function homework(param, person_id, identity_id, login)
    log.debug(login)
    local is_Login = isLogin();
    if not is_Login then --没登录
        log.debug("重新设置cookie")
        ngx.header['Set-Cookie'] = { 'person_id=' .. person_id .. '; path=/', 'identity_id=' .. identity_id .. '; path=/' }
    end

    if identity_id == "5" then
        local url = "/dsideal_yy/ypt/zy/zylistteacher"
        local nid = param['nid']
        local scheme_id = param['scheme_id']
        local pageSize = param['this_num']
        local is_root = param['isroot']
        local keyword = ""
        url = url .. string.format("?nid=%s&scheme_id=%s&pageSize=%s&is_root=%s&keyword=%s&cnode=1&sort_order=2&pageNumber=1", nid, scheme_id, pageSize, is_root, keyword);
        log.debug("我的作业，老师请求url.");
        log.debug(url)
    elseif identity_id == "6" then
        local url = "/dsideal_yy/ypt/zy/zyliststudent"
        local pageSize = param['this_num']
        url = url .. string.format("?subject_id=-1&sort_order=2&pageNumber=1&pageSize=%s&keyword=&is_root=1&cnode=1&scheme_id=-1", pageSize);
        log.debug("我的作业，学生请求url.");
        log.debug(url)
    end
    log.debug("开始调用。");
    local data, e = ngx.location.capture(url)


    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    if not is_Login then
        ngx.header['Set-Cookie'] = { }
    end
    return result_t
end

--- 我的专题
local function studentZhuanti(param, person_id, identity_id, login)
    --    data:{"random_num":creatRandomNum(),
    --        "student_id": person_id,
    --        "record_count": 12
    --    },
    --    url : url_path_action_login + "/yxx/topic/topicstudentlist",
    local student_id = person_id;
    local record_count = param['record_count']
    local url = string.format("/dsideal_yy/yxx/topic/topicstudentlist?student_id=%s&record_count=%s", student_id, record_count);
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t;
end

--- 我的游戏
local function studentGames(param, person_id, identity_id, login)
    local student_id = person_id;
    local record_count = param['record_count']
    local url = string.format("/dsideal_yy/yxx/game/gamestudentlist?student_id=%s&record_count=%s", student_id, record_count);
    local data = ngx.location.capture(url)
    local result_t = {}
    if data.status == 200 then
        cjson.encode_empty_table_as_object(false)
        result_t = cjson.decode(data.body)
    end
    return result_t;
end

---

local function_table = {
    my_yp_info = my_yp_info, --我的云盘
    my_resource_info = my_resource_info, --我的资源
    my_paper_info = my_paper_info, --我的试卷
    my_beike_info = my_beike_info, --我的备课
    my_weike_info = my_weike_info, --我的微课
    homework = homework, --我的作业
    studentZhuanti = studentZhuanti, --我的专题
    studentGames = studentGames, --我的游戏.
}

local function hasKey(t, cmpKey)
    for k, _ in pairs(t) do
        if k == cmpKey then
            return true
        end
    end
    return false
end

--解析空间json
local function parseSpaceJsonAndRequestData(person_id, identity_id, login)
    local db = SsdbUtil:getDb()
    cjson.encode_empty_table_as_object(false)
    local json = db:get("space_info_" .. person_id .. "_" .. identity_id)
    --log.debug(json)
    local result = {}
    if json and json[1] and string.len(json[1]) > 0 then
        local jsonResult = cjson.decode(json[1])
        local setting_t = jsonResult['ALL_Setting']
        for k, _ in pairs(setting_t) do
            local _k = string.sub(k, 1, -7)
            log.debug(_k)
            local b = hasKey(function_table, _k); --判断是否有此key,如果没有此key跳 出循环.
            log.debug(b)
            repeat
                if not b then
                    break;
                end
                local status, _result = pcall(function_table[_k], setting_t[k]['self_setting'], person_id, identity_id, login);
                log.debug(status)
                if not status then
                    _result = { success = false, info = "请求数据失败." }
                else
                    _result.success = true
                end
                result[k] = _result
            until true
            --table.insert(result, { [k] = _result }) --返回json装载到table里面
        end
    end
    return result;
end


--压缩数据
local function zipData(result, file_name)
    local file = io.open("/usr/local/openresty/nginx/html/baktools/" .. file_name, "w")
    cjson.encode_empty_table_as_object(false)
    file:write(cjson.encode(result))
    file:close()
    os.execute("gzip -f -9 /usr/local/openresty/nginx/html/baktools/" .. file_name)
end

function _M.generateBakToolsJson(person_id, identity_id, login)

    local db = SsdbUtil:getDb()
    local ts = db:get("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_ts")[1]
    local last_ts = db:get("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_ts")[1];

    local nologin_ts = db:get("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_nologin_ts")[1]
    local nologin_last_ts = db:get("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_nologin_ts")[1];

    local file_name = "space_" .. person_id .. "_" .. identity_id .. "_data.json";
    local no_login_file_name = "space_" .. person_id .. "_" .. identity_id .. "_data_no_login.json";
    log.debug(ts)
    log.debug(last_ts)
    log.debug(nologin_ts)
    log.debug(nologin_last_ts)
    --or nologin_ts ~= nologin_last_ts
    if ts == nil or string.len(ts) == 0 or last_ts == nil or string.len(last_ts) == 0 or ts ~= last_ts then
        if login == "1" then
            local result = parseSpaceJsonAndRequestData(person_id, identity_id, login)
            zipData(result, file_name)
            local t1 = TS.getTs()
            db:set("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_ts", t1)
            db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_ts", t1)
        end
    else
        log.debug("登录，不需要重新生成.")
    end
    if nologin_ts == nil or string.len(nologin_ts) == 0 or nologin_last_ts == nil or string.len(nologin_last_ts) == 0 or nologin_ts ~= nologin_last_ts then
        if login == "0" then
            local result = parseSpaceJsonAndRequestData(person_id, identity_id, login)
            zipData(result, no_login_file_name)
            local t1 = TS.getTs()
            db:set("space_personid_" .. person_id .. "_identityid_" .. identity_id .. "_nologin_ts", t1)
            db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_nologin_ts", t1)
        end
    else
        log.debug("未登录，不需要重新生成.")
    end
end

return baseService:inherit(_M):init()