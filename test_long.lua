local _TestController2 = {};

function _TestController2: aaa() 
    local paramValue1 = self: getParamByName("param1", true);
    local paramValue2 = self: getParamToNumber("param2");
    local paramValue3 = self: getParamToNumber("param3");
	
	local result = {};
	result.param1 = paramValue1;
	result.param2 = paramValue2;
	result.param3 = paramValue3;
	
	self: printJson(result);
end

function _TestController2: bbb()
	self: printJson("this is a test class! ");
end

BaseController: initController(_TestController2);