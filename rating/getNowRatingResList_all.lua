local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--rating_id
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--显示多少条
if args["show_size"] == nil or args["show_size"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"show_size参数错误！\"}")
    return
end
local show_size = args["show_size"]

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = args["w_type"]
end


local xxRw,czRw,gzRw,zjRw = ngx.location.capture_multi({
        {"/dsideal_yy/rating/getNowRatingResList?w_type="..w_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=4&subject_id=-1&scheme_id=-1&structure_id=-1&israting=-1&random="..math.random(1000)},
        {"/dsideal_yy/rating/getNowRatingResList?w_type="..w_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=5&subject_id=-1&scheme_id=-1&structure_id=-1&israting=-1&random="..math.random(1000)},
		{"/dsideal_yy/rating/getNowRatingResList?w_type="..w_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=6&subject_id=-1&scheme_id=-1&structure_id=-1&israting=-1&random="..math.random(1000)},
		{"/dsideal_yy/rating/getNowRatingResList?w_type="..w_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=7&subject_id=-1&scheme_id=-1&structure_id=-1&israting=-1&random="..math.random(1000)},
})

local result = {}
result["success"] = true
result["xxRw"] = cjson.decode(xxRw.body).list
result["czRw"] = cjson.decode(czRw.body).list
result["gzRw"] = cjson.decode(gzRw.body).list
result["zjRw"] = cjson.decode(zjRw.body).list

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

