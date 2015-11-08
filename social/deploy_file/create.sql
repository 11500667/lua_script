-- --------------------------------------------------------
-- 主机:                           10.10.3.199
-- 服务器版本:                        5.5.39-MariaDB - Source distribution
-- 服务器操作系统:                      Linux
-- HeidiSQL 版本:                  9.1.0.4867
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- 导出  表 dsideal_db.t_social_bbs 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs` (
  `id` int(11) NOT NULL COMMENT '主键',
  `region_id` int(11) DEFAULT NULL COMMENT '省市区县校id',
  `name` varchar(100) DEFAULT NULL COMMENT '论坛名称',
  `logo_url` varchar(200) DEFAULT NULL COMMENT 'logo地址',
  `icon_url` varchar(200) DEFAULT NULL COMMENT '图标地址',
  `domain` varchar(100) DEFAULT NULL COMMENT '域名地址',
  `status` int(11) DEFAULT '0' COMMENT '状态，默认0,1关闭',
  `post_today` int(11) DEFAULT '0' COMMENT '今日帖数',
  `post_yestoday` int(11) DEFAULT '0' COMMENT '昨日帖数',
  `total_topic` int(11) DEFAULT '0' COMMENT '总主题数',
  `total_post` int(11) DEFAULT '0' COMMENT '总帖数',
  `social_type` int(11) DEFAULT '1' COMMENT '1表示论坛，2表示博客，3表示问答',
  `region_type` int(11) DEFAULT NULL COMMENT '省101 市102 区103 校104 班105',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_forum 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_forum` (
  `id` int(11) NOT NULL COMMENT '主键',
  `bbs_id` int(11) DEFAULT NULL COMMENT '论坛id',
  `partition_id` int(11) DEFAULT NULL COMMENT '分区id',
  `name` varchar(100) DEFAULT NULL COMMENT '版块名称',
  `icon_url` varchar(200) DEFAULT NULL COMMENT '图标地址',
  `description` varchar(200) DEFAULT NULL COMMENT '版块简介',
  `sequence` int(11) DEFAULT '0' COMMENT '排序',
  `b_delete` int(11) DEFAULT '0' COMMENT '删除标志，默认0,1删除',
  `pid` int(11) DEFAULT '-1' COMMENT 'pid',
  `post_today` int(11) DEFAULT '0' COMMENT '今日帖数',
  `post_yestoday` int(11) DEFAULT '0' COMMENT '昨日帖数',
  `total_topic` int(11) DEFAULT '0' COMMENT '总主题数',
  `total_post` int(11) DEFAULT '0' COMMENT '总帖数',
  `last_post_id` int(11) DEFAULT '-1' COMMENT '最后发表帖子id',
  `last_post_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_forum_user 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_forum_user` (
  `forum_id` int(11) NOT NULL COMMENT '版块id',
  `person_id` int(11) NOT NULL COMMENT '用户id',
  `identity_id` int(11) NOT NULL COMMENT '身份id',
  `person_name` varchar(100) DEFAULT NULL COMMENT '姓名',
  `flag` int(2) DEFAULT '0' COMMENT '默认0普通用户，1表示版主，2表示申请加入待审核，审核通过之后为0',
  PRIMARY KEY (`forum_id`,`person_id`,`identity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_partition 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_partition` (
  `id` int(11) NOT NULL COMMENT '主键',
  `bbs_id` int(11) DEFAULT NULL COMMENT '论坛id',
  `name` varchar(100) DEFAULT NULL COMMENT '分区名称',
  `sequence` int(11) DEFAULT '0' COMMENT '排序',
  `b_delete` int(11) DEFAULT '0' COMMENT '删除标志，默认0,1删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_post 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_post` (
  `id` int(11) NOT NULL COMMENT '主键',
  `bbs_id` int(11) NOT NULL COMMENT '论坛id',
  `forum_id` int(11) NOT NULL COMMENT '版块id',
  `topic_id` int(11) NOT NULL COMMENT '主题帖id',
  `title` varchar(100) DEFAULT NULL COMMENT '帖子标题',
  `content` longtext COMMENT '帖子内容，引用回复时截取内容存在一起',
  `person_id` int(11) DEFAULT NULL COMMENT '发帖人id',
  `identity_id` int(11) DEFAULT NULL COMMENT '发帖人身份id',
  `person_name` varchar(32) DEFAULT NULL COMMENT '真实姓名',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `floor` int(11) DEFAULT NULL COMMENT '楼层,主帖算1楼',
  `support_count` int(11) DEFAULT '0' COMMENT '支持数',
  `oppose_count` int(11) DEFAULT '0' COMMENT '反对数',
  `parent_id` int(11) NOT NULL COMMENT '回复帖子id 回复哪个帖子',
  `ancestor_id` int(11) NOT NULL COMMENT '祖先帖子id',
  `b_delete` int(2) DEFAULT '0' COMMENT '0未删除，1已删除',
  `ts` bigint(20) DEFAULT '0' COMMENT '时间戳',
  `update_ts` bigint(20) DEFAULT '0' COMMENT '时间戳',
  `message_type` int(2) DEFAULT '1' COMMENT '1.BBS 2.留言 3.博文',
  PRIMARY KEY (`id`),
  KEY `update_ts` (`update_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='回帖表';

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_topic 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_topic` (
  `id` int(11) NOT NULL COMMENT '主键',
  `bbs_id` int(11) NOT NULL COMMENT 'bbsid',
  `forum_id` int(11) NOT NULL COMMENT '版块id',
  `title` varchar(100) NOT NULL COMMENT '标题',
  `message_type` int(2) DEFAULT '1' COMMENT '1.BBS 2.留言 3.博文',
  `first_post_id` int(11) NOT NULL COMMENT '主题帖id',
  `ts` bigint(20) NOT NULL COMMENT '时间戳',
  `update_ts` bigint(20) NOT NULL COMMENT '时间戳',
  `person_id` int(11) NOT NULL COMMENT '发帖人id',
  `identity_id` int(11) DEFAULT NULL COMMENT '发帖人身份id',
  `person_name` varchar(32) DEFAULT NULL COMMENT '真实姓名.',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_post_id` int(11) DEFAULT NULL COMMENT '最后帖子id',
  `replyer_person_id` int(11) DEFAULT NULL COMMENT '最后回帖人id',
  `replyer_identity_id` int(11) DEFAULT NULL COMMENT '最后回帖身份id',
  `replyer_time` timestamp NULL DEFAULT NULL COMMENT '最后回帖时间',
  `view_count` int(10) DEFAULT '0' COMMENT '浏览次数',
  `content` longtext COMMENT '主题内容',
  `reply_count` int(10) DEFAULT '0' COMMENT '回复次数',
  `b_reply` int(2) unsigned DEFAULT NULL COMMENT '是否允许回复0允许，1不允许',
  `category_id` int(11) DEFAULT NULL COMMENT '主题分类id',
  `b_best` int(2) DEFAULT NULL COMMENT '是否精华',
  `b_top` bigint(20) DEFAULT NULL COMMENT '是否置顶',
  `support_count` int(11) DEFAULT '0' COMMENT '支持数',
  `oppose_count` int(11) DEFAULT '0' COMMENT '反对数',
  `b_delete` int(2) DEFAULT '0' COMMENT '''0:未删 1：已删'',',
  `type_id` varchar(32) DEFAULT NULL COMMENT '类型id.',
  PRIMARY KEY (`id`),
  KEY `update_ts` (`update_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='bbs主题帖表';

-- 数据导出被取消选择。


-- 导出  表 dsideal_db.t_social_bbs_topic_category 结构
CREATE TABLE IF NOT EXISTS `t_social_bbs_topic_category` (
  `id` int(11) NOT NULL,
  `bbs_id` int(11) NOT NULL COMMENT 'bbs_id论坛id',
  `forum_id` int(11) NOT NULL COMMENT '版块id',
  `name` varchar(100) DEFAULT NULL COMMENT '分类名称',
  `sequence` int(11) DEFAULT NULL COMMENT '排序',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='主题分类表';

-- 数据导出被取消选择。
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
