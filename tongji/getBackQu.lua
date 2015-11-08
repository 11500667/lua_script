ngx.header.content_type = "text/plain;charset=utf-8"

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取市ID的参数
local shi_id = args["shi_id"]
--获取区ID的参数
local qu_id = args["qu_id"]

local cjson = require "cjson"
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local sys = {"zy","st","sj","bk","wk"}

--将zset的key,score二维数组转只有key的一维数组
function array_2_1(table)
    local array_1 = {}
    local x = 1
    for i=1,#table,2 do
        array_1[x] = table[i]
        x = x+1
    end
    return array_1
end

 local school_list = {}
local all = {}

--获取有哪些学段
local stage_list = ssdb_db:zrange("stage_list",0,-1)
for i=1,#stage_list,2 do
    local stage_tab = {}
    --获取学段ID
    local stage_id = stage_list[i];
    local stage_name = ssdb_db:hget("stage_"..stage_id,"stage_name")[1]
    --
    local attr_title = {}
    --区域加学科的数组
    local subject_tab = {}
    subject_tab[1]="学校"
    --根据学段获取该学科有哪些学科
    local subject_list_zset = ssdb_db:zrange("subject_list_"..stage_id,0,-1)
    local subject_list = array_2_1(subject_list_zset) 
    for j=1,#subject_list do
        --获取学科ID
        local subject_id = subject_list[j]
        --获取学科名称        
        local subject_name = ssdb_db:hget("subject_"..subject_id,"subject_name")[1]
        subject_tab[j+1] = subject_name
    end
    subject_tab[#subject_list+2]="合计"
    attr_title["attr_title"] = subject_tab

    local arr_sys = {}
    for n=1,#sys do
    local sys_str = {}
    --
    local arr_filecount = {}    
    local filecount = {}
    --
    local arr_filesize = {}
    local filesize = {}
    local res = ngx.location.capture("/dsideal_yy/ypt/region/getSchoolByDistrict?district_id="..qu_id.."&stage_id="..stage_id)
    local str =  cjson.decode(res.body)
    school_list = str.table_list
    for j=1,#school_list do
        --区名和各科的文件个数数组
          local filecount_tab = {}
          --区名和各科的文件大小数组
        local filesize_tab = {}
        local school_id = school_list[j].school_id
        local school_name = school_list[j].school_name
        filecount_tab[1] = school_name
        filesize_tab[1] = school_name

        for k=1,#subject_list do
            --获取学科ID
            local subject_id = subject_list[k]
            
            local count = ssdb_db:hget("tj_qu_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..school_id.."_"..stage_id.."_"..subject_id,"resource_count")[1]
            if count == "" then
            count = "0"
        end
        filecount_tab[k+1] = count

        --获取大小
        local size = ssdb_db:hget("tj_qu_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..school_id.."_"..stage_id.."_"..subject_id,"resource_size")[1]     
        if size == "" then
            size = "0"
        end
        filesize_tab[k+1] = size
          end
          --获取个数的合计
          local total_count = ssdb_db:hget("tj_qu_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..school_id.."_"..stage_id,"resource_count")[1]
          if total_count == "" then
              total_count = "0"
          end
          filecount_tab[#subject_list+2] = total_count
          --获取大小的合计
          local total_size = ssdb_db:hget("tj_qu_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..school_id.."_"..stage_id,"resource_size")[1]
          if total_size == "" then
              total_size = "0"
          end 
        filesize_tab[#subject_list+2] = total_size

        filecount[j] = filecount_tab
        filesize[j] = filesize_tab
    end

    arr_filecount["arr_filecount"] = filecount
    arr_filesize["arr_filesize"] = filesize

    sys_str[1] = arr_filecount
    sys_str[2] = arr_filesize

    arr_sys[sys[n]] = sys_str

end
    
    stage_tab[1] = attr_title
    stage_tab[2] = arr_sys
    --stage_tab[2] = arr_filecount
    --stage_tab[3] = arr_filesize

    all[stage_name] = stage_tab
	
    
end

local school_info = {}
for i=1,#stage_list,2 do
	local stage_id = stage_list[i];
	local res = ngx.location.capture("/dsideal_yy/ypt/region/getSchoolByDistrict?district_id="..qu_id.."&stage_id="..stage_id)
    local str =  cjson.decode(res.body)
    school_list = str.table_list
	school_info[stage_id] = school_list
end

all["xiao_list"] = school_info

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.say(tostring(cjson.encode(all)))

