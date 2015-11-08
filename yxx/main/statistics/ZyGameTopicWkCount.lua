--[[
@Author cuijinlong
@date 2015-4-24
--]]
local StatModel = require "yxx.main.statistics.model.StatModel";
local rows = StatModel:game_topic_count();
ngx.say("{\"game\":"..rows[1]["count"]..",\"topic\":"..rows[2]["count"].."}")

