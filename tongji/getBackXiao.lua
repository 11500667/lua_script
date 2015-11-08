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
--获取校ID的参数
local xiao_id = args["xiao_id"]

local cjson = require "cjson"
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

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

local sys = {"zy","st","sj","bk","wk"}
local mtype = {}
--资源类型（2：图片  3：文本  4：视频  5：音频  6：其他）
local t_type = {{id="2",name="图片"},{id="3",name="文本"},{id="4",name="视频"},{id="5",name="音频"},{id="6",name="其他"}}
local sjtype = {{id="1",name="格式化试卷"},{id="2",name="非格式化试卷"}}
local other = {{id="-1",name="数量"}}
local bktype = {{id="2",name="数量"}}

local i_count = 1
local all = {}
--获取该学校有哪些学段
local res_school = ngx.location.capture("/dsideal_yy/ypt/region/getStageBySchool?school_id="..xiao_id)
local str_school =  cjson.decode(res_school.body)
local stage_list = str_school.table_list

for i=1,#stage_list do
    local stage_tab = {}
    --获取学段IDqu_list[j].district_id
    local stage_id = stage_list[i].stage_id;
    local stage_name = stage_list[i].stage_name;
	
	
    --
    
    local arr_sys = {}
    for n=1,#sys do
        local attr_title = {}
    local sys_str = {}
    --区域加学科的数组
    local mtype_tab = {}
    mtype_tab[1]="学科"
    if sys[n]=="zy" then
        mtype = t_type
    elseif sys[n]=="sj" then
        mtype = sjtype
	elseif sys[n]=="bk" then
        mtype = bktype
    else
        mtype = other
    end


    for j=1,#mtype do
         --获取学科ID
        local mtype_id = mtype[j].id        
        --获取学科名称        
        local mtype_name = mtype[j].name
        mtype_tab[j+1] = mtype[j].name
    end    
    mtype_tab[#mtype+2]="合计"
    attr_title["attr_title"] = mtype_tab
    
    --
    local arr_filecount = {}    
    local filecount = {}
    --
    local arr_filesize = {}
    local filesize = {}
    local subject_list_zset = ssdb_db:zrange("subject_list_"..stage_id,0,-1)
    local subject_list = array_2_1(subject_list_zset) 
    for j=1,#subject_list do
        --区名和各科的文件个数数组
          local filecount_tab = {}
          --区名和各科的文件大小数组
        local filesize_tab = {}
        local subject_id = subject_list[j]
        local subject_name = ssdb_db:hget("subject_"..subject_id,"subject_name")[1]
        filecount_tab[1] = subject_name
        filesize_tab[1] = subject_name
        for k=1,#mtype do
            --获取学科ID
            local mtype_id = mtype[k].id

            --获取个数
            local count = ssdb_db:hget("tj_xiao_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..xiao_id.."_"..stage_id.."_"..subject_id.."_"..mtype_id,"resource_count")[1]
            if count == "" then
            count = "0"
        end
        filecount_tab[k+1] = count

        --获取大小
        local size = ssdb_db:hget("tj_xiao_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..xiao_id.."_"..stage_id.."_"..subject_id.."_"..mtype_id,"resource_size")[1]     
		
        if size == "" then
            size = "0"
        end
        filesize_tab[k+1] = size
          end
          --获取个数的合计
          local total_count = ssdb_db:hget("tj_xiao_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..xiao_id.."_"..stage_id.."_"..subject_id,"resource_count")[1]
          if total_count == "" then
              total_count = "0"
          end
          filecount_tab[#mtype+2] = total_count
          --获取大小的合计
          local total_size = ssdb_db:hget("tj_xiao_"..sys[n].."_"..shi_id.."_"..qu_id.."_"..xiao_id.."_"..stage_id.."_"..subject_id,"resource_size")[1]
          if total_size == "" then
              total_size = "0"
          end 
        filesize_tab[#mtype+2] = total_size
        filecount[j] = filecount_tab
        filesize[j] = filesize_tab
    end

    arr_filecount["arr_filecount"] = filecount
    arr_filesize["arr_filesize"] = filesize

    sys_str[1] = attr_title
    sys_str[2] = arr_filecount
    sys_str[3] = arr_filesize

    arr_sys[sys[n]] = sys_str


end
    
    --stage_tab[1] = attr_title
    stage_tab[1] = arr_sys
    --stage_tab[2] = arr_filecount
    --stage_tab[3] = arr_filesize

    all[stage_name] = stage_tab
	
    
end

ngx.say(tostring(cjson.encode(all)))


