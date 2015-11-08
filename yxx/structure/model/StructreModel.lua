local _Structre={};
--[[
@Author cjl
@date 2015-7-15
--]]

--[[
--记录学生上传点击树的节点ID
--]]
function _Structre:save_structre_record(student_id,model_id,subject_id,table)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    SSDBUtil:multi_hset("record_structre_"..student_id.."_"..model_id.."_"..subject_id,table)
end

--[[
--获得学生上传点击树的节点ID
--]]
function _Structre:get_structre_record(student_id,model_id,subject_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local table = SSDBUtil:multi_hget_hash("record_structre_"..student_id.."_"..model_id.."_"..subject_id,"structure_id","pidstr");
    SSDBUtil:_keepAlive();
    return table;
end

return _Structre;