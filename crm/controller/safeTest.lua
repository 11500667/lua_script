local timestamp 	= os.time();

local nonce = "cba";
local token = "dsideal";
local tab = {};
table.insert(tab,token);
table.insert(tab,tostring(timestamp));
table.insert(tab,nonce);
table.sort(tab);
local str = table.concat(tab, "");


local signature 	= ngx.md5(str);











local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..signature.."\",\"return_param_2\":\""..timestamp.."\",\"return_param_3\":\""..nonce.."\"}";
ngx.print(return_info);

