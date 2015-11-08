local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比ID
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

local rating_type
if args["rating_type"] == nil or args["rating_type"] == "" then
  rating_type = 1
else
  rating_type = args["rating_type"]
end
ngx.log(ngx.ERR, "===================================================="..rating_type)

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = args["w_type"]
end


local xxGood,czGood,gzGood
if rating_type == 1 then

xxGood,czGood,gzGood = ngx.location.capture_multi({
        {"/dsideal_yy/rating/beforeGoodResByRatingId?rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=4&subject_id=-1&award_id=1&random="..math.random(1000)},
        {"/dsideal_yy/rating/beforeGoodResByRatingId?rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=5&subject_id=-1&award_id=1&random="..math.random(1000)},
		{"/dsideal_yy/rating/beforeGoodResByRatingId?rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=6&subject_id=-1&award_id=1&random="..math.random(1000)},
})
else
xxGood,czGood,gzGood = ngx.location.capture_multi({
        {"/dsideal_yy/rating/beforeGoodResByRatingId?w_type="..w_type.."&rating_type="..rating_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=4&subject_id=-1&award_id=1&random="..math.random(1000)},
        {"/dsideal_yy/rating/beforeGoodResByRatingId?w_type="..w_type.."&rating_type="..rating_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=5&subject_id=-1&award_id=1&random="..math.random(1000)},
		{"/dsideal_yy/rating/beforeGoodResByRatingId?w_type="..w_type.."&rating_type="..rating_type.."&rating_id="..rating_id.."&pageNumber=1&pageSize="..show_size.."&stage_id=6&subject_id=-1&award_id=1&random="..math.random(1000)},
})
end
local result = {}
result["success"] = true
result["xxGood"] = cjson.decode(xxGood.body).list
result["czGood"] = cjson.decode(czGood.body).list
result["gzGood"] = cjson.decode(gzGood.body).list

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

