require "common.CommonUtil"
local cjson = require "cjson"
ngx.log(ngx.ERR,"=====================================================")
ngx.log(ngx.ERR,test())
local returnjson = {}
returnjson.success = true
returnjson.info = test()
ngx.print(cjson.encode(returnjson))

