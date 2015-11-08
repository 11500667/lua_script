local _DateTime = {};
--[[
根据已知时间和偏移量以及时间单位计算出一个新的时间
@param srcDateTime 时间
@param interval 偏移量
@param dateUnit 偏移量单位
@use  local newTime=getNewDate(oldTime,3,'HOUR')
      local a1 = string.format('%d-%02d-%02d %02d:%02d:%02d',newTime.year,newTime.month,newTime.day,newTime.hour,newTime.min,newTime.sec)
      =>2013-09-09 02:28:28
--]]
function _DateTime:get_new_date(srcDateTime,interval ,dateUnit)
    --从日期字符串中截取出年月日时分秒
    local Y = string.sub(srcDateTime,1,4)
    local M = string.sub(srcDateTime,5,6)
    local D = string.sub(srcDateTime,7,8)
    local H = string.sub(srcDateTime,9,10)
    local MM = string.sub(srcDateTime,11,12)
    local SS = string.sub(srcDateTime,13,14)
    --把日期时间字符串转换成对应的日期时间
    local dt1 = os.time{year=Y, month=M, day=D, hour=H,min=MM,sec=SS}
    --根据时间单位和偏移量得到具体的偏移数据
    local ofset=0
    if dateUnit =='DAY' then
        ofset = 60 *60 * 24 * interval
    elseif dateUnit == 'HOUR' then
        ofset = 60 *60 * interval
    elseif dateUnit == 'MINUTE' then
        ofset = 60 * interval
    elseif dateUnit == 'SECOND' then
        ofset = interval
    end
    local newTime = os.date("*t", dt1 + tonumber(ofset)) --指定的时间+时间偏移量
    return newTime
end
return _DateTime;