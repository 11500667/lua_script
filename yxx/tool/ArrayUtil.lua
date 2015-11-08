
local _ArrayUtil = {};
function _ArrayUtil:arrayContain(array, value)
    for i=1,#array do
        if array[i] == value then
            return true;
        end
    end
    return false;
end
return _ArrayUtil;