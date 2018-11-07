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

-- 傾印  程序 db_lexus_cs.sp_bind_client 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_bind_client`(
	IN `p_manager_id` VARCHAR(50),
	IN `p_customer_id` VARCHAR(50),
	IN `p_customer_name` VARCHAR(20),
	IN `p_vehicle_type` VARCHAR(20),
	IN `p_vehicle_number` VARCHAR(20),
	IN `p_avator` VARCHAR(300),
	IN `p_telphone` VARCHAR(20),
	IN `p_personal_data` VARCHAR(2000)






)
BEGIN
	/* 20181022 By Ben */
	/* call sp_bind_client("SE0001","C0003","王二明",'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '{"討厭的維修時間":"平日上班"}'); */
	DECLARE p_conversation_title varchar(60);
	DECLARE p_conversation_avator varchar(300);
	
	IF NOT EXISTS (
		SELECT customer_id FROM tb_customer WHERE ht_id = p_customer_id
	)THEN
		INSERT INTO tb_customer
		(`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) 
		VALUES (UUID(), p_customer_id, p_customer_name, p_vehicle_type, p_vehicle_number, p_avator, p_telphone, p_personal_data, NOW(), NULL);
	ELSE
		UPDATE tb_customer SET telphone = p_telphone WHERE ht_id = p_customer_id;	
	END IF;

	IF NOT EXISTS (
		SELECT responsibility_id FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id
	)THEN
		SET p_conversation_title = (
				SELECT CONCAT(vehicle_type,"/",vehicle_number,"/",name) 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);
		SET p_conversation_avator = (
				SELECT avator 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);
		SET p_conversation_title = IFNULL(p_conversation_title, CONCAT("未知的使用者: ",p_customer_id));
		SET p_conversation_avator = IFNULL(p_conversation_avator, "https://customer-service-xiang.herokuapp.com/images/avatar.png");
		INSERT INTO tb_responsibility 
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `manager_unread`, `customer_unread`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  NOW(), '', 0 , 0 );
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_conversation_info 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_conversation_info`(
	IN `p_manager_id` VARCHAR(50),
	IN `p_customer_id` VARCHAR(50)


)
BEGIN
	/* 20181022 By Ben */
	/* call sp_select_conversation_info("SE0001","C0003"); */
	DECLARE p_manager_json_data varchar(3000);
	DECLARE p_customer_json_data varchar(3000);
	
	SET p_manager_json_data = (SELECT 
		json_merge(
			json_object(
				"end_point","service",
				"id",ht_id,
				"name",manager_name,
				"type",manager_type,
				"avator",avator,
				"PHONE",telphone
			),personal_data
		)
	FROM tb_manager where ht_id = p_manager_id LIMIT 0,1);
	
	SET p_customer_json_data = (SELECT 
		json_merge(
			json_object(
				"end_point","client",
				"id",ht_id,
				"name",name,
				"vehicle_type",vehicle_type,
				"vehicle_number",vehicle_number,
				"avator",avator,
				"PHONE",telphone,
				"personal_data_time",personal_data_time
			),personal_data
		)
	FROM tb_customer where ht_id = p_customer_id LIMIT 0,1);
	
	SET p_manager_json_data = IFNULL(p_manager_json_data,"{}");
	SET p_customer_json_data = IFNULL(p_customer_json_data,"{}");
	
	SELECT p_manager_json_data manager_data, p_customer_json_data customer_data ;
	#SELECT json_array(p_manager_json_data,p_customer_json_data) conversation_info ;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_manager_list 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_manager_list`(
	IN `p_manager_id` VARCHAR(50)


)
BEGIN
	/* 20181022 By Ben */
	/* call sp_select_manager_list("SE0001"); */
	
	SELECT customer_id, conversation_title, avator, last_talk_time, last_message, manager_unread, note
	from tb_responsibility WHERE manager_id = p_manager_id ORDER BY last_talk_time DESC;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_talk_history 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_talk_history`(
	IN `p_endpoint` VARCHAR(50),
	IN `p_manager_id` VARCHAR(50),
	IN `p_customer_id` VARCHAR(50),
	IN `p_skip` int,
	IN `p_limit` int


)
BEGIN
	/* 20181024 By Ben */
	/* call sp_select_talk_history("client","SE0001","C0003",null,null); */
	DECLARE p_skip_exec int default 0;
	DECLARE p_limit_exec int default 1;
	
	IF p_skip IS NOT NULL THEN	
		SET p_skip_exec = p_skip;
	END IF;
	IF p_limit IS NOT NULL THEN	
		SET p_limit_exec = p_limit;
	END IF;
	
	IF p_endpoint = "service" AND p_skip IS NULL AND p_limit IS NULL THEN
		SET p_limit_exec = (SELECT manager_unread FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id LIMIT 0,1)+1;
		SET p_limit_exec = IF(p_limit_exec>1,p_limit_exec,1);
	END IF;
	
	SELECT * 
	#message_type, content, avator, last_talk_time, last_message, unread, note
	FROM tb_message 
	LEFT JOIN 
	((SELECT ht_id , avator FROM tb_customer) UNION (SELECT ht_id , avator FROM tb_manager)) avator_dict
	ON tb_message.from = avator_dict.ht_id
	WHERE (`to` = p_manager_id AND `from` = p_customer_id ) 
		OR (`to` = p_customer_id AND `from` = p_manager_id )
	ORDER BY time DESC
	LIMIT p_limit_exec OFFSET p_skip_exec;
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_talk_tricks 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_talk_tricks`(
	IN p_manager_id VARCHAR(50) , 
	IN p_ans_ID VARCHAR(20)
)
BEGIN
	/* 20181022 By Ben */
	/* call sp_select_talk_tricks("SE0001","D0002"); */
	IF EXISTS (
		SELECT talk_tricks FROM tb_talk_tricks WHERE manager_id = p_manager_id AND dialog_id = p_ans_ID
	)THEN
		SELECT talk_tricks FROM tb_talk_tricks WHERE manager_id = p_manager_id AND dialog_id = p_ans_ID LIMIT 0,1;
	ELSE 
		SELECT talk_tricks FROM tb_talk_tricks_default WHERE dialog_id = p_ans_ID LIMIT 0,1;
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_send_message 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_send_message`(
	IN `p_message_type` VARCHAR(20) ,
	IN `p_content` VARCHAR(2000) ,
	IN `p_intent_str` VARCHAR(2000) ,
	IN `p_recognition_result` VARCHAR(2000) ,
	IN `p_time` VARCHAR(20) ,
	IN `p_direction` VARCHAR(20) ,
	IN `p_from_id` VARCHAR(50) ,
	IN `p_to_id` VARCHAR(50) 


,
	IN `p_time_record` VARCHAR(500)






)
BEGIN
	/* 20181022 By Ben */
	/* call sp_send_message("text","哈囉","[]","","1540190376871","client","C0003","SE0001","{\"r_time\":\"123\"}"); */
	/* call sp_send_message("text","哈囉","[]","","1540190376871","service","SE0001","C0003","{\"r_time\":\"123\"}"); */
	DECLARE p_customer_id varchar(40);
	DECLARE p_manager_id varchar(40);
	DECLARE p_last_message varchar(40);
	DECLARE p_conversation_title varchar(60);
	DECLARE p_conversation_avator varchar(100);
	DECLARE p_set_unread int;
	DECLARE p_datetime varchar(30);
	SET p_datetime = FROM_UNIXTIME(p_time/1000);
	#SET p_datetime = CONVERT_TZ(FROM_UNIXTIME(p_time/1000), '+00:00', '+08:00');
	
	IF p_direction = 'service' THEN
		SET p_customer_id = p_to_id;
		SET p_manager_id = p_from_id;
		SET p_set_unread = 0;
	END IF;
	IF  p_direction = 'client' THEN
		SET p_customer_id = p_from_id;
		SET p_manager_id = p_to_id;
		SET p_set_unread = 1;
	END IF;
	
	
	INSERT INTO tb_message
	(`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`, `time_record`) 
	VALUES
	(UUID(), p_message_type, p_content, p_datetime, p_intent_str, p_recognition_result, p_direction, p_from_id, p_to_id, p_time_record);
		
	IF EXISTS (
		SELECT responsibility_id FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id
	)THEN
		UPDATE tb_responsibility SET last_talk_time = p_datetime, last_message =  p_content, 
			manager_unread = (manager_unread+1)*p_set_unread, customer_unread = (customer_unread+1)*IF(p_set_unread=1,0,1)
		WHERE manager_id = p_manager_id AND customer_id = p_customer_id;
	ELSE 
		SET p_conversation_title = (
				SELECT CONCAT(vehicle_type,"/",vehicle_number,"/",name) 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);
		SET p_conversation_avator = (
				SELECT avator 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);
		SET p_conversation_title = IFNULL(p_conversation_title, CONCAT("未知的使用者: "+p_customer_id));
		SET p_conversation_avator = IFNULL(p_conversation_avator, "https://customer-service-xiang.herokuapp.com/images/avatar.png");
		INSERT INTO tb_responsibility 
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `manager_unread`,`customer_unread`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  p_datetime, p_content, 0 ,0);
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_update_manager 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_manager`(
	IN `p_manager_id` VARCHAR(50),
	IN `p_manager_type` VARCHAR(50),
	IN `p_manager_name` VARCHAR(20),
	IN `p_avator` VARCHAR(300),
	IN `p_telphone` VARCHAR(20),
	IN `p_personal_data` VARCHAR(2000)


)
BEGIN
	/* 20181022 By Ben */
	/* call sp_update_manager("SE0001","CostomerService","帥哥志豪",'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863010', '{"討厭的維修時間":"平日上班"}'); */
	IF NOT EXISTS (
		SELECT manager_id FROM tb_manager WHERE ht_id = p_manager_id 
	)THEN
		INSERT INTO tb_manager (`manager_id`, `ht_id`, `manager_type`, `manager_name`, `avator`, `telphone`, `personal_data`, `personal_data_time`) VALUES (UUID(), p_manager_id, p_manager_type, p_manager_name, p_avator, p_telphone, p_personal_data, NOW());
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_update_talk_tricks 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_talk_tricks`(
	IN p_manager_id VARCHAR(50) , 
	IN p_type VARCHAR(50) , 
	IN p_dialog_id VARCHAR(20),
	IN p_talk_tricks VARCHAR(2000)
)
BEGIN
	/* 20181022 By Ben */
	/* call sp_update_talk_tricks("SE0001","dialog","D0002",'["息怒","妳個混帳","我也是笑笑"]'); */
	IF EXISTS (
		SELECT talk_tricks FROM tb_talk_tricks WHERE manager_id = p_manager_id AND dialog_id = p_dialog_id
	)THEN
		UPDATE tb_talk_tricks SET talk_tricks = p_talk_tricks WHERE manager_id = p_manager_id AND dialog_id = p_dialog_id;
	ELSE 
		INSERT INTO tb_talk_tricks ( `type`, `manager_id`, `dialog_id`, `talk_tricks`) VALUES (p_type,p_manager_id,p_dialog_id,p_talk_tricks);
	END IF;
	
END//
DELIMITER ;

-- 傾印  表格 db_lexus_cs.tb_customer 結構
CREATE TABLE IF NOT EXISTS `tb_customer` (
  `customer_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `vehicle_type` varchar(20) DEFAULT NULL,
  `vehicle_number` varchar(20) DEFAULT NULL,
  `avator` varchar(300) DEFAULT NULL,
  `telphone` varchar(20) DEFAULT NULL,
  `personal_data` varchar(2000) DEFAULT NULL,
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_customer 的資料：~4 rows (大約)
/*!40000 ALTER TABLE `tb_customer` DISABLE KEYS */;
INSERT INTO `tb_customer` (`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) VALUES
	('54c6e618-e1ce-11e8-ac49-00090ffe0001', 'U502785c6d9c1d63aad1535d71c51eae3', '鄭鈺婷', 'IS300h', 'NUM-056', 'https://ai-catcher.com/wp-content/uploads/icon_74.png', '', '{}', '2018-11-06 22:14:53', NULL),
	('5f45d80e-e1ce-11e8-ac49-00090ffe0001', 'C0001', '測試使用者1', 'IS300h', 'RBD-0021', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQIGa49DabvTpQldi1JH7KHt2TeGFmn_3g4U2jAegFdvRLFunkYQg', '0919863010', '{}', '2018-11-06 22:15:11', NULL),
	('5f70f4f5-e1ce-11e8-ac49-00090ffe0001', 'C0002', '測試使用者2', 'IS300h', 'RBD-0022', 'https://im1.book.com.tw/image/getImage?i=https://www.books.com.tw/img/001/079/99/0010799970.jpg&v=5ba225b9&w=348&h=348', '0919863010', '{}', '2018-11-06 22:15:11', NULL),
	('5f91e592-e1ce-11e8-ac49-00090ffe0001', 'C0003', '測試使用者3', 'IS300h', 'RBD-0023', 'http://blog.accupass.com/wp-content/uploads/2017/03/1_120122230539_1.jpg', '0919863010', '{}', '2018-11-06 22:15:11', NULL),
	('d3d429b9-e1d1-11e8-ac49-00090ffe0001', '38ed3cdc-7136-4b28-8b82-b0ecb9b1cfc3', '鄭伊然', 'IS300h', 'NUM-031', 'https://ai-catcher.com/wp-content/uploads/icon_74.png', '', '{}', '2018-11-06 22:39:55', NULL);
/*!40000 ALTER TABLE `tb_customer` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_manager 結構
CREATE TABLE IF NOT EXISTS `tb_manager` (
  `manager_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `manager_type` varchar(50) DEFAULT NULL,
  `manager_name` varchar(50) DEFAULT NULL,
  `avator` varchar(300) DEFAULT NULL,
  `telphone` varchar(50) DEFAULT NULL,
  `personal_data` varchar(50) DEFAULT NULL COMMENT '預想是jsonstr',
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_manager 的資料：~1 rows (大約)
/*!40000 ALTER TABLE `tb_manager` DISABLE KEYS */;
INSERT INTO `tb_manager` (`manager_id`, `ht_id`, `manager_type`, `manager_name`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) VALUES
	('5f3999ee-e1ce-11e8-ac49-00090ffe0001', 'AA00001', 'D', '陳柏廷', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', 'NULL', '{}', '2018-11-06 22:15:11', '');
/*!40000 ALTER TABLE `tb_manager` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_message 結構
CREATE TABLE IF NOT EXISTS `tb_message` (
  `message_id` char(40) NOT NULL,
  `message_type` varchar(20) DEFAULT NULL,
  `content` varchar(2000) DEFAULT NULL,
  `time` datetime(3) DEFAULT NULL,
  `assistant_ans` varchar(2000) DEFAULT NULL,
  `visualrecog_ans` varchar(2000) DEFAULT NULL,
  `direction_type` varchar(20) DEFAULT NULL,
  `from` varchar(50) DEFAULT NULL,
  `to` varchar(50) DEFAULT NULL,
  `time_record` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_message 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_message` DISABLE KEYS */;
INSERT INTO `tb_message` (`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`, `time_record`) VALUES
	('03254a97-e1d3-11e8-ac49-00090ffe0001', 'text', '123', '2018-11-06 22:48:20.349', '[]', '', 'client', '38ed3cdc-7136-4b28-8b82-b0ecb9b1cfc3', 'AA00001', '{"socket_receive":1541515700350,"assistant_call":1541515700351,"assistant_return":1541515704190,"mysql_call":1541515704190,"mysql_return":1541515704196,"socket_broadcast":1541515704197,"before_db_log":1541515704198}'),
	('3e69edfa-e1d3-11e8-ac49-00090ffe0001', 'text', '123123123', '2018-11-06 22:50:02.470', '[]', '', 'client', '38ed3cdc-7136-4b28-8b82-b0ecb9b1cfc3', 'AA00001', '{"socket_receive":1541515802471,"assistant_call":1541515802471,"assistant_return":1541515803632,"mysql_call":1541515803632,"mysql_return":1541515803633,"socket_broadcast":1541515803633,"before_db_log":1541515803633}'),
	('599a2080-e1d3-11e8-ac49-00090ffe0001', 'text', '123123123', '2018-11-06 22:50:48.111', '[]', '', 'client', 'U502785c6d9c1d63aad1535d71c51eae3', 'AA00001', '{"socket_receive":1541515848112,"assistant_call":1541515848112,"assistant_return":1541515849191,"mysql_call":1541515849192,"mysql_return":1541515849248,"socket_broadcast":1541515849248,"before_db_log":1541515849248}'),
	('62deaa58-e1d3-11e8-ac49-00090ffe0001', 'text', '妳好妳好', '2018-11-06 22:51:04.795', '', '', 'service', 'AA00001', 'U502785c6d9c1d63aad1535d71c51eae3', '{"socket_receive":1541515864796,"socket_broadcast":1541515864796,"before_db_log":1541515864797}'),
	('7ff85531-e1d3-11e8-ac49-00090ffe0001', 'text', '哈囉', '2018-11-06 22:51:53.618', '', '', 'service', 'AA00001', '38ed3cdc-7136-4b28-8b82-b0ecb9b1cfc3', '{"socket_receive":1541515913618,"socket_broadcast":1541515913618,"before_db_log":1541515913619}');
/*!40000 ALTER TABLE `tb_message` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_responsibility 結構
CREATE TABLE IF NOT EXISTS `tb_responsibility` (
  `responsibility_id` char(40) NOT NULL,
  `manager_id` char(40) DEFAULT NULL,
  `customer_id` char(40) DEFAULT NULL,
  `conversation_title` varchar(60) DEFAULT NULL COMMENT '避免為了名字而每次join',
  `avator` varchar(300) DEFAULT NULL,
  `last_talk_time` datetime DEFAULT NULL,
  `last_message` varchar(200) DEFAULT NULL,
  `manager_unread` int(11) DEFAULT NULL,
  `customer_unread` int(11) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`responsibility_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_responsibility 的資料：~4 rows (大約)
/*!40000 ALTER TABLE `tb_responsibility` DISABLE KEYS */;
INSERT INTO `tb_responsibility` (`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `manager_unread`, `customer_unread`, `note`, `memo`) VALUES
	('54d9a0b0-e1ce-11e8-ac49-00090ffe0001', 'AA00001', 'U502785c6d9c1d63aad1535d71c51eae3', 'IS300h/NUM-056/鄭鈺婷', 'https://ai-catcher.com/wp-content/uploads/icon_74.png', '2018-11-06 22:51:05', '妳好妳好', 0, 1, NULL, ''),
	('5f5d3327-e1ce-11e8-ac49-00090ffe0001', 'AA00001', 'C0001', 'IS300h/RBD-0021/測試使用者1', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQIGa49DabvTpQldi1JH7KHt2TeGFmn_3g4U2jAegFdvRLFunkYQg', '2018-11-06 22:15:11', '', 0, 0, NULL, ''),
	('5f86622a-e1ce-11e8-ac49-00090ffe0001', 'AA00001', 'C0002', 'IS300h/RBD-0022/測試使用者2', 'https://im1.book.com.tw/image/getImage?i=https://www.books.com.tw/img/001/079/99/0010799970.jpg&v=5ba225b9&w=348&h=348', '2018-11-06 22:15:11', '', 0, 0, NULL, ''),
	('5f9c0913-e1ce-11e8-ac49-00090ffe0001', 'AA00001', 'C0003', 'IS300h/RBD-0023/測試使用者3', 'http://blog.accupass.com/wp-content/uploads/2017/03/1_120122230539_1.jpg', '2018-11-06 22:15:11', '', 0, 0, NULL, ''),
	('d3e8bc96-e1d1-11e8-ac49-00090ffe0001', 'AA00001', '38ed3cdc-7136-4b28-8b82-b0ecb9b1cfc3', 'IS300h/NUM-031/鄭伊然', 'https://ai-catcher.com/wp-content/uploads/icon_74.png', '2018-11-06 22:51:54', '哈囉', 0, 1, NULL, '');
/*!40000 ALTER TABLE `tb_responsibility` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_talk_tricks 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(10) DEFAULT NULL,
  `manager_id` varchar(50) DEFAULT NULL,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL COMMENT '預期是jsonarray',
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks 的資料：~9 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks` DISABLE KEYS */;
INSERT INTO `tb_talk_tricks` (`id`, `type`, `manager_id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
	(1, 'dialog', 'SE0001', 'D0003', '["吃什麼?","coffee tea or me","與我無關阿","不要啦"]', '吃飯'),
	(2, 'dialog', 'SE0001', 'D0004', '["不要同情我!!","妳個混帳","我也是笑笑"]', '同情'),
	(3, 'dialog', 'SE0001', 'D0005', '["我們有提供OO","我們有提供那個","我們有提供這個"]', '尋求資訊'),
	(4, 'dialog', 'SE0001', 'D0001', '["有什麼需要我幫忙的嗎","hi","哈囉"]', '歡迎'),
	(5, 'dialog', 'SE0001', 'D0002', '["去上吧 可憐的孩子","拍拍","不想上班就別上了"]', '不想上班'),
	(6, 'dialog', 'SE0001', 'D0006', '["有什麼需要我幫忙的嗎","hi","哈囉"]', '打招呼'),
	(7, 'dialog', 'SE0001', 'D0007', '["息怒","妳個混帳","我也是笑笑"]', '生氣'),
	(8, 'dialog', 'SE0001', 'D0008', '["抱歉 我聽不懂?","有別的說法嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎","嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎","嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎嗎","嗎嗎嗎嗎嗎嗎嗎嗎"]', 'anything_else');
/*!40000 ALTER TABLE `tb_talk_tricks` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_talk_tricks_default 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks_default` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL,
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks_default 的資料：~9 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks_default` DISABLE KEYS */;
INSERT INTO `tb_talk_tricks_default` (`id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
	(2, 'D0002', '["default不想上班","default不想上班","default不想上班"]', '不想上班'),
	(3, 'D0003', '["default吃飯","default吃飯","default吃飯"]', '吃飯'),
	(4, 'D0004', '["default同情","default同情","default同情"]', '同情'),
	(5, 'D0005', '["default尋求資訊","default尋求資訊","default尋求資訊"]', '尋求資訊'),
	(6, 'D0006', '["default打招呼","default打招呼","default打招呼"]', '打招呼'),
	(7, 'D0007', '["default生氣","default生氣","default生氣"]', '生氣'),
	(8, 'D0008', '["default anything_else","default anything_else","default anything_else"]', 'anything_else'),
	(12, 'D0001', '["default歡迎","default歡迎","default歡迎"]', '歡迎');
/*!40000 ALTER TABLE `tb_talk_tricks_default` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_uploaded_picture 結構
CREATE TABLE IF NOT EXISTS `tb_uploaded_picture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` char(40) DEFAULT NULL,
  `picture_name` varchar(100) DEFAULT NULL,
  `picture_url` varchar(200) DEFAULT NULL,
  `upload_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_uploaded_picture 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `tb_uploaded_picture` DISABLE KEYS */;
INSERT INTO `tb_uploaded_picture` (`id`, `customer_id`, `picture_name`, `picture_url`, `upload_time`) VALUES
	(1, '3a432ccc-245c-4364-9366-e8b52536fe35', 'tire_press.png', 'http://localhost:3000/uploaded/tire_pressure.png', '2018-10-18 12:46:09');
/*!40000 ALTER TABLE `tb_uploaded_picture` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
