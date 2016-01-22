



local str = "";


str = "0001abcdefgeijklmn1";

local _,total = string.gsub(str,"[A-Za-z1-9]?","d");

print(_);

print(total);
