-- -----------------------------------------------------------------------------------
-- 文件描述： controller类：[iComet的公用的工具类]
-- 日    期： 2016年1月5日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------
local _iCometCtl = {};

local _iCometUtil = require "common.iComet.iCometUtil";

-- -----------------------------------------------------------------------------------
-- 函数描述： controller函数：[向iComet的Channel中插入信息]
-- 日    期： 2016年1月5日
-- 参    数： 无
-- 返 回 值： 返回值信息
-- -----------------------------------------------------------------------------------
local function push(self)
    -- 1、iComet 只支持GET请求，此处验证如果客户端使用POST请求，则返回错误
    -- local method = ngx.var.request_method;
    -- if method == "POST" then
    --     self: printJson(encodeJson({ success = false, info = "请求方式不正确，只支持GET请求"}));
    --     ngx.exit(ngx.HTTP_OK);
    -- end
    -- 2、获取参数
    local channelName = self: getParamByName("cname"  , true);
    local content     = self: getParamByName("content", true);
    -- 3、发送消息
    local status, result, err = pcall(_iCometUtil["push"], _iCometUtil, channelName, content);
    if not status then    
        ngx.log(ngx.INFO, "\n向iComet中插入信息失败，错误信息：[", result, "]\n");
        self: printJson(encodeJson({ success = false, info = "向iComet中插入信息失败" }));
        ngx.exit(ngx.HTTP_OK);
    end
    -- 4、返回消息给客户端
    self: printJson(encodeJson({ success = true, info = "向iComet插入信息成功"}));
end
_iCometCtl.push = push;


local function test2(self)
    local testParam = self: getParamByName("test_para", true);
    ngx.log(ngx.INFO, "[sj_log] -> [modelName] -> testParam: [", testParam, "]");

    self: printJson(encodeJson({ success = true, info = "测试成功"}));
end
_iCometCtl.test2 = test2;

BaseController:initController(_iCometCtl);