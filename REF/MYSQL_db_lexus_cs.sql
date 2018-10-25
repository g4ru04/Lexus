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
	IN `p_customer_id` VARCHAR(50)
)
BEGIN
	/* 20181022 By Ben */
	/* call sp_bind_client("SE0001","C0003"); */
	DECLARE p_conversation_title varchar(60);
	DECLARE p_conversation_avator varchar(100);
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
		INSERT INTO tb_responsibility 
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `unread`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  NOW(), '', 0 );
	END IF;
	
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
	
	SELECT customer_id, conversation_title, avator, last_talk_time, last_message, unread, note
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
		SET p_limit_exec = (SELECT unread FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id LIMIT 0,1)+1;
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
		UPDATE tb_responsibility SET last_talk_time = p_datetime, last_message =  p_content, unread = (unread+1)*p_set_unread
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
		INSERT INTO tb_responsibility 
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `unread`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  p_datetime, p_content, 0 );
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
  `avator` varchar(100) DEFAULT NULL,
  `telphone` varchar(20) DEFAULT NULL,
  `personal_data` varchar(2000) DEFAULT NULL,
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_customer 的資料：~5 rows (大約)
/*!40000 ALTER TABLE `tb_customer` DISABLE KEYS */;
INSERT INTO `tb_customer` (`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) VALUES
	('3a432ccc-245c-4364-9366-e8b52536fe35', 'C0003', '陳一為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863012', '{"車險到期日":"2018-11-28"}', '2018-10-18 11:30:32', NULL),
	('4ˋ03a2f73-947e-416b-9d19-c8a7c3e93849', 'C0004', '陳二為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863012', NULL, '2018-10-18 11:30:32', NULL),
	('5c4972ee-8edb-4f11-9197-30734ca1f093', 'C0005', '陳三為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863012', NULL, '2018-10-18 11:30:32', NULL),
	('dd71bed7-610c-421e-af12-4d03264cd5c1', 'C0001', '王一明', 'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '{"討厭的維修時間":"平日上班"}', '2018-10-18 11:30:32', NULL),
	('efe25070-8ec2-4bb5-b831-259b01bbd972', 'C0002', '王二明', 'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '{"討厭的維修時間":"平日上班"}', '2018-10-18 11:30:32', NULL);
/*!40000 ALTER TABLE `tb_customer` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_manager 結構
CREATE TABLE IF NOT EXISTS `tb_manager` (
  `manager_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `manager_type` varchar(50) DEFAULT NULL,
  `manager_name` varchar(50) DEFAULT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `telphone` varchar(50) DEFAULT NULL,
  `personal_data` varchar(50) DEFAULT NULL COMMENT '預想是jsonstr',
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_manager 的資料：~2 rows (大約)
/*!40000 ALTER TABLE `tb_manager` DISABLE KEYS */;
INSERT INTO `tb_manager` (`manager_id`, `ht_id`, `manager_type`, `manager_name`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) VALUES
	('b09408c5-364a-4041-9bd3-8add2493e853', 'SE0001', 'CostomerService', '帥哥志豪', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', ''),
	('e2ddbfa4-a000-40f2-8da5-43add363aac1', 'SA0001', 'Sales', '美女麗雲', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', '');
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

-- 正在傾印表格  db_lexus_cs.tb_message 的資料：~9 rows (大約)
/*!40000 ALTER TABLE `tb_message` DISABLE KEYS */;
INSERT INTO `tb_message` (`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`, `time_record`) VALUES
	('010e85c6-d826-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/93423760-d825-11e8-9d7f-27af43bf684c.png', '2018-10-25 15:14:13.104', '[{"intent":"打招呼","confidence":0.0831786649817886},{"intent":"尋求資訊","confidence":0.07130005449930295},{"intent":"生氣","confidence":0.06846968663569585},{"intent":"謝謝","confidence":0.06815011949978499},{"intent":"罵髒話","confidence":0.06733028272407965},{"intent":"不想上班","confidence":0.0670605069192945},{"intent":"高興","confidence":0.06525069238661702},{"intent":"睡覺","confidence":0.06421116142604219},{"intent":"同情","confidence":0.06344697618641035},{"intent":"吃飯","confidence":0.06124624924404004}]', '紅橙色，飲料，食品，餐具，酒精飲料，混合飲料，雞尾酒', 'client', 'C0001', 'SE0001', '{"socket_receive":1540451653106,"visualrecog_call":1540451653111,"visualrecog_return":1540451656052,"assistant_call":1540451657293,"assistant_return":1540451658880,"socket_broadcast":1540451658881,"before_db_log":1540451659017}'),
	('02fec9b9-d817-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 13:26:59.142', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540445219142,"assistant_call":1540445219149,"assistant_return":1540445219806,"socket_broadcast":1540445219807,"before_db_log":1540445219818}'),
	('0ac4c528-d764-11e8-a595-00090ffe0001', 'text', '1', '2018-10-24 16:06:02.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368361914,"socket_broadcast":1540368361947,"before_db_log":1540368362172}'),
	('0ccf0425-d764-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 16:06:02.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368362437,"socket_broadcast":1540368365394,"before_db_log":1540368365596}'),
	('0ce6ad22-d764-11e8-a595-00090ffe0001', 'text', '3', '2018-10-24 16:06:03.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368362928,"socket_broadcast":1540368365397,"before_db_log":1540368365597}'),
	('0cff22a1-d764-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 16:06:04.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368363667,"socket_broadcast":1540368365399,"before_db_log":1540368365705}'),
	('0d14aa9a-d764-11e8-a595-00090ffe0001', 'text', '5', '2018-10-24 16:06:04.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368364359,"socket_broadcast":1540368365402,"before_db_log":1540368365737}'),
	('0d28f53c-d764-11e8-a595-00090ffe0001', 'text', '6', '2018-10-24 16:06:05.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368364963,"socket_broadcast":1540368365471,"before_db_log":1540368365836}'),
	('0d44d713-d764-11e8-a595-00090ffe0001', 'text', '7', '2018-10-24 16:06:06.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368366238,"socket_broadcast":1540368366310,"before_db_log":1540368366368}'),
	('0dbd82c6-d764-11e8-a595-00090ffe0001', 'text', '8', '2018-10-24 16:06:07.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368367114,"socket_broadcast":1540368367133,"before_db_log":1540368367159}'),
	('0e31083b-d764-11e8-a595-00090ffe0001', 'text', '9', '2018-10-24 16:06:08.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368367790,"socket_broadcast":1540368367873,"before_db_log":1540368367916}'),
	('0ec3354b-d764-11e8-a595-00090ffe0001', 'text', '0', '2018-10-24 16:06:09.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540368368595,"socket_broadcast":1540368368657,"before_db_log":1540368368874}'),
	('1aaa541b-d824-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/add591f0-d823-11e8-9d7f-27af43bf684c.jpg', '2018-10-25 15:00:38.703', '[{"intent":"打招呼","confidence":0.10638635267444557},{"intent":"尋求資訊","confidence":0.09119348988506602},{"intent":"生氣","confidence":0.08757342079881597},{"intent":"謝謝","confidence":0.08716469120413423},{"intent":"罵髒話","confidence":0.0861161116870818},{"intent":"不想上班","confidence":0.08577106570783713},{"intent":"高興","confidence":0.08345629464014906},{"intent":"睡覺","confidence":0.08212672404158354},{"intent":"同情","confidence":0.0811493234012886},{"intent":"吃飯","confidence":0.07833457141311442}]', '灰色，灰色，人員，護士', 'client', 'C0001', 'SE0001', '{"socket_receive":1540450838703,"visualrecog_call":1540450838715,"visualrecog_return":1540450841224,"assistant_call":1540450842313,"assistant_return":1540450842972,"socket_broadcast":1540450842972,"before_db_log":1540450842987}'),
	('1f5ae57e-d809-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 11:47:34.386', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540439254386,"socket_broadcast":1540439254421,"before_db_log":1540439254443}'),
	('38242e1c-d738-11e8-a595-00090ffe0001', 'text', '2131232', '2018-10-24 10:52:19.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349538952,"assistant_call":1540349538969,"assistant_return":1540349540309,"socket_broadcast":1540349540309,"before_db_log":1540349540441}'),
	('387d57fd-d738-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 10:52:19.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349539279,"assistant_call":1540349539295,"assistant_return":1540349540851,"socket_broadcast":1540349540851,"before_db_log":1540349541026}'),
	('38c2a7fe-d738-11e8-a595-00090ffe0001', 'text', '1231', '2018-10-24 10:52:20.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349539613,"assistant_call":1540349539646,"assistant_return":1540349541112,"socket_broadcast":1540349541112,"before_db_log":1540349541480}'),
	('39022f02-d738-11e8-a595-00090ffe0001', 'text', '32', '2018-10-24 10:52:20.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349539744,"assistant_call":1540349539762,"assistant_return":1540349541114,"socket_broadcast":1540349541114,"before_db_log":1540349541896}'),
	('3924698b-d738-11e8-a595-00090ffe0001', 'text', '1', '2018-10-24 10:52:20.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349539875,"assistant_call":1540349539892,"assistant_return":1540349541164,"socket_broadcast":1540349541164,"before_db_log":1540349541910}'),
	('39408fa7-d738-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 10:52:20.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349540046,"assistant_call":1540349540132,"assistant_return":1540349541412,"socket_broadcast":1540349541412,"before_db_log":1540349542063}'),
	('396bdf5c-d738-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 10:52:20.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349540334,"assistant_call":1540349540455,"assistant_return":1540349541798,"socket_broadcast":1540349541798,"before_db_log":1540349542589}'),
	('3987190d-d738-11e8-a595-00090ffe0001', 'text', '214', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349540528,"assistant_call":1540349540606,"assistant_return":1540349541839,"socket_broadcast":1540349541839,"before_db_log":1540349542628}'),
	('39ca0e49-d738-11e8-a595-00090ffe0001', 'text', '12', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349540707,"assistant_call":1540349540849,"assistant_return":1540349542179,"socket_broadcast":1540349542179,"before_db_log":1540349543206}'),
	('39fc06e8-d738-11e8-a595-00090ffe0001', 'text', '3', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349540885,"assistant_call":1540349541055,"assistant_return":1540349542397,"socket_broadcast":1540349542397,"before_db_log":1540349543533}'),
	('3ac0554b-d738-11e8-a595-00090ffe0001', 'text', '31', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541081,"assistant_call":1540349541140,"assistant_return":1540349543887,"socket_broadcast":1540349543887,"before_db_log":1540349544820}'),
	('3b3b6277-d738-11e8-a595-00090ffe0001', 'text', '32', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541270,"assistant_call":1540349541911,"assistant_return":1540349545234,"socket_broadcast":1540349545234,"before_db_log":1540349545627}'),
	('3b61fb5f-d738-11e8-a595-00090ffe0001', 'text', '1', '2018-10-24 10:52:21.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541439,"assistant_call":1540349542281,"assistant_return":1540349545484,"socket_broadcast":1540349545484,"before_db_log":1540349545879}'),
	('3b76bb59-d738-11e8-a595-00090ffe0001', 'text', '23', '2018-10-24 10:52:22.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541607,"assistant_call":1540349542282,"assistant_return":1540349545589,"socket_broadcast":1540349545589,"before_db_log":1540349545918}'),
	('3b98eae1-d738-11e8-a595-00090ffe0001', 'text', '1', '2018-10-24 10:52:22.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541790,"assistant_call":1540349542455,"assistant_return":1540349545796,"socket_broadcast":1540349545796,"before_db_log":1540349546240}'),
	('3bb269c6-d738-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 10:52:22.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542095,"assistant_call":1540349542771,"assistant_return":1540349545898,"socket_broadcast":1540349545898,"before_db_log":1540349546367}'),
	('3bd62039-d738-11e8-a595-00090ffe0001', 'text', '32', '2018-10-24 10:52:22.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349541945,"assistant_call":1540349542770,"assistant_return":1540349546050,"socket_broadcast":1540349546050,"before_db_log":1540349546641}'),
	('3bf248c5-d738-11e8-a595-00090ffe0001', 'text', '213', '2018-10-24 10:52:22.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542386,"assistant_call":1540349543326,"assistant_return":1540349546123,"socket_broadcast":1540349546123,"before_db_log":1540349546654}'),
	('3c0ef64b-d738-11e8-a595-00090ffe0001', 'text', '3', '2018-10-24 10:52:23.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542926,"assistant_call":1540349543924,"assistant_return":1540349546324,"socket_broadcast":1540349546324,"before_db_log":1540349546823}'),
	('3c3147fc-d738-11e8-a595-00090ffe0001', 'text', '1', '2018-10-24 10:52:23.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542543,"assistant_call":1540349543617,"assistant_return":1540349546464,"socket_broadcast":1540349546464,"before_db_log":1540349547034}'),
	('3c4a7615-d738-11e8-a595-00090ffe0001', 'text', '32', '2018-10-24 10:52:23.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542678,"assistant_call":1540349543721,"assistant_return":1540349546739,"socket_broadcast":1540349546739,"before_db_log":1540349547158}'),
	('3c6690ee-d738-11e8-a595-00090ffe0001', 'text', '21', '2018-10-24 10:52:23.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540349542804,"assistant_call":1540349543918,"assistant_return":1540349546853,"socket_broadcast":1540349546853,"before_db_log":1540349547587}'),
	('3d21fd0c-d823-11e8-a595-00090ffe0001', 'text', '2', '2018-10-25 14:54:30.100', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540450470102,"assistant_call":1540450470107,"assistant_return":1540450471303,"socket_broadcast":1540450471303,"before_db_log":1540450471317}'),
	('4148f50f-d766-11e8-a595-00090ffe0001', 'text', 'C003', '2018-10-24 16:21:53.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540369312620,"socket_broadcast":1540369312625,"before_db_log":1540369312630}'),
	('4afb9a02-d823-11e8-a595-00090ffe0001', 'text', '3', '2018-10-25 14:54:53.732', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540450493732,"assistant_call":1540450493736,"assistant_return":1540450494538,"socket_broadcast":1540450494538,"before_db_log":1540450494555}'),
	('4c62ab73-0031-4595-b59a-73285168b760', 'text', '哈囉 請問有人在嗎', '2018-10-18 11:44:54.000', '[{"intent":"尋求資訊","confidence":0.8483095169067383},{"intent":"打招呼","confidence":0.27784162759780884},{"intent":"生氣","confidence":0.26535335183143616}]', NULL, 'client', '3a432ccc-245c-4364-9366-e8b52536fe35', 'e2ddbfa4-a000-40f2-8da5-43add363aac1', NULL),
	('4d1496ef-d758-11e8-a595-00090ffe0001', 'text', '123213', '2018-10-24 14:41:59.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363319231,"socket_broadcast":1540363319435,"before_db_log":1540363319463}'),
	('4edfbf56-d758-11e8-a595-00090ffe0001', 'text', '123213', '2018-10-24 14:42:02.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363322442,"socket_broadcast":1540363322464,"before_db_log":1540363322475}'),
	('4f742ab7-d69b-11e8-a595-00090ffe0001', 'text', 'sdfsdfsf', '2018-10-23 16:09:18.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540282158272,"socket_broadcast":1540282158276,"before_db":1540282158281}'),
	('51ff6e29-d817-11e8-a595-00090ffe0001', 'text', '2', '2018-10-25 13:29:11.728', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540445351728,"assistant_call":1540445351734,"assistant_return":1540445352348,"socket_broadcast":1540445352348,"before_db_log":1540445352362}'),
	('53f73297-d69d-11e8-a595-00090ffe0001', 'text', '123', '2018-10-23 16:23:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283024759,"socket_broadcast":1540283024763,"before_db":1540283024767}'),
	('540e4710-d69d-11e8-a595-00090ffe0001', 'text', '', '2018-10-23 16:23:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283024913,"socket_broadcast":1540283024917,"before_db":1540283024921}'),
	('542ebbc3-d69d-11e8-a595-00090ffe0001', 'text', '213', '2018-10-23 16:23:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025078,"socket_broadcast":1540283025089,"before_db":1540283025093}'),
	('544b075a-d69d-11e8-a595-00090ffe0001', 'text', '1', '2018-10-23 16:23:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025255,"socket_broadcast":1540283025266,"before_db":1540283025271}'),
	('547c1a19-d69d-11e8-a595-00090ffe0001', 'text', '23', '2018-10-23 16:23:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025419,"socket_broadcast":1540283025525,"before_db":1540283025531}'),
	('549c41d2-d69d-11e8-a595-00090ffe0001', 'text', '1', '2018-10-23 16:23:46.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025530,"socket_broadcast":1540283025534,"before_db":1540283025542}'),
	('54be1425-d69d-11e8-a595-00090ffe0001', 'text', '23', '2018-10-23 16:23:46.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025747,"socket_broadcast":1540283025752,"before_db":1540283025757}'),
	('54d86cad-d69d-11e8-a595-00090ffe0001', 'text', '123', '2018-10-23 16:23:46.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540283025920,"socket_broadcast":1540283025925,"before_db":1540283025931}'),
	('63de9cb7-d5bb-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/083100f0-d5bb-11e8-a5f9-c7d5eb1cc490.png', '2018-10-22 13:26:36.000', '[{"intent":"打招呼","confidence":0.0831786649817886},{"intent":"尋求資訊","confidence":0.07130005449930295},{"intent":"生氣","confidence":0.06846968663569585},{"intent":"謝謝","confidence":0.06815011949978499},{"intent":"罵髒話","confidence":0.06733028272407965},{"intent":"不想上班","confidence":0.0670605069192945},{"intent":"高興","confidence":0.06525069238661702},{"intent":"睡覺","confidence":0.06421116142604219},{"intent":"同情","confidence":0.06344697618641035},{"intent":"吃飯","confidence":0.06124624924404004}]', '紅橙色，飲料，食品，餐具，酒精飲料，混合飲料，雞尾酒', 'client', 'C0003', 'SE0001', NULL),
	('6dfaf71d-d82b-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 15:53:08.360', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540453988361,"assistant_call":1540453988371,"assistant_return":1540453989221,"mysql_call":1540453989221,"mysql_return":1540453989226,"socket_broadcast":1540453989226,"before_db_log":1540453989243}'),
	('7834b722-d692-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/1577eb70-d692-11e8-8a31-1d6034b34bb5.jpg', '2018-10-23 15:05:55.000', '[{"intent":"打招呼","confidence":0.10638635267444557},{"intent":"尋求資訊","confidence":0.09119348988506602},{"intent":"生氣","confidence":0.08757342079881597},{"intent":"謝謝","confidence":0.08716469120413423},{"intent":"罵髒話","confidence":0.0861161116870818},{"intent":"不想上班","confidence":0.08577106570783713},{"intent":"高興","confidence":0.08345629464014906},{"intent":"睡覺","confidence":0.08212672404158354},{"intent":"同情","confidence":0.0811493234012886},{"intent":"吃飯","confidence":0.07833457141311442}]', '灰色，灰色，人員，護士', 'client', 'C0003', 'SE0001', '{"socket_receive":1540278354876,"visualrecog_call":1540278354883,"visualrecog_return":1540278358067,"assistant_call":1540278359110,"assistant_return":1540278360333,"socket_broadcast":1540278360333,"before_db":1540278361086}'),
	('8221cc92-d823-11e8-a595-00090ffe0001', 'text', '213132', '2018-10-25 14:56:27.065', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540450587065,"socket_broadcast":1540450587070,"before_db_log":1540450587079}'),
	('87152111-d758-11e8-a595-00090ffe0001', 'text', '12312311', '2018-10-24 14:42:56.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363376350,"socket_broadcast":1540363400677,"before_db_log":1540363416777}'),
	('872d7541-d758-11e8-a595-00090ffe0001', 'text', '213', '2018-10-24 14:42:57.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363376680,"socket_broadcast":1540363401251,"before_db_log":1540363416927}'),
	('874979b3-d758-11e8-a595-00090ffe0001', 'text', '12', '2018-10-24 14:42:57.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363376862,"socket_broadcast":1540363401740,"before_db_log":1540363417120}'),
	('894edf21-d817-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 13:30:43.466', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540445443467,"assistant_call":1540445443472,"assistant_return":1540445445129,"socket_broadcast":1540445445130,"before_db_log":1540445445158}'),
	('8ab58bbb-d758-11e8-a595-00090ffe0001', 'text', '3', '2018-10-24 14:42:57.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377020,"socket_broadcast":1540363412661,"before_db_log":1540363422861}'),
	('8ad4d51e-d758-11e8-a595-00090ffe0001', 'text', '213', '2018-10-24 14:42:57.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377204,"socket_broadcast":1540363413181,"before_db_log":1540363422994}'),
	('8aec9f4e-d758-11e8-a595-00090ffe0001', 'text', '12', '2018-10-24 14:42:57.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377359,"socket_broadcast":1540363415769,"before_db_log":1540363423005}'),
	('8b0376c2-d758-11e8-a595-00090ffe0001', 'text', '3', '2018-10-24 14:42:58.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377528,"socket_broadcast":1540363415771,"before_db_log":1540363423006}'),
	('8b1baaef-d758-11e8-a595-00090ffe0001', 'text', '132', '2018-10-24 14:42:58.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377713,"socket_broadcast":1540363415773,"before_db_log":1540363423007}'),
	('8b325a3f-d758-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 14:42:58.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363377891,"socket_broadcast":1540363415774,"before_db_log":1540363423007}'),
	('8b493464-d758-11e8-a595-00090ffe0001', 'text', '421', '2018-10-24 14:42:58.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363378222,"socket_broadcast":1540363415777,"before_db_log":1540363423221}'),
	('8b6df1b0-d758-11e8-a595-00090ffe0001', 'text', '421', '2018-10-24 14:42:58.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363378393,"socket_broadcast":1540363415778,"before_db_log":1540363423222}'),
	('8b796dc9-d758-11e8-a595-00090ffe0001', 'text', '222', '2018-10-24 14:43:03.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363382641,"socket_broadcast":1540363415780,"before_db_log":1540363423494}'),
	('8b931790-d758-11e8-a595-00090ffe0001', 'text', '222', '2018-10-24 14:43:11.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363390696,"socket_broadcast":1540363416681,"before_db_log":1540363423509}'),
	('8bb1200c-d758-11e8-a595-00090ffe0001', 'text', '22', '2018-10-24 14:43:12.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363391535,"socket_broadcast":1540363416683,"before_db_log":1540363423525}'),
	('8bcd651b-d758-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 14:43:30.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363409874,"socket_broadcast":1540363417121,"before_db_log":1540363423590}'),
	('8bea24c9-d758-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 14:43:30.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363410342,"socket_broadcast":1540363417122,"before_db_log":1540363423597}'),
	('8c069b87-d758-11e8-a595-00090ffe0001', 'text', '22', '2018-10-24 14:43:31.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363411243,"socket_broadcast":1540363417133,"before_db_log":1540363423597}'),
	('8c1ab998-d758-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 14:43:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363411671,"socket_broadcast":1540363417135,"before_db_log":1540363423603}'),
	('8c3a52e9-d758-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 14:43:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363411942,"socket_broadcast":1540363419371,"before_db_log":1540363423606}'),
	('8c499a00-d758-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 14:43:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363412154,"socket_broadcast":1540363419372,"before_db_log":1540363423613}'),
	('8c58d433-d758-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 14:43:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363412310,"socket_broadcast":1540363421859,"before_db_log":1540363423614}'),
	('8c66c760-d758-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 14:43:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363412695,"socket_broadcast":1540363422986,"before_db_log":1540363423878}'),
	('8c82a234-d758-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 14:43:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363412913,"socket_broadcast":1540363422987,"before_db_log":1540363423951}'),
	('8d4d4c40-d758-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 14:43:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363413074,"socket_broadcast":1540363422991,"before_db_log":1540363427210}'),
	('8fca0318-d758-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 14:43:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363413260,"socket_broadcast":1540363422995,"before_db_log":1540363431384}'),
	('912464d5-d758-11e8-a595-00090ffe0001', 'text', '4', '2018-10-24 14:43:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363413430,"socket_broadcast":1540363422997,"before_db_log":1540363433654}'),
	('91309dc0-d758-11e8-a595-00090ffe0001', 'text', '2', '2018-10-24 14:43:34.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363413904,"socket_broadcast":1540363423000,"before_db_log":1540363433705}'),
	('914f78e6-d758-11e8-a595-00090ffe0001', 'text', '5', '2018-10-24 14:43:34.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540363414276,"socket_broadcast":1540363423002,"before_db_log":1540363433936}'),
	('9c6660cd-d815-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 13:16:57.029', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540444617030,"assistant_call":1540444617034,"assistant_return":1540444618189,"socket_broadcast":1540444618189,"before_db_log":1540444618194}'),
	('a35c3295-d815-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 13:17:09.146', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540444629147,"assistant_call":1540444629152,"assistant_return":1540444629867,"socket_broadcast":1540444629867,"before_db_log":1540444629873}'),
	('ab6cf343-d732-11e8-a595-00090ffe0001', 'text', '123', '2018-10-24 10:12:35.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540347155319,"assistant_call":1540347155326,"assistant_return":1540347156862,"socket_broadcast":1540347156862,"before_db_log":1540347156872}'),
	('aeef411f-d732-11e8-a595-00090ffe0001', 'text', 'RRRR', '2018-10-24 10:12:42.000', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001', '{"socket_receive":1540347161762,"assistant_call":1540347161767,"assistant_return":1540347162748,"socket_broadcast":1540347162748,"before_db_log":1540347162761}'),
	('b0fb3413-d825-11e8-a595-00090ffe0001', 'text', '我想', '2018-10-25 15:12:03.772', '[{"intent":"吃飯","confidence":0.4402834177017212},{"intent":"睡覺","confidence":0.4276889324188233},{"intent":"不想上班","confidence":0.3519213438034058},{"intent":"打招呼","confidence":0.2828812837600708},{"intent":"尋求資訊","confidence":0.27167291045188907},{"intent":"生氣","confidence":0.2688584685325623},{"intent":"謝謝","confidence":0.2684344530105591},{"intent":"高興","confidence":0.26541656255722046},{"intent":"同情","confidence":0.26351991891860965},{"intent":"罵髒話","confidence":0.2436951369047165}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540451523773,"assistant_call":1540451523778,"assistant_return":1540451524663,"socket_broadcast":1540451524664,"before_db_log":1540451524671}'),
	('b562e068-d823-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 14:57:53.060', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540450673060,"socket_broadcast":1540450673064,"before_db_log":1540450673070}'),
	('baccfd7c-d5cf-11e8-a595-00090ffe0001', 'text', '請問客服在嗎', '2018-10-22 15:52:11.000', '[{"intent":"尋求資訊","confidence":0.6827099323272705},{"intent":"打招呼","confidence":0.3224217534065247},{"intent":"生氣","confidence":0.2929953753948212},{"intent":"謝謝","confidence":0.2924854695796967},{"intent":"罵髒話","confidence":0.2908138334751129},{"intent":"不想上班","confidence":0.2901981592178345},{"intent":"高興","confidence":0.28650023937225344},{"intent":"睡覺","confidence":0.28433436155319214},{"intent":"同情","confidence":0.282719099521637},{"intent":"吃飯","confidence":0.27801045775413513}]', '', 'client', 'C0003', 'SE0001', NULL),
	('c158748f-d815-11e8-a595-00090ffe0001', 'text', '222', '2018-10-25 13:17:58.925', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540444678926,"assistant_call":1540444678943,"assistant_return":1540444680062,"socket_broadcast":1540444680062,"before_db_log":1540444680180}'),
	('c48bc395-d691-11e8-a595-00090ffe0001', 'text', '哈哈', '2018-10-23 15:01:00.000', '', '', 'service', 'SE0001', 'C0001', '{"request_time":1540278059714}'),
	('c57aae68-d815-11e8-a595-00090ffe0001', 'text', '3222332', '2018-10-25 13:18:05.724', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540444685726,"assistant_call":1540444685745,"assistant_return":1540444686873,"socket_broadcast":1540444686873,"before_db_log":1540444687115}'),
	('c8cb835d-d827-11e8-a595-00090ffe0001', 'text', '1', '2018-10-25 15:27:02.737', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540452422737,"assistant_call":1540452422749,"assistant_return":1540452423583,"socket_broadcast":1540452423583,"before_db_log":1540452423618}'),
	('ca26e04a-d827-11e8-a595-00090ffe0001', 'text', '我想', '2018-10-25 15:27:04.801', '[{"intent":"吃飯","confidence":0.4402834177017212},{"intent":"睡覺","confidence":0.4276889324188233},{"intent":"不想上班","confidence":0.3519213438034058},{"intent":"打招呼","confidence":0.2828812837600708},{"intent":"尋求資訊","confidence":0.27167291045188907},{"intent":"生氣","confidence":0.2688584685325623},{"intent":"謝謝","confidence":0.2684344530105591},{"intent":"高興","confidence":0.26541656255722046},{"intent":"同情","confidence":0.26351991891860965},{"intent":"罵髒話","confidence":0.2436951369047165}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540452424801,"assistant_call":1540452424805,"assistant_return":1540452425879,"socket_broadcast":1540452425880,"before_db_log":1540452425895}'),
	('cc94a1b7-d818-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 13:39:47.502', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540445987503,"socket_broadcast":1540445987506,"before_db_log":1540445987520}'),
	('cebc31aa-d823-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 14:58:35.585', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540450715586,"socket_broadcast":1540450715594,"before_db_log":1540450715598}'),
	('ced57b4e-d81b-11e8-a595-00090ffe0001', 'text', '很高興為您服務', '2018-10-25 14:01:19.722', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540447279723,"socket_broadcast":1540447279735,"before_db_log":1540447279790}'),
	('d02f648e-d6b1-11e8-a595-00090ffe0001', 'text', '123', '2018-10-23 18:50:23.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291823172,"socket_broadcast":1540291823177,"before_db_log":1540291823185}'),
	('d1b46c1b-d81b-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-25 14:01:24.570', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540447284570,"socket_broadcast":1540447284591,"before_db_log":1540447284606}'),
	('d315d700-d823-11e8-a595-00090ffe0001', 'text', '123132', '2018-10-25 14:58:42.883', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540450722884,"socket_broadcast":1540450722888,"before_db_log":1540450722897}'),
	('d360cfbf-d6b1-11e8-a595-00090ffe0001', 'text', '2232', '2018-10-23 18:50:29.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291828535,"socket_broadcast":1540291828538,"before_db_log":1540291828542}'),
	('d40ce5ff-d81b-11e8-a595-00090ffe0001', 'text', '謝謝', '2018-10-25 14:01:28.502', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540447288503,"socket_broadcast":1540447288513,"before_db_log":1540447288541}'),
	('d665f2d4-d823-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 14:58:47.589', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540450727591,"assistant_call":1540450727596,"assistant_return":1540450728447,"socket_broadcast":1540450728448,"before_db_log":1540450728455}'),
	('d6a48778-d6b1-11e8-a595-00090ffe0001', 'text', '77[', '2018-10-23 18:50:34.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291834008,"socket_broadcast":1540291834015,"before_db_log":1540291834020}'),
	('d9823d62-d6b1-11e8-a595-00090ffe0001', 'text', '1231223213', '2018-10-23 18:50:39.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291838815,"socket_broadcast":1540291838819,"before_db_log":1540291838828}'),
	('da0fa70c-d823-11e8-a595-00090ffe0001', 'text', 'for you', '2018-10-25 14:58:53.639', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540450733640,"assistant_call":1540450733644,"assistant_return":1540450734591,"socket_broadcast":1540450734591,"before_db_log":1540450734600}'),
	('db8285c2-d6b1-11e8-a595-00090ffe0001', 'text', '2222442424242', '2018-10-23 18:50:42.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291842174,"socket_broadcast":1540291842179,"before_db_log":1540291842185}'),
	('dd0710f5-d6b1-11e8-a595-00090ffe0001', 'text', '23323232', '2018-10-23 18:50:45.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291844721,"socket_broadcast":1540291844726,"before_db_log":1540291844731}'),
	('dda20179-d6b1-11e8-a595-00090ffe0001', 'text', '233232', '2018-10-23 18:50:46.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291845739,"socket_broadcast":1540291845742,"before_db_log":1540291845747}'),
	('de0e9fb6-d6b1-11e8-a595-00090ffe0001', 'text', '332', '2018-10-23 18:50:46.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291846449,"socket_broadcast":1540291846455,"before_db_log":1540291846459}'),
	('de54eb56-d6b1-11e8-a595-00090ffe0001', 'text', '322323', '2018-10-23 18:50:47.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291846908,"socket_broadcast":1540291846916,"before_db_log":1540291846920}'),
	('e672c130-d69c-11e8-a595-00090ffe0001', 'text', '22', '2018-10-23 16:20:41.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540282841095,"socket_broadcast":1540282841099,"before_db":1540282841105}'),
	('eb9965db-d81b-11e8-a595-00090ffe0001', 'text', '123', '2018-10-25 14:02:07.561', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540447327562,"socket_broadcast":1540447328039,"before_db_log":1540447328051}'),
	('f10b5560-d82a-11e8-a595-00090ffe0001', 'text', '我想', '2018-10-25 15:49:38.690', '[{"intent":"吃飯","confidence":0.4402834177017212},{"intent":"睡覺","confidence":0.4276889324188233},{"intent":"不想上班","confidence":0.3519213438034058},{"intent":"打招呼","confidence":0.2828812837600708},{"intent":"尋求資訊","confidence":0.27167291045188907},{"intent":"生氣","confidence":0.2688584685325623},{"intent":"謝謝","confidence":0.2684344530105591},{"intent":"高興","confidence":0.26541656255722046},{"intent":"同情","confidence":0.26351991891860965},{"intent":"罵髒話","confidence":0.2436951369047165}]', '', 'client', 'C0001', 'SE0001', '{"socket_receive":1540453778690,"assistant_call":1540453778698,"assistant_return":1540453779615,"mysql_call":1540453779615,"mysql_return":1540453779618,"socket_broadcast":1540453779619,"before_db_log":1540453779636}'),
	('f78ebddb-d6b1-11e8-a595-00090ffe0001', 'text', '123', '2018-10-23 18:51:29.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291889230,"socket_broadcast":1540291889235,"before_db_log":1540291889241}'),
	('f8899ccf-d6b1-11e8-a595-00090ffe0001', 'text', '123', '2018-10-23 18:51:31.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291890876,"socket_broadcast":1540291890879,"before_db_log":1540291890885}'),
	('f9282153-d6b1-11e8-a595-00090ffe0001', 'text', '2', '2018-10-23 18:51:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291891911,"socket_broadcast":1540291891915,"before_db_log":1540291891925}'),
	('f94d2df1-d6b1-11e8-a595-00090ffe0001', 'text', '2', '2018-10-23 18:51:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291892082,"socket_broadcast":1540291892089,"before_db_log":1540291892100}'),
	('f9619b2a-d6b1-11e8-a595-00090ffe0001', 'text', '2', '2018-10-23 18:51:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291892254,"socket_broadcast":1540291892260,"before_db_log":1540291892264}'),
	('f9772484-d6b1-11e8-a595-00090ffe0001', 'text', '2', '2018-10-23 18:51:32.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291892427,"socket_broadcast":1540291892438,"before_db_log":1540291892442}'),
	('f990358a-d6b1-11e8-a595-00090ffe0001', 'text', '2', '2018-10-23 18:51:33.000', '', '', 'service', 'SE0001', 'C0003', '{"socket_receive":1540291892591,"socket_broadcast":1540291892597,"before_db_log":1540291892607}');
/*!40000 ALTER TABLE `tb_message` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_responsibility 結構
CREATE TABLE IF NOT EXISTS `tb_responsibility` (
  `responsibility_id` char(40) NOT NULL,
  `manager_id` char(40) DEFAULT NULL,
  `customer_id` char(40) DEFAULT NULL,
  `conversation_title` varchar(60) DEFAULT NULL COMMENT '避免為了名字而每次join',
  `avator` varchar(100) DEFAULT NULL,
  `last_talk_time` datetime DEFAULT NULL,
  `last_message` varchar(200) DEFAULT NULL,
  `unread` int(11) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`responsibility_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_responsibility 的資料：~2 rows (大約)
/*!40000 ALTER TABLE `tb_responsibility` DISABLE KEYS */;
INSERT INTO `tb_responsibility` (`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `unread`, `note`, `memo`) VALUES
	('5d71d71d-d76b-11e8-a595-00090ffe0001', 'SE0001', 'C0001', 'CT200H/ABZ-1234/王一明', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-25 15:53:08', '123', 14, NULL, ''),
	('97c7b1a7-d6aa-11e8-a595-00090ffe0001', 'SE0001', 'C0003', 'CT201H/ABZ-1235/陳一為', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-25 14:58:43', '123132', 0, NULL, '');
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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks 的資料：~11 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks` DISABLE KEYS */;
INSERT INTO `tb_talk_tricks` (`id`, `type`, `manager_id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
	(1, 'dialog', 'SE0001', 'D0003', '["yeah","yeah","yeah"]', '吃飯'),
	(2, 'dialog', 'SE0001', 'D0004', '["很高興為您服務","謝謝","不客氣"]', '同情'),
	(3, 'dialog', 'SE0001', 'D0005', '["no","I\'m Fine","Thank you"]', '尋求資訊'),
	(4, 'dialog', 'SE0001', 'D0001', '["no","I\'m Fine","Thank you"]', '歡迎'),
	(5, 'dialog', 'SE0001', 'D0002', '["no","I\'m Fine","Thank you"]', '不想上班'),
	(6, 'dialog', 'SE0001', 'D0006', '["no","I\'m Fine","Thank you"]', '打招呼'),
	(7, 'dialog', 'SE0001', 'D0007', '["no","I\'m Fine","Thank you"]', '生氣'),
	(8, 'dialog', 'SE0001', 'D0008', '["no","I\'m Fine","Thank you"]', 'anything_else'),
	(9, 'dialog', 'SE0001', 'D0009', '["no","I\'m Fine","Thank you"]', NULL),
	(10, 'dialog', 'SE0001', 'D0010', '["no","I\'m Fine","Thank you"]', NULL),
	(11, 'dialog', 'SE0001', 'D0011', '["no","I\'m Fine","Thank you"]', NULL);
/*!40000 ALTER TABLE `tb_talk_tricks` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_talk_tricks_default 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks_default` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL,
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks_default 的資料：~11 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks_default` DISABLE KEYS */;
INSERT INTO `tb_talk_tricks_default` (`id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
	(2, 'D0002', '["很高興為您服務","謝謝您","造成您的困擾我深感抱歉，在此向您致上最深的歉意。"]', '不想上班'),
	(3, 'D0003', '["很高興為您服務","謝謝您","造成您的困擾我深感抱歉，在此向您致上最深的歉意。"]', '吃飯'),
	(4, 'D0004', '["很高興為您服務","謝謝您","造成您的困擾我深感抱歉，在此向您致上最深的歉意。"]', '同情'),
	(5, 'D0005', '["很高興為您服務","謝謝您","造成您的困擾我深感抱歉，在此向您致上最深的歉意。"]', '尋求資訊'),
	(6, 'D0006', '["my god","yes","no"]', '打招呼'),
	(7, 'D0007', '["my god","yes","no"]', '生氣'),
	(8, 'D0008', '["my god","yes","no"]', 'anything_else'),
	(9, 'D0009', '["my god","yes","no"]', NULL),
	(10, 'D0010', '["my god","yes","no"]', NULL),
	(11, 'D0011', '["my god","yes","no"]', NULL),
	(12, 'D0001', '["my god","yes","no"]', '歡迎');
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

-- 正在傾印表格  db_lexus_cs.tb_uploaded_picture 的資料：~1 rows (大約)
/*!40000 ALTER TABLE `tb_uploaded_picture` DISABLE KEYS */;
INSERT INTO `tb_uploaded_picture` (`id`, `customer_id`, `picture_name`, `picture_url`, `upload_time`) VALUES
	(1, '3a432ccc-245c-4364-9366-e8b52536fe35', 'tire_press.png', 'http://localhost:3000/uploaded/tire_pressure.png', '2018-10-18 12:46:09');
/*!40000 ALTER TABLE `tb_uploaded_picture` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.x_tb_intent_response 結構
CREATE TABLE IF NOT EXISTS `x_tb_intent_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intent` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.x_tb_intent_response 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `x_tb_intent_response` DISABLE KEYS */;
INSERT INTO `x_tb_intent_response` (`id`, `intent`, `response_1`, `response_2`, `response_3`) VALUES
	(1, '尋求資訊', '有什麼我可以為您服務的地方呢', '我想您需要的是OOXX 請打以下電話', '請問您的車子目前的狀況是?');
/*!40000 ALTER TABLE `x_tb_intent_response` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.x_tb_visualrecog_response 結構
CREATE TABLE IF NOT EXISTS `x_tb_visualrecog_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visualrecog` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.x_tb_visualrecog_response 的資料：~0 rows (大約)
/*!40000 ALTER TABLE `x_tb_visualrecog_response` DISABLE KEYS */;
INSERT INTO `x_tb_visualrecog_response` (`id`, `visualrecog`, `response_1`, `response_2`, `response_3`) VALUES
	(1, '胎壓警示燈', '這是胎壓指示燈，表示胎壓偏低，建議回廠檢查', '胎壓警示燈，建議於服務廠就近檢查', NULL);
/*!40000 ALTER TABLE `x_tb_visualrecog_response` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
