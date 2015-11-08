> **首页备课工具gzip方式接口说明**


区分登录与非登录

 1. 请求地址：

 http://10.10.3.199/dsideal_yy/space/baktools/space_30164_5_data.json?login=1&person_id=30164&identity_id=5

 2. 参数说明：

请求地址中space_30164_5_data.json也是采用space_{person_id}_{identity_id}_data.json
   

        login       是否登录状态，1登录，2未登录.
        person_id   用户id.
        identity_id 身份id.




*重新生成ts值接口*

 1. 前台接口

 http://10.10.3.199/dsideal_yy/space/update_baktools/updatets?person_id=30164&identity_id=5

 2. 后台接口：

     

      local service = require("space.gzip.service.BakToolsUpdateTsService")
      local b = service.updateTs(person_id,identity_id) 返回true 或false

> **首页互动工具gzip方式接口说明**
> 
区分登录与非登录

 1. 请求地址：

 http://10.10.3.199/dsideal_yy/space/interaction/space_30164_5_interaction_data.json?login=1&person_id=30164&identity_id=5

 2. 参数说明：

请求地址中space_30164_5_interaction_data.json也是采用space_{person_id}_{identity_id}_interaction_data.json
   

        login       是否登录状态，1登录，2未登录.
        person_id   用户id.
        identity_id 身份id.




*重新生成ts值接口*

 1. 前台接口

 http://10.10.3.199/dsideal_yy/space/update_interaction/updatets?person_id=30164&identity_id=5

 2. 后台接口：

     

      local service = require("space.gzip.service.InteractionToolsUpdateTsService")
      local b = service.updateTs(person_id,identity_id) 返回true 或false