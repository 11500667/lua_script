--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
local cjson =  require "cjson";
local MysqlUtil = require "common.MysqlUtil";
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local Subject = tonumber(args["Subject"]);--学科ID
local TopicName = args["TopicName"];	--专题名称
local TopicType = args["TopicType"];	--专题类型
local file_id = args["file_id"];		--文件ID
local v_fileext = args["v_fileext"];	--扩展名  不需要.
local thumb_id = args["thumb_id"];		--文件ID
local v_thumbext = args["v_thumbext"];	--缩略图扩展名  不需要.
local sql ="insert into t_xx_topic(topicname,subjectid,typeid,viewcount,downcount,score,createtime,swfurl,htmlurl,thumburl) values(";
sql=table.concat({sql,"'"..TopicName.."',"});
sql=table.concat({sql,Subject..","});
sql=table.concat({sql,TopicType..",0,0,0,now(),'"});
sql=table.concat({sql,file_id.."."..v_fileext.."',"});
sql=table.concat({sql,"-1,'"..thumb_id.."."..v_thumbext.."')"});
--ngx.log(ngx.ERR, '0000000000000000000000000000'..tostring(sql)..'000000000000000000000000000000000000000000');
MysqlUtil:query(sql);
MysqlUtil:close();
say("{\"success\":true,\"info\":\"上传成功\"}")