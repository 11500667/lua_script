--[[
#申健  2015-07-03
#描述：获取试题的难度元数据
]]
local metaModel = require "question.model.QuestionMeta";
local resultTable = metaModel: getDifficultList();

local responseObj = {};

responseObj["success"]   = true;
responseObj["nd_list"] = resultTable;

local cjson = require "cjson";
ngx.print(cjson.encode(responseObj));