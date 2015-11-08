ngx.header.content_type = "text/plain;charset=utf-8"

function RandomIndex(tabNum,indexNum)
	indexNum = indexNum or tabNum
	local t = {}
	local rt = {}
	for i = 1,indexNum do
		local ri = math.random(1,tabNum + 1 - i)
		local v = ri
		for j = 1,tabNum do
			if not t[j] then
				ri = ri - 1
				if ri == 0 then
					table.insert(rt,j)
					t[j] = true
				end
			end
		end
	end
	return rt
end

local tab = {1,2,3,4,5,6,7}
local s = RandomIndex(7,7)
ngx.say(s[math.random(7)].."====")
ngx.say(math.random(7))

math.randomseed(os.time())
ngx.say(math.random(4))
 
local str = "0KHRpw=="

ngx.say(ngx.decode_base64(str))

ngx.say(v_pool_size)
