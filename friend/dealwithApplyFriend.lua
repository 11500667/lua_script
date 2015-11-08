--[[
接受或拒绝好友申请
@Author feiliming
@Date   2015-4-2
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--get args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--local person_id = args["person_id"]
--local identity_id = args["identity_id"]
local apply_id = args["apply_id"]
local deal_flag = args["deal_flag"]
if not apply_id or len(apply_id) == 0 or
	not deal_flag or len(deal_flag) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--mysql
local mysql, err = mysqllib:new()
if not mysql then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local ok, err = mysql:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取person_name的区位码, 调用java接口
local function getQuweima(person_name)
    local quwei
    local res_quwei = ngx.location.capture("/getQuwei", {
        args = { person_name = person_name }
    })
    if res_quwei.status == 200 then
        quwei = cjson.decode(res_quwei.body)
    else
        return false, "获取姓氏区位码失败！"
    end
    return quwei.quwei
end

--判断默认分组是否存在，存在返回默认分组id，不存在则插入默认分组，然后返回默认分组id
local function getDefaultGroupId(person_id, identity_id)
    local group_id = 0
    local ssql = "select group_id from t_social_friend_group where person_id = "..person_id.." and identity_id = "..identity_id.." and group_type = 1"
    local sresult, err = mysql:query(ssql)
    if not sresult then
        return false, err
    end
    if sresult and #sresult == 0 then
        --insert mysql
        group_id = ssdb:incr("t_social_friend_group_pk")[1]
        local group_type = 1
        local isql = "insert into t_social_friend_group(group_id, group_name, person_id, identity_id, group_type, sequence) values ("..
            group_id..", '我的好友' ,"..person_id..","..identity_id..","..group_type..", 0)"
        local iresutl, err = mysql:query(isql)
        if not iresutl then
            return false, err
        end
        --insert ssdb
        local group = {}
        group.group_id = group_id
        group.group_name = "我的好友"
        group.person_id = person_id
        group.identity_id = identity_id
        group.group_type = group_type
        group.sequence = 0

        ssdb:multi_hset("social_friend_group_"..group_id, group)
        ssdb:zset("social_friend_group_sorted_"..identity_id.."_"..person_id, group_id, 0)
    else
        group_id = sresult[1].group_id
    end
    return group_id
end

--插入我的好友到mysql和ssdb
local function insertMyFriend( person_id, identity_id, fperson_id, fidentity_id, quweima )
    --ngx.log(ngx.ERR, "=="..person_id.."=="..identity_id.."=="..fperson_id.."=="..fidentity_id.."=="..quweima)
    --判断是否已是我的好友
    local friending1 = ssdb:hexists("social_friend", identity_id.."_"..person_id.."_"..fidentity_id.."_"..fperson_id)
    if friending1 and friending1[1] == "1" then
        return false, "已经是好友关系！"
    end

    --获取默认分组
    local group_id, err = getDefaultGroupId(person_id, identity_id)
    if not group_id then
        return false, err
    end

    local friend_id = ssdb:incr("t_social_friend_pk")[1]
    local create_time = os.date("%Y-%m-%d %H:%M:%S")
    local ts = os.date("%Y%m%d%H%M%S")
    --mysql
    local isql = "insert into t_social_friend(friend_id, person_id, identity_id, group_id, fperson_id, fidentity_id, create_time, sequence)"..
        "values("..friend_id..","..person_id..","..identity_id..","..group_id..","..fperson_id..","..fidentity_id..","..quote(create_time)..","..quweima..")"
    local iresutl, err = mysql:query(isql)
    if not iresutl then
        return false, err
    end
    --ssdb
    local friend = {}
    friend.friend_id = friend_id
    friend.person_id = person_id
    friend.identity_id = identity_id
    friend.fperson_id = fperson_id
    friend.fidentity_id = fidentity_id
    friend.group_id = group_id
    friend.create_time = create_time
    friend.sequence = quweima
    --1好友,2全部好友排序,3分组好友排序,4好友标志
    ssdb:multi_hset("social_friend_"..friend_id, friend)
    ssdb:zset("social_friend_sorted_"..identity_id.."_"..person_id, friend_id, quweima) 
    ssdb:zset("social_friend_group_friend_sorted_"..group_id, friend_id, quweima)
    ssdb:hset("social_friend", identity_id.."_"..person_id.."_"..fidentity_id.."_"..fperson_id, 1)

    --2015-8-21更新张海的gzip的ts值
    --local service = require "space.gzip.service.InteractiveToolsUpdateTsService"
    --service.updateTs(person_id,identity_id)
    --service.updateTs(fperson_id,fidentity_id)
    return true
end

--删除申请信息
local function deleteApply( apply_id, person_id, identity_id, fperson_id, fidentity_id)
    --ngx.log(ngx.ERR, "=="..apply_id.."=="..person_id.."=="..identity_id.."=="..fperson_id.."=="..fidentity_id)
    --删除mysql申请信息
    local dsql = "delete from t_social_friend_apply where apply_id = "..apply_id
    local dresutl, err = mysql:query(dsql)
    if not dresutl then
        return false, err
    end
    --删除ssdb申请信息, 1好友申请,2好友申请排序,3申请标示
    ssdb:hclear("social_friend_apply_"..apply_id)
    ssdb:zdel("social_friend_apply_sorted_"..fidentity_id.."_"..fperson_id, apply_id)
    ssdb:hdel("social_friend_apply", identity_id.."_"..person_id.."_"..fidentity_id.."_"..fperson_id)

    return true
end

--return
local rr = {}
rr.success = true

local t0 = ssdb:multi_hget("social_friend_apply_"..apply_id, "identity_id", "person_id", "fidentity_id", "fperson_id", "apply_time")
local identity_id = t0[2]
local person_id = t0[4]
local fidentity_id = t0[6]
local fperson_id = t0[8]

--deal_flag=1接受请求
if deal_flag == "1" then
    --1.加对方为我的好友
    --1.1获取对方用户名称
    local pim = require "base.person.model.PersonInfoModel"
    local fperson_t = pim:getPersonDetail(fperson_id, fidentity_id)
    if not fperson_t then
        say("{\"success\":false,\"info\":\"读取用户信息时失败！\"}")
        return
    end
    --1.2获取person_name的区位码
    local fperson_name = fperson_t.person_name
    local quweima, err = getQuweima(fperson_name)
    if not quweima then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --1.3插入我的好友
    local result, err = insertMyFriend(person_id, identity_id, fperson_id, fidentity_id, quweima)
    if not result then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    --2.加我为对方好友
    --2.1获取我的名称
    local pim = require "base.person.model.PersonInfoModel"
    local person_t = pim:getPersonDetail(person_id, identity_id)
    if not person_t then
        say("{\"success\":false,\"info\":\"读取用户信息时失败！\"}")
        return
    end
    --2.2获取我的person_name的区位码
    local person_name = person_t.person_name
    local quweima, err = getQuweima(person_name)
    if not quweima then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --2.3插入我为对方的好友
    local result, err = insertMyFriend(fperson_id, fidentity_id, person_id, identity_id, quweima)
    if not result then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end    

    --删除申请信息
    local dresutl, err = deleteApply(apply_id, person_id, identity_id, fperson_id, fidentity_id)
    if not dresutl then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
 
    rr.info = "已互相加为好友！"
--deal_flag=2拒绝请求
elseif deal_flag == "2" then
    --以后加发送消息

    --删除申请信息
    local dresutl, err = deleteApply(apply_id, person_id, identity_id, fperson_id, fidentity_id)
    if not dresutl then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end

    rr.info = "已拒绝对方为好友！"
else
    say("{\"success\":false,\"info\":\"deal_flag参数错误！\"}")
    return
end

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)