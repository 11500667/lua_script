--
--    张海  2015-05-06
--    描述：  BBS index controller.
--
ngx.header.content_type = "text/plain";
local web = require("social.router.web")
local TableUtil = require("social.common.table")
local cjson = require "cjson"
local request = require("social.common.request")
local context = ngx.var.path_uri --有权限的context.
local no_permission_context = ngx.var.path_uri_no_permission --没有权限的context.
local log = require("social.common.log")
local service = require("space.video.service.VideoService")

---------------------------------------------------------------
-- 创建视频文件夹 1
-- Person_id：用户id
-- Identity_id：身份id
-- Folder_name：文件夹名称
-- Is_private：0公有,1私有
local function createVideoFolder()
    local personId = request:getStrParam("person_id", true, true)
    local identityId = request:getStrParam("identity_id", true, true)
    local folderName = request:getStrParam("folder_name", true, true)
    local isPrivate = request:getStrParam("is_private", true, true)
    local isDefault = request:getStrParam("is_default", false, true)
    local result = service.createVideoFolder(personId, identityId, folderName, isPrivate, isDefault)
    local r = { success = true, info = "保存成功." }
    if not result then
        r.success = false
        r.info = "保存失败!"
    end
    ngx.print(cjson.encode(r))
end

---------------------------------------------------------------
-- 编辑视频文件夹 1
-- @param #string Folder_id：文件夹id
-- @param #string Folder_name：文件夹名称
-- @param #string Is_private：0公有,1私有
local function editVideoFolder()
    local folderId = request:getStrParam("folder_id", true, true)
    local folderName = request:getStrParam("folder_name", true, true)
    local isPrivate = request:getStrParam("is_private", false, true)
    local result = service.editVideoFolder(folderName, isPrivate, folderId)
    local r = { success = true, info = "修改成功." }
    if not result then
        r.success = false
        r.info = "修改失败!"
    end
    ngx.print(cjson.encode(r))
end

------------------------------------------------------------------
---- 通过id获取视频文件夹信息.
-- local function getVideoFolderById()
-- local folderId = request:getStrParam("folder_id", true, true)
-- service:
-- end

----------------------------------------------------------------
-- 删除视频文件夹 1
-- @param #string folder_id：文件夹id
local function deleteVideoFolder()
    local folderId = request:getStrParam("folder_id", true, true)
    local result = service.deleteVideoFolder(folderId)
    local r = { success = true, info = "删除成功." }
    if not result then
        r.success = false
        r.info = "删除失败!"
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 获取视频文件列表. 1
-- @param #string person_id：用户id
-- @param #string identity_id：身份id
-- @param #string is_private：0公有,1私有,不传查所有
local function getVideoFolder()
    local personId = request:getStrParam("person_id", true, true)
    local identityId = request:getStrParam("identity_id", true, true)
    local isPrivate = request:getStrParam("is_private", false, true)
    local result = service.getVideoFolder(personId, identityId, isPrivate)
    local r = { success = true, info = "" }
    if not result then
        r.success = false
        r.info = "失败!"
    else
        r.info = "成功!"
        r.folder_list = result;
    end
    cjson.encode_empty_table_as_object(false)
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 通过id获取文件夹信息.1
-- @param #string folder_id：文件夹id
-- @return
-- Id:文件夹id
-- folder_name:文件夹名称
-- Create_time：创建时间
-- isPrivate：0公有，1私有
local function getFolderById()
    local folderId = request:getStrParam("folder_id", true, true)
    local result = service.getFolderById(folderId);
    local r = { success = true, info = "" }
    if not result then
        r.success = false
        r.info = "失败!"
    else
        if TableUtil:length(result) > 0 then
            r = result[1];
        end
        r.info = "成功!"
        r.success = true;
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 创建视频文件.1
-- @param #string Person_id：用户id
-- @param #string Identity_id：身份id
-- @param #string Folder_id：文件夹id
-- @param #string video_name：视频名称
-- @param #string file_id：file_id加扩展名
-- @param #string file_size：视频大小
-- @param #string description：视频说明描述
-- @param #string resource_id：视频说明描述
local function createVideo()
    local personId = request:getStrParam("person_id", true, true)
    local identityId = request:getStrParam("identity_id", true, true)
    local folderId = request:getStrParam("folder_id", true, true)
    local videoName = request:getStrParam("video_name", true, true)
    local fileId = request:getStrParam("file_id", true, true)
    local fileSize = request:getStrParam("file_size", true, true)
    local description = request:getStrParam("description", false, true)
    local resourceId = request:getStrParam("resource_id", true, true)
    local result = service.createVideo(personId, identityId, folderId, videoName, fileId, fileSize, description, resourceId)
    local r = { success = true, info = "创建成功." }
    if not result then
        r.success = false
        r.info = "创建失败!"
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 编辑视频文件信息.1
-- @param #string video_id：照片id
-- @param #string video_name：文件夹名称
-- @param #string description：视频描述、说明
local function editVideo()
    local videoId = request:getStrParam("video_id", true, true)
    local videoName = request:getStrParam("video_name", true, true)
    local description = request:getStrParam("description", false, true)
    local result = service.editVideo(videoId, videoName, description)
    local r = { success = true, info = "修改成功." }
    if not result then
        r.success = false
        r.info = "修改失败!"
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 通过video_id获取视频.1
-- @param #string video_id：照片id
local function getVideoById()
    local videoId = request:getStrParam("video_id", true, true)
    local result = service.getVideoById(videoId)
    local r = { success = true, info = "成功." }
    if not result then
        r.success = false
        r.info = "失败!"
    else
        if TableUtil:length(result) > 0 then
            r = result[1];
        end
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 删除视频，可以批量删除
-- @param #string video_ids：照片id，多个用逗号分隔
local function deleteVideo()
    local videoIds = request:getStrParam("video_ids", true, true)
    local folderId = request:getStrParam("folder_id", true, true)
    local result = service.deleteVideo(videoIds,folderId)
    local r = { success = true, info = "删除成功!" }
    if not result then
        r.success = false
        r.info = "删除失败!"
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 获取视频列表.1
-- @param #string Folder_id：文件夹id
-- @param #string pageNumber：第几页
-- @param #string pageSize：每页条数
-- @return
-- TotalPage：总页数
-- TotalRow：总条数
-- pageNumber：第几页
-- pageSize：每页条数
-- video_list:[{
-- Id:照片id
-- Person_id：用户id
-- Identity_id：身份id
-- video_name:文件夹名称
-- Create_time：创建时间
-- folder_id：所属文件夹id
-- file_id：file_id加扩展名
-- file_size：视频文件大小
-- description：描述
-- }]
local function getVideoList()
    local folderId = request:getStrParam("folder_id", true, true)
    local pageNumber = request:getStrParam("pageNumber", true, true)
    local pageSize = request:getStrParam("pageSize", true, true)
    local result = service.getVideoList(folderId, pageNumber, pageSize)
    if result then
        result.success = true;
        cjson.encode_empty_table_as_object(false)
        ngx.print(cjson.encode(result))
    else
        local r = { success = false, info = "失败." }
        ngx.print(cjson.encode(r))
    end
end

-----------------------------------------------------------------
-- 视频移动，可以批量移动.1
-- @param #string video_ids：照片id，多个用逗号分隔
-- @param #string from_folder_id：从文件夹id
-- @param #string to_folder_id：移动到文件夹id
local function moveVideos()
    local videoIds = request:getStrParam("video_ids", true, true)
    local fromFolderId = request:getStrParam("from_folder_id", true, true)
    local toFolderId = request:getStrParam("to_folder_id", true, true)
    local result = service.moveVideos(videoIds, fromFolderId, toFolderId)
    local r = { success = false, info = "失败." }
    if result then
        r.success = true;
        r.info = "成功."
    end
    ngx.print(cjson.encode(r))
end

-----------------------------------------------------------------
-- 视频移动，可以批量移动.1
-- @param #string file_ids 视频文件 id集合 以,分格.
local function checkVideos()
    local ids = request:getStrParam("ids", true, true)
    local result = service.checkVideosByIds(ids)
    local r = {success = false }
    if result then
        r.list = result
        r.success = true;
    end
    cjson.encode_empty_table_as_object(false)
    ngx.print(cjson.encode(r))
end

-- 配置url.
-- 按功能分
local urls = {
    context .. '/createVideoFolder', createVideoFolder,
    context .. '/editVideoFolder', editVideoFolder,
    context .. '/deleteVideoFolder', deleteVideoFolder,
    context .. '/getVideoFolder', getVideoFolder,
    context .. '/getFolderById', getFolderById,
    context .. '/createVideo', createVideo,
    context .. '/editVideo', editVideo,
    context .. '/getVideoById', getVideoById,
    context .. '/deleteVideo', deleteVideo,
    context .. '/getVideo', getVideoList,
    context .. '/moveVideos', moveVideos,
    no_permission_context .. '/checkVideos', checkVideos,
}
local app = web.application(urls, nil)
app:start()