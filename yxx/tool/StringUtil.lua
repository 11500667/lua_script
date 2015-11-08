local _StringUtil= {};

-- 分隔字符串的办法
function _StringUtil:split(szFullString, szSeparator)
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

--获取扩展名
function _StringUtil:getExtension(str)
    return str:match(".+%.(%w+)$")
end


function _StringUtil:kwonledge_point_code_convert(kwonledge_point_codes)
    --local return_str = '';
    if kwonledge_point_codes ~= nil and  #kwonledge_point_codes > 0 then
        --		local kwonledge_point_codes_array = Split(kwonledge_point_codes,"_");
        --		for i=1,#kwonledge_point_codes_array do
        --			local str = kwonledge_point_codes_array[i];
        --			return_str = return_str..str..',';
        --		end
        --		return_str = string.sub(return_str,1, #return_str-1);
        return string.gsub(kwonledge_point_codes,"_",",");
    else
        return "";
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------

--获得时间戳
function _StringUtil:getTimestamp()
    local t = ngx.now();
    local n = os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14);
    n=n..string.rep("0",19-string.len(n));
    return n;
end

--[[
  去除字符串两边空格
  @param s
  @return 处理完的字符串
]]--
function _StringUtil:trim (s)
    if not s then
        return nil
    end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end


--------------------------------------------------------------------------------------------------------------------------------------------------------
return _StringUtil;
