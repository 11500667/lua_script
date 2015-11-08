--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/5/22
-- Time: 17:57
-- To change this template use File | Settings | File Templates.
--


local Constant = {
    MESSAGE_TYPE_BBS = "1",
    MESSAGE_TYPE_BOARD ="2",
}
--- 转换orgType
--- 省101 市102 区103 校104 班105
--- 机构类型：1省，2市，3区，4校，5分校，6部门，7班级
function Constant:convert(orgType)
    local _orgType = 0;
    if orgType == "101" then
        _orgType = 1
    elseif orgType == "102" then
        _orgType = 2
    elseif orgType == "103" then
        _orgType = 3
    elseif orgType == "104" then
        _orgType = 4
    end
    return _orgType
end

return Constant