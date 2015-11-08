--[[
    #申健   2015-04-18
    #描述： 计算文件大小的通用函数
]]

local _FileSize = {};

-- 小数点后的位数
local _digit = 2;

----------------------------------------------------------------------------------
--[[
	局部函数：获取数字（带小数点后指定的位数）
	作者：    申健 	        2015-04-19
	参数1：   numVal  	    数字的值
	参数2：   digit  	    小数点后需要保留的位数
	返回值： 数字大小
]]
local function getNumber(numVal, digit)
    local a = 1/math.pow(10, digit);
    print("===> a: " .. a);
    local val = numVal;
    val = val - val%a;
    return val;
end

----------------------------------------------------------------------------------
--[[
	局部函数：将文件大小由字节转换为KB
	作者：    申健 	        2015-04-19
	参数1：   fileSize  	文件的字节数
	返回值：  文件大小（KB）
]]
local function toKB(fileSize)
    local size = fileSize/1024;
    return size; -- getNumber(size, _digit);
end

----------------------------------------------------------------------------------
--[[
	局部函数：将文件大小由字节转换为MB
	作者：    申健 	        2015-04-19
	参数1：   fileSize  	文件的字节数
	返回值：  文件大小（MB）
]]
local function toMB(fileSize)
    local size = (fileSize/1024)/1024
    return getNumber(size, _digit);
end

----------------------------------------------------------------------------------
--[[
	局部函数：将文件大小由字节转换为GB
	作者：    申健 	        2015-04-19
	参数1：   fileSize  	文件的字节数
	返回值：  文件大小（GB）
]]
local function toGB(fileSize)
    local size = ((fileSize/1024)/1024)/1024
    return getNumber(size, _digit);
end

----------------------------------------------------------------------------------
--[[
	局部函数：转换文件大小的值，返回数字，不带单位
	作者：    申健 	        2015-04-19
	参数1：   fileSize  	文件的大小值，单位：字节
	参数1：   valType  	    0：自动使用最大单位，1：KB，2：MB，3：GB
	返回值1： 文件大小（数字）
]]
local function getFileSize(self, fileSize, valType)
	
    if valType == 0 then
        if fileSize < 1024 then
            return fileSize
        elseif fileSize > 1024 and fileSize < 1024*1024 then
            return toKB(fileSize);
        elseif fileSize > 1024*1024 and fileSize < 1024*1024*1024 then
            return toMB(fileSize);
        elseif fileSize > 1024*1024*1024 then
            return toGB(fileSize);
        end
    elseif valType == 1 then
        return toKB(fileSize);
    elseif valType == 2 then
        return toMB(fileSize);
    elseif valType == 3 then
        return toGB(fileSize);
    end
end

_FileSize.getFileSize = getFileSize;

----------------------------------------------------------------------------------
--[[
	局部函数：转换文件大小的值，返回字符串，带单位
	作者：    申健 	        2015-04-19
	参数1：   fileSize  	文件的大小值，单位：字节
	参数1：   valType  	    0：自动使用最大单位，1：KB，2：MB，3：GB
	返回值1： 文件大小（字符串）
]]
local function getFileSizeStr(self, fileSize, valType)
	
    if valType == 0 then
        if fileSize < 1024 then
            return fileSize + "B";
        elseif fileSize > 1024 and fileSize < 1024*1024 then
            return toKB(fileSize) .. "KB";
        elseif fileSize > 1024*1024 and fileSize < 1024*1024*1024 then
            return toMB(fileSize) ..  "MB";
        elseif fileSize > 1024*1024*1024 then
            return toGB(fileSize) ..  "GB";
        end
    elseif valType == 1 then
        return toKB(fileSize) .. "KB";
    elseif valType == 2 then
        return toMB(fileSize) .. "MB";
    elseif valType == 3 then
        return toGB(fileSize) .. "GB";
    end
end

_FileSize.getFileSizeStr = getFileSizeStr;

print(_FileSize:getFileSizeStr(1115, 1));
----------------------------------------------------------------------------------
return _FileSize;