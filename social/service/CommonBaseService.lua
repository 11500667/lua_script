--
--    张海  2015-05-06
--    描述：  CommonBaseService 接口.
--
local CommonBaseService = {
}
--- 业务逻辑模块初始化
--
-- @return table 业务逻辑模块
function CommonBaseService:init()
    return self
end
function CommonBaseService:info()
    print("开始了.")
end
--验证参数是否为空.
function CommonBaseService:checkParamIsNull(t)
    for key, var in pairs(t) do
        if var == nil or string.len(var) == 0 then
            error(key .. " 不能为空.")
        end
    end
end
--- 建立模块与业务逻辑基类的继承关系(模块Dao属性的全部方法将会暴露，可以像调用模块本身的方法一样调用)
--
-- @param table module 模块
-- @return table 模块
function CommonBaseService:inherit(module)
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
return CommonBaseService
