-- --------------------------------------------------------
-- 主機:                           127.0.0.1
-- 伺服器版本:                        8.0.13 - MySQL Community Server - GPL
-- 伺服器操作系統:                      Win64
-- HeidiSQL 版本:                  9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- 傾印 db_lexus_cs 的資料庫結構
CREATE DATABASE IF NOT EXISTS `db_lexus_cs` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE `db_lexus_cs`;

-- 傾印  程序 db_lexus_cs.sp_api_log 結構
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `sp_api_log`(
	IN `p_url` VARCHAR(200),
	IN `p_start` VARCHAR(50),
	IN `p_end` VARCHAR(50),
	IN `p_success` VARCHAR(20),
	IN `p_data` VARCHAR(2000)




)
BEGIN

	INSERT INTO tb_call_api_log (`url`, `start`, `end`, `success`, `data`) 
	VALUES (p_url, p_start, p_end, p_success, p_data);

END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_bind_client 結構
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `sp_bind_client`(
	IN `p_manager_id` VARCHAR(50),
	IN `p_customer_id` VARCHAR(50),
	IN `p_customer_name` VARCHAR(20),
	IN `p_vehicle_type` VARCHAR(20),
	IN `p_vehicle_number` VARCHAR(20),
	IN `p_avator` VARCHAR(500),
	IN `p_telphone` VARCHAR(20),
	IN `p_fend_date` VARCHAR(20),
	IN `p_uend_date` VARCHAR(20),
	IN `p_birth_date` VARCHAR(20),
	IN `p_f_flag` VARCHAR(10),
	IN `p_u_flag` VARCHAR(10),
	IN `p_birth_flag` VARCHAR(10),
	IN `p_personal_data` VARCHAR(2000),
	IN `p_notify_data` VARCHAR(200)


)
BEGIN
	/* 20181022 By Ben */
	/* call sp_bind_client("SE0001","C0003","王二明",'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '{"討厭的維修時間":"平日上班"}'); */
	DECLARE p_conversation_title varchar(60);
	DECLARE p_conversation_avator varchar(500);
	
	IF NOT EXISTS (
		SELECT customer_id FROM tb_customer WHERE ht_id = p_customer_id
	)THEN
		INSERT INTO tb_customer
		(`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `fend_date`, `uend_date`, `birth_date`, `fend_need_notify`, `uend_need_notify`, `birth_need_notify`, `personal_data`, `personal_data_time`, `memo`) 
		VALUES (UUID(), p_customer_id, p_customer_name, p_vehicle_type, p_vehicle_number, p_avator, p_telphone, p_fend_date, p_uend_date, p_birth_date, p_f_flag, p_u_flag, p_birth_flag, IFNULL(p_personal_data,"{}"), NOW(), NULL);
	ELSE
		UPDATE tb_customer SET 
			telphone = p_telphone,
			fend_date = IFNULL(p_fend_date,fend_date), 
			uend_date = IFNULL(p_uend_date,uend_date),
			birth_date = IFNULL(p_birth_date,birth_date),
			fend_need_notify = IFNULL(p_f_flag,fend_need_notify), 
			uend_need_notify = IFNULL(p_u_flag,uend_need_notify), 
			birth_need_notify = IFNULL(p_birth_flag,birth_need_notify)
		WHERE ht_id = p_customer_id;
	END IF;

	IF NOT EXISTS (
		SELECT responsibility_id FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id
	)THEN
		SET p_conversation_title = (
				SELECT CONCAT(vehicle_type,"/",vehicle_number) 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);

		SET p_conversation_avator = (
				SELECT avator 
				FROM tb_customer 
				WHERE ht_id = p_customer_id limit 0,1
			);
		#SET p_conversation_title = IFNULL(p_conversation_title, CONCAT("未知的使用者: ",p_customer_id));
		#SET p_conversation_avator = IFNULL(p_conversation_avator, "https://customer-service-xiang.herokuapp.com/images/avatar.png");
		INSERT INTO tb_responsibility 
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `customer_nickname`, `avator`, `last_talk_time`, `last_message`, `manager_unread`, `customer_unread`,`notify_data`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_customer_name, p_conversation_avator,  NOW(), '', 0, 0, IFNULL(p_notify_data,"{}"));
	ELSE 
		UPDATE tb_responsibility SET 
			conversation_title = CONCAT(p_vehicle_type,"/", p_vehicle_number), 
			#customer_nickname = p_customer_name
			avator = p_avator,
			notify_data = IFNULL(p_notify_data,notify_data)
		WHERE manager_id = p_manager_id AND customer_id = p_customer_id;
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_conversation_info 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_conversation_info`(IN `p_manager_id` VARCHAR(50), IN `p_customer_id` VARCHAR(50))
    NO SQL
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
	
	/*SELECT customer_id, conversation_title, customer_nickname, avator, last_talk_time, last_message, manager_unread, notify_data
	from tb_responsibility WHERE manager_id = p_manager_id ORDER BY last_talk_time DESC;
	
	/* 20181112 By Cat */
	
	SELECT tb_responsibility.customer_id, tb_responsibility.conversation_title, tb_responsibility.customer_nickname, tb_responsibility.avator, tb_responsibility.last_talk_time, tb_responsibility.last_message, tb_responsibility.manager_unread, tb_responsibility.notify_data
		,tb_customer.fend_need_notify, tb_customer.uend_need_notify, tb_customer.birth_need_notify, tb_customer.fend_notify, tb_customer.uend_notify, tb_customer.birth_notify
	FROM tb_responsibility RIGHT OUTER JOIN tb_customer ON tb_responsibility.customer_id=tb_customer.ht_id WHERE tb_responsibility.manager_id = p_manager_id;

END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_select_talk_history 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_talk_history`(IN `p_endpoint` VARCHAR(50), IN `p_manager_id` VARCHAR(50), IN `p_customer_id` VARCHAR(50), IN `p_skip` INT, IN `p_limit` INT)
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
	((SELECT ht_id, name name, avator FROM tb_customer) UNION (SELECT ht_id, manager_name name, avator FROM tb_manager)) avator_dict
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
CREATE DEFINER=`root`@`%` PROCEDURE `sp_send_message`(
	IN `p_message_type` VARCHAR(20),
	IN `p_content` VARCHAR(2000),
	IN `p_intent_str` VARCHAR(2000),
	IN `p_recognition_result` VARCHAR(2000),
	IN `p_time` VARCHAR(20),
	IN `p_direction` VARCHAR(20),
	IN `p_from_id` VARCHAR(50),
	IN `p_to_id` VARCHAR(50),
	IN `p_push` VARCHAR(20),
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
	(`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`, `push`, `time_record`) 
	VALUES
	(UUID(), p_message_type, p_content, p_datetime, p_intent_str, p_recognition_result, p_direction, p_from_id, p_to_id, p_push, p_time_record);
		
	IF EXISTS (
		SELECT responsibility_id FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id
	)THEN
		UPDATE tb_responsibility SET last_talk_time = p_datetime, last_message =  p_content, 
			manager_unread = (manager_unread+1)*p_set_unread, customer_unread = (customer_unread+1)*IF(p_set_unread=1,0,1)
		WHERE manager_id = p_manager_id AND customer_id = p_customer_id;
		/*
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
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `manager_unread`,`customer_unread`,`notify_data`,`personal_data`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  p_datetime, p_content, 0, 0, p_notify_data, p_personal_data);
		*/
	END IF;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_update_manager 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_manager`(
	IN `p_manager_id` VARCHAR(50),
	IN `p_compid` VARCHAR(20),
	IN `p_dlrcd` VARCHAR(20),
	IN `p_brnhcd` VARCHAR(20),
	IN `p_sectcd` VARCHAR(20),
	IN `p_manager_type` VARCHAR(50),
	IN `p_manager_name` VARCHAR(20),
	IN `p_avator` VARCHAR(200),
	IN `p_telphone` VARCHAR(20),
	IN `p_personal_data` VARCHAR(2000)





)
    NO SQL
BEGIN
	/* 20181022 By Ben */
	/* call sp_update_manager("SE0001","CostomerService","帥哥志豪",'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863010', '{"討厭的維修時間":"平日上班"}'); */
	IF NOT EXISTS (
		SELECT manager_id FROM tb_manager WHERE ht_id = p_manager_id 
	)THEN
		INSERT INTO tb_manager (`manager_id`, `ht_id`, `login`, `compid`, `dlrcd`, `brnhcd`, `sectcd`, `manager_type`, `manager_name`, `avator`, `telphone`, `personal_data`, `personal_data_time`) 
		VALUES (UUID(), p_manager_id, "Y", p_compid, p_dlrcd, p_brnhcd, p_sectcd, p_manager_type, p_manager_name, p_avator, p_telphone, p_personal_data, NOW());
	END IF;
	
	UPDATE tb_manager SET login='Y' WHERE ht_id = p_manager_id;
	
END//
DELIMITER ;

-- 傾印  程序 db_lexus_cs.sp_update_talk_tricks 結構
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_talk_tricks`(IN `p_manager_id` VARCHAR(50), IN `p_type` VARCHAR(50), IN `p_dialog_id` VARCHAR(20), IN `p_talk_tricks` VARCHAR(2000))
    NO SQL
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

-- 傾印  表格 db_lexus_cs.tb_call_api_log 結構
CREATE TABLE IF NOT EXISTS `tb_call_api_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(200) DEFAULT NULL,
  `start` varchar(50) DEFAULT NULL,
  `end` varchar(50) DEFAULT NULL,
  `success` varchar(20) DEFAULT NULL,
  `data` varchar(2000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_customer 結構
CREATE TABLE IF NOT EXISTS `tb_customer` (
  `customer_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `vehicle_type` varchar(20) DEFAULT NULL,
  `vehicle_number` varchar(20) DEFAULT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `telphone` varchar(20) DEFAULT NULL,
  `fend_date` varchar(20) DEFAULT NULL,
  `uend_date` varchar(20) DEFAULT NULL,
  `birth_date` varchar(20) DEFAULT NULL,
  `fend_need_notify` varchar(10) DEFAULT NULL,
  `uend_need_notify` varchar(10) DEFAULT NULL,
  `birth_need_notify` varchar(10) DEFAULT NULL,
  `fend_notify` varchar(10) DEFAULT 'Y',
  `uend_notify` varchar(10) DEFAULT 'Y',
  `birth_notify` varchar(10) DEFAULT 'Y',
  `personal_data` varchar(2000) DEFAULT NULL,
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_manager 結構
CREATE TABLE IF NOT EXISTS `tb_manager` (
  `manager_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `login` varchar(10) DEFAULT 'N',
  `compid` varchar(20) DEFAULT NULL,
  `dlrcd` varchar(20) DEFAULT NULL,
  `brnhcd` varchar(20) DEFAULT NULL,
  `sectcd` varchar(20) DEFAULT NULL,
  `manager_type` varchar(50) DEFAULT NULL,
  `manager_name` varchar(50) DEFAULT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `telphone` varchar(50) DEFAULT NULL,
  `personal_data` varchar(50) DEFAULT NULL COMMENT '預想是jsonstr',
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
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
  `push` varchar(20) DEFAULT NULL,
  `time_record` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_responsibility 結構
CREATE TABLE IF NOT EXISTS `tb_responsibility` (
  `responsibility_id` char(40) NOT NULL,
  `manager_id` char(40) DEFAULT NULL,
  `customer_id` char(40) DEFAULT NULL,
  `conversation_title` varchar(60) DEFAULT NULL COMMENT '避免為了名字而每次join',
  `customer_nickname` varchar(60) DEFAULT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `last_talk_time` datetime DEFAULT NULL,
  `last_message` varchar(200) DEFAULT NULL,
  `manager_unread` int(11) DEFAULT NULL,
  `customer_unread` int(11) DEFAULT NULL,
  `notify_data` varchar(200) DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`responsibility_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_talk_tricks 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(10) DEFAULT NULL,
  `manager_id` varchar(50) DEFAULT NULL,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL COMMENT '預期是jsonarray',
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_talk_tricks_default 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks_default` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL,
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.tb_uploaded_picture 結構
CREATE TABLE IF NOT EXISTS `tb_uploaded_picture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` char(40) DEFAULT NULL,
  `picture_name` varchar(100) DEFAULT NULL,
  `picture_url` varchar(200) DEFAULT NULL,
  `upload_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.x_tb_intent_response 結構
CREATE TABLE IF NOT EXISTS `x_tb_intent_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intent` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
-- 傾印  表格 db_lexus_cs.x_tb_visualrecog_response 結構
CREATE TABLE IF NOT EXISTS `x_tb_visualrecog_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visualrecog` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8;

-- 取消選取資料匯出。
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
