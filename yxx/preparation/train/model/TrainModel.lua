--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Train = {};

--[[
	局部函数：组装环节Vo数组
]]
function _Train:getTrainVo(yx_id,train_table)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local train_id = tonumber(SSDBUtil:incr("yx_moudel_train_pk"));
    local train_vo = {};
    train_vo.train_id = train_id;
    train_vo.yx_id = yx_id;
    train_vo.train_name = train_table.train_name;
    train_vo.train_content = train_table.train_content;
    train_vo.create_time = ngx.localtime();
    return train_vo;
end

--[[
	局部函数：组装insert sql语句
]]
function _Train:getTrainInsertSqlArrstable(train_table_arrs)
    local tableUtil = require "yxx.tool.TableUtil";
    local sql_table = {};
    for i=1,#train_table_arrs do
        local k_v_table = tableUtil:convert_sql(train_table_arrs[i]);
        sql_table[i] = "insert into t_yx_train("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    end
    return sql_table;
end
return _Train;