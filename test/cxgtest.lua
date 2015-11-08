--.print("ssss")
--ngx.say("{\"success\":\"false\",\"info\":\"err\"}");
for i=1,11,3 do ngx.say(i) end


local ok = false;
local err = true;
local res1 = "www";
--local res1,res2,res3,res4 = ok or err,err or ok,ok and err,err and ok

ngx.say("33333".. res1 .."");



