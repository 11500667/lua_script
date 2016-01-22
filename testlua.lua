--local response = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds", {
--	method = ngx.HTTP_POST,
--	body = "ids=2343,234324,324324"
--})

--ngx.say(response.status .. " ===> body ===> " .. response.body);

--Split方法
function Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end


local a = ",,,,,,,,";

local t= Split(a,",");

print(#t);