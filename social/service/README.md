接口说明
------------------------------------------
获取区的service.
local partitionService = require("social.service.CommonPartitionService")
获取版块的service
local forumService = require("social.service.CommonForumService")


获取BBS service
local bbsService = require("social.service.BbsService")
1.区域保存
  函数 :savePartition
  参数 :bbs_id    论坛id.
         name      区域name
         sequence  排序
         type_id   类型id.
         type      类型 1 bbs,2 留言,3 区域均衡
  返回值:无
  异常 :出错
2.区域修改
    函数 : updatePartition
    参数 : name           区域name
           partition_id   区域id
    返回值:无
    异常 :出错
3.区域删除
    函数 : deletePartition
    参数 : partition_id   区域id
    返回值:无
    异常 :出错
4.区域恢复删除
    函数 : recoveryPartition
    参数 : partition_id   区域id
    返回值:无
    异常 :出错
5.通过id获取区域
    函数 : getPartitionById
    参数 : partition_id   区域id
    返回值:类型 table
           partition_id   区域id
           bbs_id         论坛id
           name           区域名称.
           sequence       区域排错.
           type           类型。
           type_id        类型id.
    异常 :出错

------------------------------------------------------------------------------------------------------------------------
6.版块保存
    函数 :saveForum
    参数 : table类型.
          {
                  bbs_id = param.bbs_id, --论坛id
                  partition_id = param.partition_id, --区域id
                  name = param.name,--版块名称.
                  icon_url = param.icon_url,--版块url
                  description = param.description,--版块说明 可以为空.
                  sequence = param.sequence, -- 排序.
                  type_id = param.type_id, --类型id.
                  type = param.type  --类型1 bbs,2 留言,3 区域均衡
         }
    返回值:无
    异常 :出错
7.版块修改
    函数 :updateForum
    参数 : table类型.
              {
                      bbs_id = param.bbs_id, --论坛id
                      partition_id = param.partition_id, --区域id
                      name = param.name,--版块名称.
                      icon_url = param.icon_url,--版块url
                      description = param.description,--版块说明 可以为空.
                      sequence = param.sequence, -- 排序.
                      type_id = param.type_id, --类型id.
                      type = param.type  --类型1 bbs,2 留言,3 区域均衡
             }
    返回值:无
    异常 :出错
8.版块删除
    函数 :deleteForum
    参数 :forum_id 版块id.
    返回值:无
    异常 :出错
9.版块恢复删除
    函数 :recoveryForum
    参数 :forum_id 版块id.
    返回值:无
    异常 :出错
10.通过版块id获取版块信息.
    函数 :getForumById
    参数 :forum_id 版块id.
    返回值:table类型 key value
                  forum_id --版块id.
                  partition_id  --区域id
                  bbs_id   --bbsid.
                  name   --版块名称
                  icon_url --版块url
                  description --版块说明
                  sequence ---- 排序.
                  type --类型1 bbs,2 留言,3 区域均衡
                  type_id  --类型id.
    异常 :出错
11.通过区域id获取bbs所有信息。bbsService.
   函数 :getBbsByRegionId
   参数 :regionId 区域id.
   返回值:table

