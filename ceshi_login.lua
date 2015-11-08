#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
--根据persion_id  identity_id判断本身是否已经登录
if (cookie_person_id == "nil" or cookie_identity_id=="nil")  then


        local request_method = ngx.var.request_method
        local args = nil
        if "GET" == request_method then
                args = ngx.req.get_uri_args()
        else
                ngx.req.read_body()
                args = ngx.req.get_post_args()
        end
        --ngx.say("adsd!")
        --return

        local st = tostring(args["ticket"])
        if st=="nil" then
		--跳转到统一认证登录页面
                local uri=ngx.var.http_host
                local path=ngx.var.uri
                return ngx.redirect("http://"..v_cas_path.."/dsssoserver/login?service=http://"..uri..path)
                --ngx.say("跳转到统一认证登陆页面！http://"..uri..path)
        else
		ngx.say('/dsideal_yy/cas/http://'..v_cas_path..'/dsssoserver/serviceValidate?ticket='..st)
local uri=ngx.var.http_host			
		--去统一认证获取登录人员信息
                local res=ngx.location.capture('/dsideal_yy/cas/http://'..v_cas_path..'/dsssoserver/serviceValidate?ticket='..st..'&service=http://'..uri)
                ngx.say(res.body)
	end
end
