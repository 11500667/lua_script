local _FileUtil= {};
--[[
判断文件是否存在
@param path 文件路径
@return true存在，false不存在
--]]
function _FileUtil:file_exists(path)
    local f=io.open(path,"r")
    if f~=nil then io.close(f)
        return true
    else
        return false
    end
end

--[[
----检测文件是否存在，不存在就创建
--]]
function _FileUtil:create_is_file_exists(pathfile)
    if not self.file_exists(pathfile) then
        file = io.open(pathfile, "w");
    end
    file:close()
end

--[[
----@函数功能:删除文件
--]]
function _FileUtil:delfile(filePath)
    return os.remove(filePath)
end

--[[
   删除文件
    @param path 文件路径
    @return true删除成功，false删除失败或文件不存在
--]]
function _FileUtil:file_remove(path)
    if self.file_exists(path) then
        os.remove(path)
        return true
    end
    return false
end

return _FileUtil;