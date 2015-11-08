ngx.header.content_type = "text/plain;charset=utf-8"


local response = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds", {
	method = ngx.HTTP_POST,
	body = "ids=2343,234324,324324" 
})

ngx.say(response.status .. " ===> body ===> " .. response.body);