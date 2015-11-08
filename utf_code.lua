
ngx.header.content_type = "text/plain;charset=utf-8"


local function urlencode(str)  
    if (str) then  
        str = string.gsub (str, "\n", "\r\n")  
        str = string.gsub (str, "([^%w ])",  
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)  
        str = string.gsub (str, " ", "+")  
    end  
    return str  
end  


ngx.say(urlencode("回执"))
ngx.say(string.upper(ngx.escape_uri("回执")))
