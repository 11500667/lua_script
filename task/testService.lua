local cjson = require "cjson";
local taskService = require "task.services.TaskService";
local menu_id = 11111
local cur_status = 22222
local returnResult = taskService : getTurnTaskId("1","1");	
--local returnResult = taskService : getTaskId();
cjson.encode_empty_table_as_object(false)
ngx.print(cjson.encode(returnResult))