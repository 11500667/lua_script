local cjson = require "cjson"

ngx.header.content_type = "text/plain;charset=utf-8"

----带数组的复杂数据-----
local _jsonArray={}

--_jsonArray[1]=8
local  tab111 = {}
table.insert(tab111,_jsonArray)
--[[
_jsonArray[2]=9
_jsonArray[3]=11
_jsonArray[4]=14
_jsonArray[5]=25
 ]]
local _arrayFlagKey={}
_arrayFlagKey["array"]=_jsonArray
 
local tab = {}
tab["Himi"]="himigamedddd.com"
tab["testArray"]=tab111
tab["age"]="23"
 

local tabs={}

table.insert(tabs,tab);

tab = {}
tab["Himi"]="sohu.com"
tab["testArray"]=_arrayFlagKey
tab["age"]="23"
table.insert(tabs,tab);


tab = {}
tab["Himi"]="baidu.com"
tab["testArray"]=_arrayFlagKey
tab["age"]="23"
table.insert(tabs,tab);

--数据转json
local cjson = require "cjson"
local jsonData = cjson.encode(tabs)

ngx.say(jsonData);

