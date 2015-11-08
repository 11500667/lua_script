--[[
#李政言 2015-07-07
#描述：修改资源的信息
]]

local _ResourceInfo = { author="lzy"};

---------------------------------------------------------------------------
--[[
	局部函数：设置资源的属性
	作者： 	李政言 2015-04-02
	参数： 	resourceTab  		需要修改的属性
	返回值：boolean      	true是设置成功，false设置失败
]]
local function setResourceInfo(self, resourceTab)
	
	--连接ssdb
	local ssdb = require "resty.ssdb"
    local ssdb_db = ssdb:new()
    local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
      if not ok then
         ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
      return
    end
	--设置ssdb中的属性
	
	
	
end

_ResourceInfo.setResourceInfo = setResourceInfo;

return _ResourceInfo;