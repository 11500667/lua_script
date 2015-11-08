local cookie_person_id = tostring(ngx.var.cookie_person_id)

--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson"

local today = os.date("%Y%m%d")

local res = ngx.location.capture("/dsideal_yy/ypt/workroom/getWorkroomByPersonId?person_id="..cookie_person_id)
local str =  cjson.decode(res.body)
local workroom_ids = str.workroom_ids
if workroom_ids ~= "" then
    local wr_id = Split(workroom_ids,",")
    for i=1,#wr_id do        
        --获取工作室今天是几号
        local wr_today = db:hget("workroom_tj_"..wr_id[i],"today")[1]
        --判断工作室今天的属性值和现实今天是不是一样
        if wr_today == today then
            --一样的话today_upload+1
            db:hincr("workroom_tj_"..wr_id[i],"today_upload") 
        else
            --不一样就把today改成一样的，再将today_upload重置为1
            db:hset("workroom_tj_"..wr_id[i],"today",today)
            db:hset("workroom_tj_"..wr_id[i],"today_upload","1")
        end
        --资源总数+1
        db:hincr("workroom_tj_"..wr_id[i],"resource_count")

        --更新记录统计json的TS值
        local  tj_ts = math.random(1000000)..os.time()
        db:set("workroom_tj_ts_"..wr_id[i],tj_ts)
    end
end


--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":ture}")