#ngx.header.content_type = "text/plain;charset=utf-8"

local basicQt = { "选择题", "单项选择", "单项选择题", "多项选择", "多项选择题", "填空题", "计算题", "解答题", "简答题", "论述题", "判断题", "书面表达", "补全句子", "连线题", "写作", "排序题", "改写句子", "作图与实验", "探究与应用", "实验题", "材料分析", "综合题", "实验探究题", "实验探究", "组合列举题", "组合列举", "综合探究", "综合探究题", "材料分析题", "补全对话", "问答题", "历史小短文"};
local complexQt = { "完形填空", "阅读理解", "复合题"};

	--public static List<string> BasicQuestionTypeNames = new List<string> { "选择题", "单项选择", "单项选择题", "多项选择", "多项选择题", "填空题", "计算题", "解答题", "简答题", "论述题", "判断题", "书面表达", "补全句子", "连线题", "写作", "排序题", "改写句子", "作图与实验", "探究与应用", "实验题", "材料分析", "综合题", "实验探究题", "实验探究", "组合列举题", "组合列举", "综合探究", "综合探究题", "材料分析题"};

	-- public static List<string> ComplexQuestionTypeNames = new List<string> { "完形填空", "阅读理解", "复合题", };

local resultObj = {};
resultObj.success = true;
resultObj.basic = basicQt;
resultObj.complex = complexQt;

local cjson = require "cjson";
local resultJson = cjson.encode(resultObj);

ngx.say(resultJson);