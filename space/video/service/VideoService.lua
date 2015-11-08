local DBUtil = require "common.DBUtil";
local TableUtil = require("social.common.table")
local log = require("social.common.log")
local RedisUtil = require("social.common.redisutil")
local SsdbUtil = require("social.common.ssdbutil")
local util = require("social.common.util")
local quote = ngx.quote_sql_str
local _M = {}

--------------------------------------------------------------------
local function checkParamIsNull(t)
    for key, var in pairs(t) do
        if var == nil or string.len(var) == 0 then
            error(key .. " 不能为空.")
        end
    end
end

---------------------------------------------------------------
-- 创建视频文件夹
-- Person_id：用户id
-- Identity_id：身份id
-- Folder_name：文件夹名称
-- Is_private：0公有,1私有
function _M.createVideoFolder(personId, identityId, folderName, isPrivate, isDefault)

    checkParamIsNull({
        personId = personId,
        identityId = identityId,
        folderName = folderName,
        isPrivate = isPrivate
    })
    if isDefault == nil or string.len(isDefault) == 0 then
        isDefault = 0
    end
    local sql = "INSERT INTO T_SOCIAL_VIDEO_FOLDER(PERSON_ID, IDENTITY_ID, FOLDER_NAME, CREATE_TIME,  IS_PRIVATE, IS_DEFAULT,VIDEO_NUM) VALUES (" ..
            personId .. "," .. identityId .. "," .. quote(folderName) .. ",now()," .. isPrivate .. "," .. isDefault .. "," .. "0)"
    local result = DBUtil:querySingleSql(sql);
    return result
end

---------------------------------------------------------------
-- 编辑视频文件夹
-- @param #string Folder_id：文件夹id
-- @param #string Folder_name：文件夹名称
-- @param #string Is_private：0公有,1私有
function _M.editVideoFolder(folderName, isPrivate, folderId)

    checkParamIsNull({
        folderId = folderId,
        folderName = folderName,
        isPrivate = isPrivate
    })
    local sql = "UPDATE T_SOCIAL_VIDEO_FOLDER SET FOLDER_NAME = " .. quote(folderName) .. ",IS_PRIVATE = " .. quote(isPrivate) ..
            " WHERE ID = " .. folderId
    local result = DBUtil:querySingleSql(sql);
    return result
end

----------------------------------------------------------------
-- 通过id获取文件夹信息.
function _M.getVideoFolderById(folderId)
    checkParamIsNull({
        folderId = folderId
    })
    local sql = "SELECT * FROM T_SOCIAL_VIDEO_FOLDER T WHERE ID = " .. quote(folderId)
    local result = DBUtil:querySingleSql(sql);
    return result
end

----------------------------------------------------------------
-- 删除视频文件夹 1
-- Folder_id：文件夹id
function _M.deleteVideoFolder(folderId)
    checkParamIsNull({
        folderId = folderId
    })
    local db = DBUtil:getDb();
    local dsql = "UPDATE T_SOCIAL_VIDEO SET IS_DELETE=1 WHERE FOLDER_ID = " .. quote(folderId)
    local dresutl, err = db:query(dsql)
    if dresutl then
        local dsql1 = "UPDATE T_SOCIAL_VIDEO_FOLDER SET IS_DELETE=1 WHERE ID = " .. quote(folderId)
        local dresutl1, err = db:query(dsql1)
        if dresutl1 then
            return true;
        end
    end
    return false;
end

-----------------------------------------------------------------
-- 获取视频文件列表.
-- @param #string Person_id：用户id
-- @param #string Identity_id：身份id
-- @param #string Is_private：0公有,1私有,不传查所有
function _M.getVideoFolder(personId, identityId, isPrivate)
    checkParamIsNull({
        personId = personId,
        identityId = identityId
    })
    --    if isPrivate == nil or string.len(isPrivate) == 0 then
    --        error("isPrivate 不能为空.")
    --    end
    local sql = "SELECT * FROM T_SOCIAL_VIDEO_FOLDER t WHERE PERSON_ID = " .. quote(personId) .. " AND IDENTITY_ID = " .. quote(identityId) .. " AND IS_DELETE=0"
    if isPrivate and string.len(isPrivate) > 0 then
        sql = sql .. " AND IS_PRIVATE = " .. tonumber(isPrivate)
    end
    sql = sql .. " ORDER BY CREATE_TIME ASC"
    log.debug("获取视频文件列表.sql:" .. sql)
    local result = DBUtil:querySingleSql(sql);
    log.debug(result);
    return result;
end

-----------------------------------------------------------------
-- 通过id获取文件夹信息.
-- @param #string folder_id：文件夹id
function _M.getFolderById(id)

    checkParamIsNull({
        id = id
    })
    local sql = "SELECT * FROM T_SOCIAL_VIDEO_FOLDER t WHERE id = " .. quote(id)
    local result = DBUtil:querySingleSql(sql);
    return result;
end

-----------------------------------------------------------------
-- 创建视频文件.
-- @param #string Person_id：用户id
-- @param #string Identity_id：身份id
-- @param #string Folder_id：文件夹id
-- @param #string video_name：视频名称
-- @param #string file_id：file_id加扩展名
-- @param #string file_size：视频大小
-- @param #string description：视频说明描述
function _M.createVideo(personId, identityId, folderId, videoName, fileId, fileSize, description, resourceId)
    checkParamIsNull({
        personId = personId,
        identityId = identityId,
        folderId = folderId,
        videoName = videoName,
        fileId = fileId,
        fileSize = fileSize,
        resourceId = resourceId
    })
    if description == nil or string.len(description) == 0 then
        --error("description 不能为空.")
        description = ""
    end

    -- local resourceId = "" --调用平台接口，保存资源信息，然后返回 resourceid.
    local sql = "INSERT INTO  t_social_video (person_id,identity_id,folder_id,video_name,file_id,file_size,description,resource_id)"
    local value = " values(" .. personId .. "," .. identityId .. "," .. folderId .. "," .. quote(videoName) .. "," .. quote(fileId) .. "," .. fileSize .. "," .. quote(description) .. "," .. resourceId .. ")"
    sql = sql .. value;
    log.debug(sql)
    local db = DBUtil:getDb();
    local result = db:query(sql);
    --照片数加1
    local usql = "UPDATE T_SOCIAL_VIDEO_FOLDER SET VIDEO_NUM = VIDEO_NUM + 1 WHERE ID = " .. quote(folderId)
    local rows = db:query(usql).affected_rows
    if result and rows > 0 then
        return true
    else
        return false;
    end
end

-----------------------------------------------------------------
-- 编辑视频文件信息.
-- @param #string video_id：照片id
-- @param #string video_name：文件夹名称
-- @param #string description：视频描述、说明
function _M.editVideo(videoId, videoName, description)
    checkParamIsNull({
        videoId = videoId,
        videoName = videoName
    })
    if description == nil or string.len(description) == 0 then
        description = "DESCRIPTION"
    end
    local sql = "UPDATE T_SOCIAL_VIDEO SET VIDEO_NAME=%s,DESCRIPTION=%s WHERE ID=%d"
    sql = string.format(sql, quote(videoName), quote(description), videoId)
    local result = DBUtil:querySingleSql(sql);
    return result;
end



local function reloadResourceM3U8Info(result)
    if result then
        if TableUtil:length(result) > 0 then
            local db = SsdbUtil:getDb()

            for i = 1, #result do
                local resourceId = result[i]['resource_id'];
                log.debug("在redis中获取 资源信息.key: resource_" .. resourceId)
                local keys = {"m3u8_status", "m3u8_url", "thumb_id", "width", "height", "resource_format", "file_id"}
                local resRecord = db:multi_hget("resource_" .. resourceId,unpack(keys) )
                 log.debug(resRecord)
                if resRecord ~= ngx.null then
                    local res = util:multi_hget(resRecord, keys)
                    local m3u8_status = tostring(res.m3u8_status)
                    local m3u8_url = tostring(res.m3u8_url)
                    local thumb_id = tostring(res.thumb_id)
                    local width = tostring(res.width)
                    local height = tostring(res.height)
                    local resource_format = tostring(res.resource_format)
                    local file_id = tostring(res.file_id)
                    result[i].m3u8_status = m3u8_status
                    result[i].m3u8_url = m3u8_url
                    result[i].thumb_id = thumb_id
                    result[i].width = width
                    result[i].height = height
                    result[i].resource_format = resource_format
                    result[i].file_id = file_id
                end
            end
        end
    end
end

-----------------------------------------------------------------
-- 通过video_id获取视频.
-- @param #string video_id：照片id
function _M.getVideoById(id)
    checkParamIsNull({
        id = id
    })
    local sql = "SELECT *  FROM T_SOCIAL_VIDEO WHERE ID=%d";
    sql = string.format(sql, id);
    local result = DBUtil:querySingleSql(sql);
    reloadResourceM3U8Info(result)
    return result;
end

-----------------------------------------------------------------
-- 删除视频，可以批量删除 1
-- @param #string video_ids：照片id，多个用逗号分隔
-- @param #string folder_id：照片文件夹id
function _M.deleteVideo(ids, folder_id)
    checkParamIsNull({
        ids = ids,
        folder_id = folder_id
    })
    local idas = Split(ids, ",")
    local count = #idas;
    local sql = "UPDATE T_SOCIAL_VIDEO SET IS_DELETE=1 WHERE ID IN(" .. ids .. ")"
    log.debug("删除视频sql:" .. sql)
    local result = DBUtil:querySingleSql(sql)
    if result.affected_rows > 0 then
        local folder_sql = "UPDATE T_SOCIAL_VIDEO_FOLDER SET VIDEO_NUM=VIDEO_NUM-" .. count .. " WHERE ID=" .. folder_id
        local delete_r = DBUtil:querySingleSql(folder_sql)
        if delete_r.affected_rows > 0 then
            return true;
        end
    end
    return false;
end


local function calculatePage(pageNumber,pageSize,totalRow)
    local _pagenum = tonumber(pageNumber)
    local _pagesize = tonumber(pageSize)
    local totalRow = totalRow
    local totalPage = math.floor((totalRow + _pagesize - 1) / _pagesize)
    if totalPage > 0 and tonumber(pageNumber) > totalPage then
        _pagenum = totalPage
    end
    local offset = _pagesize * _pagenum - _pagesize
    return offset,_pagesize,totalPage
end
-----------------------------------------------------------------
-- 获取视频列表.
-- @param #string Folder_id：文件夹id
-- @param #string pageNumber：第几页
-- @param #string pageSize：每页条数
function _M.getVideoList(folderId, pageNumber, pageSize)
    checkParamIsNull({
        folderId = folderId,
        pageNumber = pageNumber,
        pageSize = pageSize
    })
    local count_sql = "SELECT COUNT(*) as totalRow FROM T_SOCIAL_VIDEO T WHERE T.FOLDER_ID=" .. folderId .. " AND IS_DELETE=0"
    local list_sql = "SELECT *  FROM T_SOCIAL_VIDEO T WHERE T.FOLDER_ID=" .. folderId .. " AND IS_DELETE=0"
    log.debug("获取列表.count_sql:" .. count_sql);
    local count = DBUtil:querySingleSql(count_sql);
    if TableUtil:length(count) == 0 then
        return false;
    end
    log.debug("获取视频列表.count:" .. count[1].totalRow);
    local offset,_pagesize,totalPage = calculatePage(pageNumber,pageSize,count[1].totalRow);
    list_sql = list_sql .. " LIMIT " .. offset .. "," .. _pagesize
    log.debug("获取视频列表.list sql:" .. list_sql);
    local list = DBUtil:querySingleSql(list_sql);
    local result = {totalRow = count[1].totalRow, totalPage = totalPage, pageNumber = pageNumber, pageSize = pageSize }
    --log.debug(type(list[1]))
    if list and list[1] then
        log.debug("获取视频列表.list :");
        log.debug(list)
        reloadResourceM3U8Info(list) --加载m3u8信息.
        result.video_list = list
    else
        result.video_list = {}
    end
    return result;
end

-----------------------------------------------------------------
-- 视频移动，可以批量移动
-- @param #string video_ids：照片id，多个用逗号分隔
-- @param #string from_folder_id：从文件夹id
-- @param #string to_folder_id：移动到文件夹id
function _M.moveVideos(videoIds, fromFolderId, toFolderId)
    checkParamIsNull({
        videoIds = videoIds,
        fromFolderId = fromFolderId,
        toFolderId = toFolderId
    })
    local t_ids = Split(videoIds, ",")
    local t_sqls = {}
    for i = 1, #t_ids do
        local pid = t_ids[i]
        if pid and string.len(pid) > 0 then
            local dsql = "UPDATE T_SOCIAL_VIDEO SET FOLDER_ID = " .. quote(toFolderId) .. " WHERE ID = " .. quote(pid) .. ";"
            table.insert(t_sqls, dsql)
        end
    end

    local dresult = DBUtil:batchExecuteSqlInTx(t_sqls, 1000)
    local db = DBUtil:getDb()
    --照片数
    if dresult then
        --从照片数-n
        local usql = "UPDATE T_SOCIAL_VIDEO_FOLDER SET VIDEO_NUM = VIDEO_NUM - " .. #t_sqls .. " WHERE ID = " .. quote(fromFolderId)
        local uresutl, err = db:query(usql)
        if not uresutl then
            return false;
        end
        --照片数+n
        local usql1 = "UPDATE T_SOCIAL_VIDEO_FOLDER SET VIDEO_NUM = VIDEO_NUM + " .. #t_sqls .. " WHERE ID = " .. quote(toFolderId)
        local uresutl1, err = db:query(usql1)
        if not uresutl1 then
            return false;
        end
    end
    return true;
end

----------------------------------------------------------------------
-- 验证file_id是否存在.
-- @param #string ids  id集合 以,分格.
-- @result #table
function _M.checkVideosByIds(ids)
    checkParamIsNull({
        ids = ids
    })
    local t_ids = Split(ids, ",")
    local t_sqls = {}
    for i = 1, #t_ids do
        local fid = quote(t_ids[i])
        table.insert(t_sqls, fid)
    end
    local str = table.concat(t_sqls, ",")
    local sql = "SELECT FILE_ID,resource_id,video_name FROM T_SOCIAL_VIDEO WHERE ID IN(" .. str .. ") AND IS_DELETE=0"
    log.debug("查询file_id sql:" .. sql)
    local id_list = DBUtil:querySingleSql(sql);
    reloadResourceM3U8Info(id_list);
    log.debug(id_list)
    return id_list;
end

return _M;