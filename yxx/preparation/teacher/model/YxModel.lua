--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _YX = {};
--[[
	局部函数：教师列表
]]
function _YX:yxList(yx_name,person_id,person_identity,subject_id,is_root,scheme_id,structure_id,sort_type,sort_mode,cnode,page_size,page_number)
    local DbUtil = require "yxx.tool.DbUtil";
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local offset = page_size*page_number-page_size;
    local limit = page_size;
    local str_maxmatches = page_number*100;
    --升序还是降序
    local asc_desc = "";
    if sort_mode == "1" then
        asc_desc = "asc";
    else
        asc_desc = "desc";
    end
    --排序
    local sort_filed="";
    if sort_type=="1" then
        sort_filed = "sort=attr_"..asc_desc..":update_ts;";
    end
    local query_condition = "";
    if yx_name ~= "" then
        query_condition = query_condition..yx_name..";";--关键字搜索
    end
    if person_id ~= "" then
        query_condition = query_condition.."filter=create_person_id,"..person_id..";";--预习创建人ID
    end
    if person_identity ~= "" then
        query_condition = query_condition.."filter=create_identity_id,"..person_identity..";";--预习创建人身份
    end
    if subject_id ~= "" then
        query_condition = query_condition.."filter=subject_id,"..subject_id..";";
    end

    local structure_scheme = ""
    if is_root == "1" then
        if cnode == "1" then
            structure_scheme = "filter=scheme_id,"..scheme_id..";"
        else
            structure_scheme = "filter=structure_id,"..structure_id..";"
        end
    else
        if cnode == "0" then
            structure_scheme = "filter=structure_id,"..structure_id..";"
        else
            local cache = DbUtil:getRedis();
            local sid = cache:get("node_"..structure_id)
            local sids = Split(sid,",")
            for i=1,#sids do
                structure_scheme = structure_scheme..sids[i]..","
            end
            structure_scheme = "filter=structure_id,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
            cache:set_keepalive(0,v_pool_size)
        end
    end
    local db = MysqlUtil:getDb();
    local query_sql    = "SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse where QUERY=\'"..query_condition..structure_scheme..sort_filed.."filter=is_delete,0;filter=class_id,0;filter=group_id,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;";

    local rows = MysqlUtil:query(query_sql);
    local read_result  = db:read_result();
    local _,s_str      = string.find(read_result[1]["Status"],"found: ");
    local e_str        = string.find(read_result[1]["Status"],", time:");
    local total_row    = string.sub(read_result[1]["Status"],s_str+1,e_str-1);
    local total_page   = math.floor((total_row+page_size-1)/page_size);
    local return_table = {};
    for i=1,#rows do
        local yxtoperson_tab = SSDBUtil:multi_hget_hash("yxx_yxtoperson_"..rows[i].id,"yx_id");--rows[i].id：预习人员表的ID
        local yx_table = SSDBUtil:multi_hget_hash("yx_moudel_info_"..yxtoperson_tab.yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id","is_public","class_ids","group_ids");
        -- todo 预习提交情况 start
        local ssdb = SSDBUtil:getDb();
        db:query("SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse WHERE query=\'filter=yx_id,"..yxtoperson_tab.yx_id.."\';SHOW ENGINE SPHINX  STATUS;");
        local count    = db:read_result();
        local _,s_str  = string.find(count[1]["Status"],"found: ");
        local e_str    = string.find(count[1]["Status"],", time:");
        local total    = string.sub(count[1]["Status"],s_str+1,e_str-1);
        local submit_count = ssdb:hsize("yx_student_submit_"..yxtoperson_tab.yx_id);
        if not submit_count or string.len(submit_count[1])==0 then
            yx_table.submit_info = ngx.encode_base64("0/"..(tonumber(total)-1));
        else
            yx_table.submit_info = ngx.encode_base64(submit_count[1].."/"..(tonumber(total)-1));
        end
        -- todo 预习提交情况 end
        table.insert(return_table,yx_table);
    end
    local result         ={};
    result["success"]    ="true";
    result["total_row"]  =total_row;
    result["total_page"] =total_page;
    result["page_number"]=page_number
    result["page_size"]  =page_size;
    result["list"]       =return_table;
    SSDBUtil:keepAlive();
    MysqlUtil:close(db);
    return result;
end

function _YX:getYxTableArrs(param_table)
    local yx_table        = {};
    yx_table.yx_id        = param_table.yx_id;                     --预习ID
    yx_table.yx_name      = param_table.yx_name;                   --预习名称
    yx_table.create_time  = ngx.localtime();                       --创建时间
    yx_table.class_ids    = param_table.class_ids;                 --预习对象(按班级留预习)
    yx_table.group_ids    = param_table.group_ids;                 --预习对象(按组留预习)
    yx_table.person_id    = tonumber(param_table.person_id);       --创建人
    yx_table.identity_id  = tonumber(param_table.identity_id);     --创建人身份
    yx_table.scheme_id    = tonumber(param_table.scheme_id);       --教材版本ID
    yx_table.structure_id = tonumber(param_table.structure_id);    --教材章节目录
    yx_table.subject_id   = tonumber(param_table.subject_id);      --学科ID
    yx_table.yx_conent    = param_table.yx_conent;                 --预习说明
    yx_table.is_delete    = 0;                                     --是否删除 0：未删除 1:删除
    yx_table.is_public    = tonumber(param_table.is_public);       --是否发布 1：发布 0表示未发布
    return yx_table;
end
--[[
	局部函数：组装预习表的insert语句
]]
function _YX:getYxInsertSql(yx_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local yxtoperson_id = SSDBUtil:incr("t_yx_yxtoperson_pk");
    SSDBUtil:multi_hset("yxx_yxtoperson_"..yxtoperson_id,yx_table);
    local k_v_table = tableUtil:convert_sql(yx_table);
    local insert_sql = "START TRANSACTION;"..
                       "delete from t_cp_info where cp_type_id=2 and bus_id="..yx_table.yx_id..";"..
                       "delete from t_yx_info where yx_id="..yx_table.yx_id..";"..
                       "insert into t_yx_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"..
                       "insert into t_yx_person(id,yx_id,person_id,identity_id,bureau_id,class_id,group_id,update_ts) value("..
                                                yxtoperson_id..","..yx_table.yx_id..",0,0,0,0,0,"..TS.getTs()..");"..
                       "COMMIT;";
    SSDBUtil:keepAlive();
    return insert_sql;
end
--[[
	局部函数：获得预习详情，通过预习ID
	参数：预习ID
]]
function _YX:getYxDetail(yx_id)
    local cjson = require "cjson";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local ssdb_db = SSDBUtil:getDb()
    local yx_detail_encode = ssdb_db:hget("preparation_yx_info",yx_id);
    local yx_detail_table = {};
    if yx_detail_encode ~= "ok" and yx_detail_encode[1] and string.len(yx_detail_encode[1])>0 then
        yx_detail_table = cjson.decode(yx_detail_encode[1]);
        if yx_detail_table then
            local train_list = yx_detail_table.train_list;
            for i=1,#train_list do
                local material_list = train_list[i].material_list;
                for j=1,#material_list do
                    local resource_id = material_list[j].resource_id;
                    local resource_type = material_list[j].resource_type;
                    if resource_type then
                        if tonumber(resource_type) == 1 or tonumber(resource_type) == 4 then
                            --todo 资源/备课 start
                            local myjson = ssdb_db:hgetall("resource_"..resource_id);
                            if myjson[1] == "ok" then
                                myjson = ssdb_db:hgetall("myresource_"..resource_id);
                            end
                            for z=2,#myjson,2 do
                                material_list[j][tostring(myjson[z-1])] = myjson[z];
                            end
                            --todo 资源/备课 end
                        elseif tonumber(resource_type) == 2 then
                            --todo 微课 start
                            local wkds_info = ngx.location.capture("/dsideal_yy/ypt/wkds/getwkdsInfo",{args={id=resource_id}});
                            if wkds_info.status == 200 then
                                material_list[j].resource_info = cjson.decode(wkds_info.body);
                            end
                            --todo 微课 end
                        elseif tonumber(resource_type) == 3 then
                            local paper_source = material_list[j].paper_source;
                            if paper_source and tonumber(paper_source) == 2 then
                                --todo 非格式化试卷 start
                                local papers = ngx.location.capture("/dsideal_yy/ypt/paper/getInfoByPaperId",{args={id=resource_id,paper_type=2}});
                                if papers.status ~= 200 then
                                    papers = ngx.location.capture("/dsideal_yy/ypt/paper/getInfoByPaperId",{args={id=resource_id,paper_type=1}});
                                end
                                if papers.status == 200 then
                                    material_list[j].resource_info = cjson.decode(papers.body);
                                end
                                --todo 非格式化试卷 end
                            end
                        end
                    end
                end
            end
        end
    end
    SSDBUtil:keepAlive();
    return yx_detail_table;
end
return _YX;