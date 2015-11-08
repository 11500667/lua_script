--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/5/19
-- Time: 17:10
-- To change this template use File | Settings | File Templates.
--


local b =1
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end

ngx.sleep(10)

ngx.say(args["a"]+1)
