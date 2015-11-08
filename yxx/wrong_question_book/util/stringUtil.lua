local _StringUtil= {};
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
return _StringUtil;
