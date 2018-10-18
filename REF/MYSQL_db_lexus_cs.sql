-- --------------------------------------------------------
-- 主機:                           127.0.0.1
-- 伺服器版本:                        5.7.16-log - MySQL Community Server (GPL)
-- 伺服器操作系統:                      Win64
-- HeidiSQL 版本:                  9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- 傾印 db_lexus_cs 的資料庫結構
CREATE DATABASE IF NOT EXISTS `db_lexus_cs` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `db_lexus_cs`;

-- 傾印  表格 db_lexus_cs.tb_customer 結構
CREATE TABLE IF NOT EXISTS `tb_customer` (
  `customer_id` char(40) NOT NULL,
  `ht_id` varchar(20) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `vehicle_type` varchar(20) DEFAULT NULL,
  `vehicle_number` varchar(20) DEFAULT NULL,
  `avator` varchar(100) DEFAULT NULL,
  `telphone` varchar(20) DEFAULT NULL,
  `personal_data` varchar(2000) DEFAULT NULL,
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_customer 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_customer` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_customer` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_intent_response 結構
CREATE TABLE IF NOT EXISTS `tb_intent_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intent` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_intent_response 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_intent_response` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_intent_response` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_manager 結構
CREATE TABLE IF NOT EXISTS `tb_manager` (
  `manager_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `manager_name` varchar(50) DEFAULT NULL,
  `avator` varchar(50) DEFAULT NULL,
  `telphone` varchar(50) DEFAULT NULL,
  `personal_data` varchar(50) DEFAULT NULL COMMENT '預想是jsonstr',
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_manager 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_manager` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_manager` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_message 結構
CREATE TABLE IF NOT EXISTS `tb_message` (
  `message_id` char(40) NOT NULL,
  `message_type` varchar(20) DEFAULT NULL,
  `content` varchar(2000) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `assistant_ans` varchar(2000) DEFAULT NULL,
  `visualrecog_ans` varchar(2000) DEFAULT NULL,
  `direction_type` varchar(20) DEFAULT NULL,
  `from` char(40) DEFAULT NULL,
  `to` char(40) DEFAULT NULL,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_message 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_message` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_message` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_responsibility 結構
CREATE TABLE IF NOT EXISTS `tb_responsibility` (
  `responsibility_id` char(40) NOT NULL,
  `customer_id` char(40) DEFAULT NULL,
  `manager_id` char(40) DEFAULT NULL,
  `last_talk_time` datetime DEFAULT NULL,
  `last_message` varchar(200) DEFAULT NULL,
  `unread` int(11) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `memo` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`responsibility_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_responsibility 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_responsibility` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_responsibility` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_talk_tricks 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `manager_id` char(40) DEFAULT NULL,
  `talk_trick` varchar(2000) DEFAULT NULL COMMENT '預期是jsonarray',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_talk_tricks` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_uploaded_picture 結構
CREATE TABLE IF NOT EXISTS `tb_uploaded_picture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` char(40) DEFAULT NULL,
  `picture_name` varchar(100) DEFAULT NULL,
  `picture_url` varchar(200) DEFAULT NULL,
  `upload_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_uploaded_picture 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_uploaded_picture` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_uploaded_picture` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_visualrecog_response 結構
CREATE TABLE IF NOT EXISTS `tb_visualrecog_response` (
  `id` int(11) NOT NULL,
  `visualrecog` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_visualrecog_response 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_visualrecog_response` DISABLE KEYS */;
/*!40000 ALTER TABLE `tb_visualrecog_response` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
