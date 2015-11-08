-- ngx.header["Content-Type"] = "text/plain"

local cjson =  require "cjson";
local MysqlUtil = require "common.MysqlUtil";
local upload = require "resty.upload"
local uuid =  require "resty.uuid";
local file_id = uuid.new();
local thumb_id = uuid.new();

-- 注意下目录：mkdir /usr/local/tomcat7/webapps/dsideal_yy/html/yxx/xx/topic/file -p 的写权限，
-- 一般可以 chmod 777 /usr/local/tomcat7/webapps/dsideal_yy/html/yxx/xx/topic/file/ 即可。
local chunk_size = 4096 
local form = upload:new(chunk_size) 

ngx.log(ngx.ERR,"@@@@@@@@@@@@@@####################"..tostring(form));


local file 
local filelen=0 
form:set_timeout(0) -- 1 sec 
local filename 

function get_filename(res) 
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)') 
    if filename then  
        return filename[2] 
    end 
end 
-- 分隔字符串的办法
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
--获取扩展名
function getExtension(str)
    return str:match(".+%.(%w+)$")
end

local args={}

-- 上传路径
local osfilepath = "/usr/local/tomcat7/webapps/dsideal_yy/html/yxx/xx/topic/file/" 
local i=0 
local v_filepath="";
local v_thumbpath="";
local v_fileext="";
local v_thumbext="";

while true do     
    local typ, res, err = form:read() 
    if not typ then 
        -- ngx.say("failed to read: ", err) 
        return 
    end 
    
    local arg=nil;
    
    if typ == "header" then 
        
        if res[1] ~= "Content-Type" then      
             
            -- 参数名称： 
            local list=Split(res[2],"\"");

            if(list[1]=="form-data; name=")  then 
                arg=list[2];              
            end
            
            filename = get_filename(res[2])                   
            if filename then                 
                i=i+1 
                
                if i==1 then                     
                    v_thumbext=getExtension(filename)      
                    v_thumbpath = osfilepath  .. thumb_id.."."..v_thumbext
                    file = io.open(v_thumbpath,"w+") 
                else
                    v_fileext=getExtension(filename)      
                    v_filepath= osfilepath  .. file_id..".".. v_fileext
                    file = io.open(v_filepath,"w+") 
                end
                
                if not file then 
                    -- ngx.say("failed to open file ")                     
                    return 
                end 
            else 
            end 
        end 
    elseif typ == "body" then 
            
        if file then 
            filelen= filelen + tonumber(string.len(res))     
            file:write(res)             
        else 
            arg=res;    
        end 
    elseif typ == "part_end" then 
        if file then 
            file:close() 
            file = nil 
            -- ngx.say("file upload success")          
        end 
    elseif typ == "eof" then 
        break 
    else
    end    

    if(arg~=nil) then        
        table.insert(args, tostring(arg));            
    end
end 


local result={};
local i=1;
for i=1, #args,2 do      
    result[args[i]]=args[i+1];
end 

local Stage=ngx.quote_sql_str(result["Stage"]);
local Subject=ngx.quote_sql_str(result["Subject"]);
local TopicName=ngx.quote_sql_str(result["TopicName"]);

local sql ="insert into t_xx_topic(topicname,subjectid,typeid,viewcount,downcount,score,createtime,swfurl,htmlurl,thumburl) values(";
sql=table.concat({sql,TopicName..","});
sql=table.concat({sql,Subject..","});
sql=table.concat({sql,"-1,0,0,0,now(),'"});
sql=table.concat({sql,file_id.."."..v_fileext.."',"});
sql=table.concat({sql,"-1,'"..thumb_id.."."..v_thumbext.."')"});

MysqlUtil:query(sql);
MysqlUtil:close();

-- 跳转
local location="/dsideal_yy/html/yxx/xx/topic/UploadOk.html?Stage="..result["Stage"].."&Subject="..result["Subject"];
ngx.redirect(location)
   
   




