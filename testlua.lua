--local response = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds", {
--	method = ngx.HTTP_POST,
--	body = "ids=2343,234324,324324"
--})

--ngx.say(response.status .. " ===> body ===> " .. response.body);


local str = "，中，国，长，春，市";
print(string.sub(str,2,3));
