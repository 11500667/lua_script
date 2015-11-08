--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/8
-- Time: 14:40
-- To change this template use File | Settings | File Templates.
-- 备课工具基类

local BakToolsBaseService = {}
--- 业务逻辑模块初始化
--
-- @return table 业务逻辑模块
function BakToolsBaseService:init()
    return self
end
-- @param table module 模块
-- @return table 模块
function BakToolsBaseService:inherit(module)
    module.__super = self
    return setmetatable(module, {
        __index = function(self, key)
            if self.__super[key] then
                return self.__super[key]
            end
            return nil
        end
    })
end
return BakToolsBaseService

