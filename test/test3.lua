local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end




local cjson = require "cjson"
local res = ngx.location.capture("/dsideal_yy/ypt/workroom/getWorkroomByPersonId?person_id=88")
local str =  cjson.decode(res.body)
local ids = str.workroom_ids
if ids == "" then
    ngx.say("空")
else
    local r_id = Split(ids,",")
    for i=1,#r_id do
	ngx.say(r_id[i].."====================")
    end
end

local size = "11"

if tonumber(size) > 10 then
ngx.say("大于")

end

ngx.say("======================================")
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(string.format("%14.3f",ngx.now()),12,14)
ngx.say(ts)

ngx.say("********************************************")
ngx.say(string.len(ts))

local myTs = require "resty.TS"
ngx.say("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"..myTs.getTs())

local date = require "resty.date"
local a,b,c,d,e,y,m,h,s,t 
  
d = date.diff("Jan 7 1563", date(1563, 1, 2)) 
ngx.say(d:spandays()) 

local encode_str = "eyJjcmVhdGVfdGltZSI6IjIwMTQtMDktMjkgMTA6Mzg6MDYiLCJoZWlnaHQiOjEyMDAsIm5kX2lkIjo1LCJuZF9zdGFyIjoi4piF4piF4piF4piF4piFIiwib3B0aW9uX2NvdW50IjowLCJxdF9pZCI6OSwicXRfbmFtZSI6IumYheivu+eQhuinoyIsInF0X3R5cGUiOjIsInF1ZXN0aW9uX2lkX2NoYXIiOiI0ODYxQ0QzMy0zREQyLTRDNEMtOTY4Qi0zN0NBNDVFNDEwRUUiLCJzdHJ1Y3R1cmVfaWQiOjUyODQ2LCJzdHJ1Y3R1cmVfcGF0aCI6IuWIneS4reivreaWh+efpeivhueCuT09LT7pmIXor7stPueOsOS7o+aWh+mYheivuy0+6K6w5Y+Z5paH6ZiF6K+7IiwidF9jaGlsZCI6W10sInRfaWQiOiIyNEVGMEREQi1DQTM5LTQwNTItQjQ0Ri0wRDA5QTVGMTUwNzgiLCJ0X3JhbmdlIjoxLCJ0X3RpdGxlIjoi5Lic5biI55CG5oOz5o+Q5L6bIiwidXNlX2NvdW50IjowLCJ6c2QiOiIifQ=="

local question_str = ngx.decode_base64(encode_str)

ngx.say(question_str)
local question_json = cjson.decode(question_str)

ngx.say(question_json["t_title"])


local mySP = require "resty.Split"
local ids = "1,2,3"
ngx.say(mySP.split(ids,","))


