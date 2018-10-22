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


)
BEGIN
	/* 20181022 By Ben */
	/* call sp_send_message("text","哈囉","[]","","1540190376871","client","C0003","SE0001"); */
	/* call sp_send_message("text","哈囉","[]","","1540190376871","service","SE0001","C0003"); */
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
	(`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`) 
	VALUES
	(UUID(), p_message_type, p_content, p_datetime, p_intent_str, p_recognition_result, p_direction, p_from_id, p_to_id);
		
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

-- 傾印  表格 db_lexus_cs.tb_intent_response 結構
CREATE TABLE IF NOT EXISTS `tb_intent_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intent` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_intent_response 的資料：~1 rows (大約)
/*!40000 ALTER TABLE `tb_intent_response` DISABLE KEYS */;
INSERT INTO `tb_intent_response` (`id`, `intent`, `response_1`, `response_2`, `response_3`) VALUES
	(1, '尋求資訊', '有什麼我可以為您服務的地方呢', '我想您需要的是OOXX 請打以下電話', '請問您的車子目前的狀況是?');
/*!40000 ALTER TABLE `tb_intent_response` ENABLE KEYS */;

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
	('b09408c5-364a-4041-9bd3-8add2493e853', 'SE0001', 'CostomerService', '帥哥志豪', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', ''),
	('e2ddbfa4-a000-40f2-8da5-43add363aac1', 'SA0001', 'Sales', '美女麗雲', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', '');
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

-- 正在傾印表格  db_lexus_cs.tb_message 的資料：~74 rows (大約)
/*!40000 ALTER TABLE `tb_message` DISABLE KEYS */;
INSERT INTO `tb_message` (`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`) VALUES
	('0c180c3a-d5dd-11e8-a595-00090ffe0001', 'text', 'hello', '2018-10-22 17:27:31', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('0ce3480f-d5e6-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 18:31:59', '', '', 'service', 'SE0001', 'C0003'),
	('0f83f33f-d5df-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:41:57', '', '', 'service', 'SE0001', 'C0003'),
	('0ff3c239-d5df-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:41:57', '', '', 'service', 'SE0001', 'C0003'),
	('10bbb208-d5df-11e8-a595-00090ffe0001', 'text', '12414212123', '2018-10-22 17:41:59', '', '', 'service', 'SE0001', 'C0003'),
	('1205b3f1-d5e6-11e8-a595-00090ffe0001', 'text', '12312312', '2018-10-22 18:32:06', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('14af3e49-d5e6-11e8-a595-00090ffe0001', 'text', '@@@@', '2018-10-22 18:32:12', '', '', 'service', 'SE0001', 'C0003'),
	('16e435e1-d5e6-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 18:32:16', '', '', 'service', 'SE0001', 'C0001'),
	('181c9765-d5e6-11e8-a595-00090ffe0001', 'text', 'CCC', '2018-10-22 18:32:18', '', '', 'service', 'SE0001', 'C0001'),
	('1b8ff964-d5dd-11e8-a595-00090ffe0001', 'text', 'hello?', '2018-10-22 17:27:56', '[{"intent":"打招呼","confidence":0.12480454724904036},{"intent":"尋求資訊","confidence":0.10698141191092318},{"intent":"生氣","confidence":0.10273461641543094},{"intent":"謝謝","confidence":0.10225512528965056},{"intent":"罵髒話","confidence":0.10102500987925753},{"intent":"不想上班","confidence":0.10062022762911768},{"intent":"高興","confidence":0.09790471057429359},{"intent":"睡覺","confidence":0.09634495735014283},{"intent":"同情","confidence":0.09519834369786152},{"intent":"吃飯","confidence":0.09189628625655219}]', '', 'client', 'C0001', 'SE0001'),
	('1e2d0dcd-d5e6-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 18:32:27', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1ebe977f-d5e6-11e8-a595-00090ffe0001', 'text', '4', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1ed67c94-d5e6-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 18:32:27', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1f103378-d5e6-11e8-a595-00090ffe0001', 'text', '21', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1f2c7590-d5e6-11e8-a595-00090ffe0001', 'text', '124', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1f46cb66-d5e6-11e8-a595-00090ffe0001', 'text', '1', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1f6527b2-d5e6-11e8-a595-00090ffe0001', 'text', '4', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1f7f1008-d5e6-11e8-a595-00090ffe0001', 'text', '1', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1fa52fc7-d5e6-11e8-a595-00090ffe0001', 'text', '4', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1fc85aa0-d5e6-11e8-a595-00090ffe0001', 'text', '4', '2018-10-22 18:32:28', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1fe430a5-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('1ffe7696-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('2019329d-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('203e4924-d5e6-11e8-a595-00090ffe0001', 'text', '214', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('20521edf-d5dd-11e8-a595-00090ffe0001', 'text', '@@@', '2018-10-22 17:28:05', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('2058fd94-d5e6-11e8-a595-00090ffe0001', 'text', '21', '2018-10-22 18:32:29', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('206f4760-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:30', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('20934e75-d5e6-11e8-a595-00090ffe0001', 'text', '21', '2018-10-22 18:32:30', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('20b6ec91-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:30', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('20d3fe40-d5dd-11e8-a595-00090ffe0001', 'text', '@@@', '2018-10-22 17:28:05', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('20ddaea8-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:30', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('21041392-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:30', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('21229e2a-d5e6-11e8-a595-00090ffe0001', 'text', '421', '2018-10-22 18:32:31', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('2138ba89-d5dd-11e8-a595-00090ffe0001', 'text', '@@@', '2018-10-22 17:28:06', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('22e3ab08-d5df-11e8-a595-00090ffe0001', 'text', '22222', '2018-10-22 17:42:29', '', '', 'service', 'SE0001', 'C0001'),
	('2c436108-d5df-11e8-a595-00090ffe0001', 'text', '333', '2018-10-22 17:42:45', '', '', 'service', 'SE0001', 'C0001'),
	('4512a75f-d5e7-11e8-a595-00090ffe0001', 'text', '哈囉', '2018-10-22 18:40:43', '', '', 'service', 'SE0001', 'C0001'),
	('479b7bdb-d5e7-11e8-a595-00090ffe0001', 'text', '妳有什麼問題 妳說阿', '2018-10-22 18:40:47', '', '', 'service', 'SE0001', 'C0001'),
	('4a0f7e74-d5e7-11e8-a595-00090ffe0001', 'text', '說吧', '2018-10-22 18:40:51', '', '', 'service', 'SE0001', 'C0003'),
	('4b538f04-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:44', '', '', 'service', 'SE0001', 'C0003'),
	('4c62ab73-0031-4595-b59a-73285168b760', 'text', '哈囉 請問有人在嗎', '2018-10-18 11:44:54', '[{"intent":"尋求資訊","confidence":0.8483095169067383},{"intent":"打招呼","confidence":0.27784162759780884},{"intent":"生氣","confidence":0.26535335183143616}]', NULL, 'client', '3a432ccc-245c-4364-9366-e8b52536fe35', 'e2ddbfa4-a000-40f2-8da5-43add363aac1'),
	('5054bfce-d5e7-11e8-a595-00090ffe0001', 'text', '這不是來說了嗎', '2018-10-22 18:41:01', '[{"intent":"尋求資訊","confidence":0.6006868362426758},{"intent":"不想上班","confidence":0.405301308631897},{"intent":"同情","confidence":0.31871623992919923},{"intent":"打招呼","confidence":0.2779551506042481},{"intent":"罵髒話","confidence":0.2690021634101868},{"intent":"生氣","confidence":0.2654657900333405},{"intent":"高興","confidence":0.2626458764076233},{"intent":"謝謝","confidence":0.2514598309993744},{"intent":"睡覺","confidence":0.24956916570663454},{"intent":"吃飯","confidence":0.2462650090456009}]', '', 'client', 'C0003', 'SE0001'),
	('541dcc57-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:48', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('5421c755-d5e7-11e8-a595-00090ffe0001', 'text', '你們的那個OOXX很難用', '2018-10-22 18:41:06', '[{"intent":"高興","confidence":0.12473153168213999},{"intent":"打招呼","confidence":0.11101276008462761},{"intent":"尋求資訊","confidence":0.09744723064782833},{"intent":"謝謝","confidence":0.09383666447901219},{"intent":"罵髒話","confidence":0.09289578252422857},{"intent":"不想上班","confidence":0.09259381976321136},{"intent":"生氣","confidence":0.08944345093326832},{"intent":"睡覺","confidence":0.0893333639610077},{"intent":"同情","confidence":0.08843258497443005},{"intent":"吃飯","confidence":0.08590433142985035}]', '', 'client', 'C0003', 'SE0001'),
	('55d87370-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:49', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('5642fec2-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:50', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('56b2ffac-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:49', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('56ce02f3-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:51', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('56f9217d-d5e6-11e8-a595-00090ffe0001', 'text', '', '2018-10-22 18:33:51', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('63de9cb7-d5bb-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/083100f0-d5bb-11e8-a5f9-c7d5eb1cc490.png', '2018-10-22 13:26:36', '[{"intent":"打招呼","confidence":0.0831786649817886},{"intent":"尋求資訊","confidence":0.07130005449930295},{"intent":"生氣","confidence":0.06846968663569585},{"intent":"謝謝","confidence":0.06815011949978499},{"intent":"罵髒話","confidence":0.06733028272407965},{"intent":"不想上班","confidence":0.0670605069192945},{"intent":"高興","confidence":0.06525069238661702},{"intent":"睡覺","confidence":0.06421116142604219},{"intent":"同情","confidence":0.06344697618641035},{"intent":"吃飯","confidence":0.06124624924404004}]', '紅橙色，飲料，食品，餐具，酒精飲料，混合飲料，雞尾酒', 'client', 'C0003', 'SE0001'),
	('6d596947-d5d1-11e8-a595-00090ffe0001', 'text', '哈囉', '2018-10-22 16:04:20', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001'),
	('7362cfda-d5df-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:44:44', '', '', 'service', 'SE0001', 'C0003'),
	('741ae8c4-d5df-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:44:45', '', '', 'service', 'SE0001', 'C0003'),
	('754605a6-d5d1-11e8-a595-00090ffe0001', 'text', '你在嗎', '2018-10-22 16:04:33', '[{"intent":"尋求資訊","confidence":0.5353703975677491},{"intent":"謝謝","confidence":0.4245968341827393},{"intent":"同情","confidence":0.29919591546058655},{"intent":"打招呼","confidence":0.2536240816116333},{"intent":"生氣","confidence":0.24908681809902192},{"intent":"罵髒話","confidence":0.24891038537025453},{"intent":"不想上班","confidence":0.2488194763660431},{"intent":"高興","confidence":0.24821758270263672},{"intent":"睡覺","confidence":0.24787375032901765},{"intent":"吃飯","confidence":0.24674625098705294}]', '', 'client', 'C0001', 'SE0001'),
	('a5e7f209-d5df-11e8-a595-00090ffe0001', 'text', '1231231', '2018-10-22 17:46:08', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('a6fd1d13-d5df-11e8-a595-00090ffe0001', 'text', '2312321', '2018-10-22 17:46:08', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('b159f1f7-d5df-11e8-a595-00090ffe0001', 'image', 'http://localhost:3000/images/uploaded/54686070-d5df-11e8-a8bc-b771c13c8e58.jpg', '2018-10-22 17:46:21', '[{"intent":"打招呼","confidence":0.08590847070276482},{"intent":"尋求資訊","confidence":0.07364002108473358},{"intent":"生氣","confidence":0.07071676456526461},{"intent":"謝謝","confidence":0.07038670968954648},{"intent":"罵髒話","confidence":0.06953996703453812},{"intent":"不想上班","confidence":0.06926133757075946},{"intent":"高興","confidence":0.06739212749396871},{"intent":"睡覺","confidence":0.06631848060277717},{"intent":"同情","confidence":0.06552921588826449},{"intent":"吃飯","confidence":0.06325626421135554}]', '灰色，灰色，人，理療師', 'client', 'C0003', 'SE0001'),
	('baccfd7c-d5cf-11e8-a595-00090ffe0001', 'text', '請問客服在嗎', '2018-10-22 15:52:11', '[{"intent":"尋求資訊","confidence":0.6827099323272705},{"intent":"打招呼","confidence":0.3224217534065247},{"intent":"生氣","confidence":0.2929953753948212},{"intent":"謝謝","confidence":0.2924854695796967},{"intent":"罵髒話","confidence":0.2908138334751129},{"intent":"不想上班","confidence":0.2901981592178345},{"intent":"高興","confidence":0.28650023937225344},{"intent":"睡覺","confidence":0.28433436155319214},{"intent":"同情","confidence":0.282719099521637},{"intent":"吃飯","confidence":0.27801045775413513}]', '', 'client', 'C0003', 'SE0001'),
	('be3d5b4e-d5cf-11e8-a595-00090ffe0001', 'text', '我在 請說', '2018-10-22 15:52:18', '', '', 'service', 'SE0001', 'C0003'),
	('c3378f69-d5d9-11e8-a595-00090ffe0001', 'text', '蝦?', '2018-10-22 17:03:58', '[{"intent":"打招呼","confidence":0.12480454724904036},{"intent":"尋求資訊","confidence":0.10698141191092318},{"intent":"生氣","confidence":0.10273461641543094},{"intent":"謝謝","confidence":0.10225512528965056},{"intent":"罵髒話","confidence":0.10102500987925753},{"intent":"不想上班","confidence":0.10062022762911768},{"intent":"高興","confidence":0.09790471057429359},{"intent":"睡覺","confidence":0.09634495735014283},{"intent":"同情","confidence":0.09519834369786152},{"intent":"吃飯","confidence":0.09189628625655219}]', '', 'client', 'C0001', 'SE0001'),
	('ccfb9d45-d5d9-11e8-a595-00090ffe0001', 'text', '哈囉 在嗎', '2018-10-22 17:04:18', '', '', 'service', 'SE0001', 'C0003'),
	('cf4fb90f-d5d9-11e8-a595-00090ffe0001', 'text', 'QQ', '2018-10-22 17:04:22', '', '', 'service', 'SE0001', 'C0003'),
	('d0ce343a-d5d9-11e8-a595-00090ffe0001', 'text', '別這樣', '2018-10-22 17:04:24', '', '', 'service', 'SE0001', 'C0003'),
	('d864dcb7-d5d9-11e8-a595-00090ffe0001', 'text', 'XDD', '2018-10-22 17:04:35', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0003', 'SE0001'),
	('d9a82891-d5d9-11e8-a595-00090ffe0001', 'text', '嚇死我了', '2018-10-22 17:04:37', '[{"intent":"同情","confidence":0.12288786943271007},{"intent":"睡覺","confidence":0.12244524586538007},{"intent":"吃飯","confidence":0.12016057029665746},{"intent":"打招呼","confidence":0.11580924061006144},{"intent":"尋求資訊","confidence":0.10353606378294204},{"intent":"生氣","confidence":0.1005982618213956},{"intent":"高興","confidence":0.09718795610944682},{"intent":"罵髒話","confidence":0.09300392144234487},{"intent":"謝謝","confidence":0.09273342656344391},{"intent":"不想上班","confidence":0.08628079990790243}]', '', 'client', 'C0003', 'SE0001'),
	('dc513705-d5de-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:40:31', '', '', 'service', 'SE0001', 'C0003'),
	('dcd55763-d5d9-11e8-a595-00090ffe0001', 'text', '挺正常的嗎', '2018-10-22 17:04:43', '[{"intent":"尋求資訊","confidence":0.6827099323272705},{"intent":"打招呼","confidence":0.3224217534065247},{"intent":"生氣","confidence":0.2929953753948212},{"intent":"謝謝","confidence":0.2924854695796967},{"intent":"罵髒話","confidence":0.2908138334751129},{"intent":"不想上班","confidence":0.2901981592178345},{"intent":"高興","confidence":0.28650023937225344},{"intent":"睡覺","confidence":0.28433436155319214},{"intent":"同情","confidence":0.282719099521637},{"intent":"吃飯","confidence":0.27801045775413513}]', '', 'client', 'C0001', 'SE0001'),
	('de09ee42-d5d9-11e8-a595-00090ffe0001', 'text', '大概', '2018-10-22 17:04:45', '[{"intent":"打招呼","confidence":0.08744434833526613},{"intent":"尋求資訊","confidence":0.0749565625190735},{"intent":"生氣","confidence":0.07198104381561281},{"intent":"謝謝","confidence":0.07164508819580079},{"intent":"罵髒話","confidence":0.07078320741653443},{"intent":"不想上班","confidence":0.07049959659576417},{"intent":"高興","confidence":0.06859696865081788},{"intent":"睡覺","confidence":0.06750412702560425},{"intent":"同情","confidence":0.06670075178146362},{"intent":"吃飯","confidence":0.06438716411590577}]', '', 'client', 'C0001', 'SE0001'),
	('de849dc1-d5de-11e8-a595-00090ffe0001', 'text', '123132', '2018-10-22 17:40:35', '', '', 'service', 'SE0001', 'C0001'),
	('e13a53c1-d5de-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:40:39', '', '', 'service', 'SE0001', 'C0003'),
	('e3058f90-d5de-11e8-a595-00090ffe0001', 'text', '123123', '2018-10-22 17:40:42', '', '', 'service', 'SE0001', 'C0003'),
	('e377e98c-d5de-11e8-a595-00090ffe0001', 'text', '123123123', '2018-10-22 17:40:43', '', '', 'service', 'SE0001', 'C0003'),
	('e4107b82-d5de-11e8-a595-00090ffe0001', 'text', '142124124', '2018-10-22 17:40:44', '', '', 'service', 'SE0001', 'C0003'),
	('e7fe0024-d5de-11e8-a595-00090ffe0001', 'text', '@@DFASOIFOJSAFJISAF', '2018-10-22 17:40:46', '', '', 'service', 'SE0001', 'C0003');
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
	('0c310508-d5dd-11e8-a595-00090ffe0001', 'SE0001', 'C0003', 'CT201H/ABZ-1235/陳一為', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-22 18:41:06', '你們的那個OOXX很難用', 2, NULL, ''),
	('1ba677a4-d5dd-11e8-a595-00090ffe0001', 'SE0001', 'C0001', 'CT200H/ABZ-1234/王一明', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-22 18:40:47', '妳有什麼問題 妳說阿', 0, NULL, '');
/*!40000 ALTER TABLE `tb_responsibility` ENABLE KEYS */;

-- 傾印  表格 db_lexus_cs.tb_talk_tricks 結構
CREATE TABLE IF NOT EXISTS `tb_talk_tricks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `manager_id` char(40) DEFAULT NULL,
  `talk_trick` varchar(2000) DEFAULT '["很高興為您服務","謝謝您","造成您的困擾我深感抱歉，在此向您致上最深的歉意。"]' COMMENT '預期是jsonarray',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_talk_tricks 的資料：~1 rows (大約)
/*!40000 ALTER TABLE `tb_talk_tricks` DISABLE KEYS */;
INSERT INTO `tb_talk_tricks` (`id`, `manager_id`, `talk_trick`) VALUES
	(1, 'e2ddbfa4-a000-40f2-8da5-43add363aac1', '["很高興為您服務","謝謝","不客氣"]');
/*!40000 ALTER TABLE `tb_talk_tricks` ENABLE KEYS */;

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

-- 傾印  表格 db_lexus_cs.tb_visualrecog_response 結構
CREATE TABLE IF NOT EXISTS `tb_visualrecog_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visualrecog` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8;

-- 正在傾印表格  db_lexus_cs.tb_visualrecog_response 的資料：~1 rows (大約)
/*!40000 ALTER TABLE `tb_visualrecog_response` DISABLE KEYS */;
INSERT INTO `tb_visualrecog_response` (`id`, `visualrecog`, `response_1`, `response_2`, `response_3`) VALUES
	(1, '胎壓警示燈', '這是胎壓指示燈，表示胎壓偏低，建議回廠檢查', '胎壓警示燈，建議於服務廠就近檢查', NULL);
/*!40000 ALTER TABLE `tb_visualrecog_response` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
