	
	local resourceInfo = {};
	resourceInfo.id = 7900340000
	resourceInfo.thumb_id = "-4";
	resourceInfo.resource_id_char = "-4";
	local test 	= require "base.resource.model.ResourceUtil";
	local result = test:setResourceInfo(resourceInfo)
	
	if result==true then
	    ngx.say("成功")
	else
	    ngx.say("失败")
	end
	