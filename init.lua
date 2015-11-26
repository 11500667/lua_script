package.path = package.path .. ";/usr/local/lua_script/?.lua;/usr/local/lua_script_sfssxw/?.lua;/usr/local/lua_script_yx/?.lua;";

-- 直接在加载时引用常用的lua文件
g_cjson = require "cjson";
g_cjson.encode_empty_table_as_object(false);
require "common.PublicFunction";
BaseController = require "common.BaseController";

require "aeslua"

--Split方法
function Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
       local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
       if not nFindLastIndex then
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
        break
       end
       nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
       nFindStartIndex = nFindLastIndex + string.len(szSeparator)
       nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

--redis全局变量
v_redis_ip="127.0.0.1"
v_redis_port="6379"

--mysql全局变量
v_mysql_ip="10.10.6.199"
v_mysql_port="3306"
v_mysql_database="dsideal_db"
v_mysql_user="root"
v_mysql_password="dsideal"

--ssdb全局变量
v_ssdb_ip = "127.0.0.1"
v_ssdb_port = "8888"

--池大小
v_pool_size = "100"

--统一认证全局变量
v_cas_path="10.10.3.25:8030"

-- 组织机构共享设置
v_share_range = {
    { range_id = 0, name = "全国",   display = true, redis_key = "all", input_id = "share_all"}, 
    { range_id = 1, name = "本省",   display = true, redis_key = "sheng", input_id = "share_sh"}, 
    { range_id = 2, name = "本市",   display = true, redis_key = "shi", input_id = "share_shi"}, 
    { range_id = 3, name = "本区",   display = true, redis_key = "qu", input_id = "share_are"}, 
    { range_id = 4, name = "本校",   display = true, redis_key = "xiao", input_id = "share_sch"} 
 --   { range_id = 5, name = "学科组", display = false, redis_key = "bm"} 
};

-- 云资源、云备课、云微课、云试卷、云试题等模块查询时的范围
v_query_range = {
    { name = "全部范围", display = true  , query_key=0 }, 
    { name = "东师理想", display = true  , query_key=1 }, 
    { name = "本省",     display = false , query_key=6, redis_key = "sheng"}, 
    { name = "本市",     display = true  , query_key=7, redis_key = "shi"}, 
    { name = "本区",     display = true  , query_key=2, redis_key = "qu"}, 
    { name = "本校",     display = true  , query_key=3, redis_key = "xiao"}, 
    { name = "学科组",   display = false , query_key=4, redis_key = "bm"} 
};

-- 我的资源的下标签页的配置项
v_my_info_type = {
    { type_id = 6  , type_name = "我的上传" },
    { type_id = 7  , type_name = "我的共享" },
    { type_id = 1  , type_name = "我的收藏" },
    { type_id = 2  , type_name = "我推荐的资源" },
    { type_id = 3  , type_name = "推荐给我的资源" },
    { type_id = 4  , type_name = "我的评论" },
    { type_id = 5  , type_name = "我的反馈" },
    { type_id = 10 , type_name = "我参评的资源" },
    { type_id = 0  , type_name = "全部" }
}

-- 试卷类型的配置信息
v_config_paper_type = {
    { type_id = 0  , type_name = "全部格式" },
    { type_id = 1  , type_name = "格式化试卷" },
    { type_id = 2  , type_name = "非格式化试卷" }
}

-- 可排序字段的设置：
v_config_sort_field = {
    zy = {
        { field_name = "媒体类型" , sort_type = 4 },
        { field_name = "时间"     , sort_type = 1 },
        { field_name = "下载次数" , sort_type = 3 }
    },
    sj = {
        { field_name = "格式类型" , sort_type = 2 },
        { field_name = "存档时间" , sort_type = 3 }
    },
    bk = {
        { field_name = "类型"     , sort_type = 4 },
        { field_name = "格式"     , sort_type = 5 },
        { field_name = "时间"     , sort_type = 1 },
        { field_name = "下载次数" , sort_type = 3 }
    },
    wk = {
        { field_name = "播放次数" , sort_type = 2 },
        { field_name = "播放时间" , sort_type = 4 }
    },
    sort_value = {
        asc  = 1,
        desc = 2 
    }
};


-- 是否允许共享给群组
v_share_group = true;


--教研存储html路径
v_yx_htmlPath = "/usr/local/tomcat7/webapps/dsideal_yy/yx/html/"

--配置局版和云版 1是云版 2是局版
v_pt_type = 2;
