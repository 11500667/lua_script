/*新闻通知公告分类表*/
CREATE TABLE `t_space_notice_category` (
   `category_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
   `category_name` varchar(100) DEFAULT NULL COMMENT '分类名称',
   `register_id` int(11) DEFAULT NULL COMMENT '注册号',
   `create_time` datetime DEFAULT NULL COMMENT '注册时间',
   `parent_id` int(11) DEFAULT '-1' COMMENT '父id',
   `b_delete` int(11) DEFAULT '0' COMMENT '删除标志，默认0,1表示删除',
   PRIMARY KEY (`category_id`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8

/*新闻通知公告内容表*/
CREATE TABLE `t_space_notice` (
   `notice_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
   `title` varchar(100) DEFAULT NULL COMMENT '新闻通知公告标题',
   `overview` varchar(200) DEFAULT NULL COMMENT '概述，概要说明，比标题长',
   `person_id` int(11) DEFAULT NULL COMMENT '创建人id',
   `identity_id` int(11) DEFAULT NULL COMMENT '创建人身份id',
   `create_time` datetime DEFAULT NULL COMMENT '创建时间',
   `content` longtext COMMENT '新闻通知公告内容',
   `category_id` int(11) DEFAULT '-1' COMMENT '分类id',
   `org_id` int(11) DEFAULT NULL COMMENT '新闻所属机构id，通常是创建人的所属机构吧',
   `org_type` int(11) DEFAULT NULL COMMENT '所属机构类型，因org_id可能重复才加的这个字段，101表示省，102市，103区，104校，105班级，106群组，需要再加',
   `register_id` int(11) DEFAULT NULL COMMENT '注册号',
   `ts` bigint(20) DEFAULT NULL,
   `update_ts` bigint(20) DEFAULT NULL,
   `thumbnail` int(11) DEFAULT NULL COMMENT '缩略图对应的resource_info_id',
   `attachments` varchar(1000) DEFAULT NULL COMMENT '附件对应的resource_info_id，多个使用逗号分隔',
   `view_count` int(11) DEFAULT '0' COMMENT '浏览次数',
   `b_delete` int(11) DEFAULT '0' COMMENT '删除标志，默认0,1表示删除',
   PRIMARY KEY (`notice_id`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8

/*通知发送表，内容与发送是一对多关系*/
CREATE TABLE `t_space_notice_receive` (
   `receive_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
   `notice_id` int(11) DEFAULT NULL COMMENT '新闻通知公告id',
   `create_time` datetime DEFAULT NULL COMMENT '发送时间',
   `receive_person_id` int(11) DEFAULT NULL COMMENT '接收人id，也可以是机构id',
   `receive_identity_id` int(11) DEFAULT NULL COMMENT '接收人身份id，接收者是机构时101、102、103分别表示省、市、区教育局，104表示学校，105表示班级，106表示群组，需要再加',
   `read_flag` int(11) DEFAULT '0' COMMENT '已读标识，默认0未读,1表示已读',
   `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
   `receipt_flag` int(11) DEFAULT '0' COMMENT '回执标识，默认0未回执，1表示已回执',
   `receipt_info` varchar(200) DEFAULT NULL COMMENT '回执信息',
   `receipt_time` datetime DEFAULT NULL COMMENT '回执时间',
   `b_delete` int(11) DEFAULT '0' COMMENT '删除标志，默认0,1表示删除',
   PRIMARY KEY (`receive_id`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8



#申请注册号，注册号使用ssdb存储，ssdb:incr(space_notice_register_id)
location /dsideal_yy/ypt/notice/applyRegisterId{
    content_by_lua_file /usr/local/lua_script/space/notice/applyRegisterId.lua;
}

#新闻通知公告分类维护
#添加分类 编辑分类
#查询分类，不分页
#删除分类，标志删除，有子分类的分类禁止删除
location /dsideal_yy/ypt/notice/addCategory{
    content_by_lua_file /usr/local/lua_script/space/notice/addCategory.lua;
}
location /dsideal_yy/notice/getCategoryById{
    content_by_lua_file /usr/local/lua_script/space/notice/getCategoryById.lua;
}
location /dsideal_yy/ypt/notice/editCategory{
    content_by_lua_file /usr/local/lua_script/space/notice/editCategory.lua;
}
location /dsideal_yy/ypt/notice/deleteCategory{
    content_by_lua_file /usr/local/lua_script/space/notice/deleteCategory.lua;
}
location /dsideal_yy/notice/getCategoriesByParentId{
    content_by_lua_file /usr/local/lua_script/space/notice/getCategoriesByParentId.lua;
}
location /dsideal_yy/notice/getCategoriesByRegisterId{
    content_by_lua_file /usr/local/lua_script/space/notice/getCategoriesByRegisterId.lua;
}

#添加新闻、通知公告
#编辑新闻、通知公告
#删除新闻、通知公告
location /dsideal_yy/ypt/notice/addNotice{
    content_by_lua_file /usr/local/lua_script/space/notice/addNotice.lua;
}
location /dsideal_yy/notice/getNoticeById{
    content_by_lua_file /usr/local/lua_script/space/notice/getNoticeById.lua;
}
location /dsideal_yy/ypt/notice/editNotice{
    content_by_lua_file /usr/local/lua_script/space/notice/editNotice.lua;
}
location /dsideal_yy/ypt/notice/deleteNoticeByIds{
    content_by_lua_file /usr/local/lua_script/space/notice/deleteNoticeByIds.lua;
}
#查询新闻、通知公告，分页，sphinx
#（1）	按时间倒序查询，
#（2）	按浏览次数查询，
#（3）	按机构查询，
#（4）	按接收人接收机构查询，
#（5）	按标题或内容模糊查询，
location /dsideal_yy/notice/getNoticeList{
    content_by_lua_file /usr/local/lua_script/space/notice/getNoticeList.lua;
}

#更改已读标识
#通知回执
location /dsideal_yy/ypt/notice/updateReadFlag{
    content_by_lua_file /usr/local/lua_script/space/notice/updateReadFlag.lua;
}
location /dsideal_yy/ypt/notice/updateReceiptFlag{
    content_by_lua_file /usr/local/lua_script/space/notice/updateReceiptFlag.lua;
}

#浏览次数加1
location /dsideal_yy/notice/viewCount{
    content_by_lua_file /usr/local/lua_script/space/notice/viewCount.lua;
}


