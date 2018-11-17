-- phpMyAdmin SQL Dump
-- version 4.0.10deb1
-- http://www.phpmyadmin.net
--
-- 主機: localhost
-- 建立日期: 2018 年 11 月 16 日 17:00
-- 伺服器版本: 5.7.15-0ubuntu2
-- PHP 版本: 5.5.9-1ubuntu4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- 資料庫: `db_lexus_cs`
--

DELIMITER $$
--
-- Procedure
--
CREATE DEFINER=`root`@`%` PROCEDURE `sp_bind_client`(IN `p_manager_id` VARCHAR(50), IN `p_customer_id` VARCHAR(50), IN `p_customer_name` VARCHAR(20), IN `p_vehicle_type` VARCHAR(20), IN `p_vehicle_number` VARCHAR(20), IN `p_avator` VARCHAR(500), IN `p_telphone` VARCHAR(20), IN `p_fend_date` VARCHAR(20), IN `p_uend_date` VARCHAR(20), IN `p_birth_date` VARCHAR(20), IN `p_f_flag` VARCHAR(10), IN `p_u_flag` VARCHAR(10), IN `p_birth_flag` VARCHAR(10), IN `p_personal_data` VARCHAR(2000), IN `p_notify_data` VARCHAR(200))
BEGIN
	/* 20181022 By Ben */
	/* call sp_bind_client("SE0001","C0003","王二明",'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '{"討厭的維修時間":"平日上班"}'); */
	DECLARE p_conversation_title varchar(60);
	DECLARE p_conversation_avator varchar(500);
	
	IF NOT EXISTS (
		SELECT customer_id FROM tb_customer WHERE ht_id = p_customer_id
	)THEN
		INSERT INTO tb_customer
		(`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `fend_date`, `uend_date`, `birth_date`, `f_flag`, `u_flag`, `birth_flag`, `personal_data`, `personal_data_time`, `memo`) 
		VALUES (UUID(), p_customer_id, p_customer_name, p_vehicle_type, p_vehicle_number, p_avator, p_telphone, p_fend_date, p_uend_date, p_birth_date, p_f_flag, p_u_flag, p_birth_flag, IFNULL(p_personal_data,"{}"), NOW(), NULL);
	ELSE
		UPDATE tb_customer SET telphone = p_telphone WHERE ht_id = p_customer_id;
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
	
END$$

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
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_manager_list`(IN `p_manager_id` VARCHAR(50))
BEGIN
	/* 20181022 By Ben */
	/* call sp_select_manager_list("SE0001"); */
	
	/*SELECT customer_id, conversation_title, customer_nickname, avator, last_talk_time, last_message, manager_unread, notify_data
	from tb_responsibility WHERE manager_id = p_manager_id ORDER BY last_talk_time DESC;
	
	/* 20181112 By Cat */

	
	SELECT tb_responsibility.customer_id, tb_responsibility.conversation_title, tb_responsibility.customer_nickname, tb_responsibility.avator, tb_responsibility.last_talk_time, tb_responsibility.last_message, tb_responsibility.manager_unread, tb_responsibility.notify_data
	FROM tb_responsibility LEFT OUTER JOIN tb_customer ON tb_responsibility.customer_id=tb_customer.ht_id WHERE tb_responsibility.manager_id = p_manager_id;

END$$

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
END$$

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
	
END$$

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
	
END$$

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
	
END$$

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
	
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- 資料表結構 `tb_customer`
--

CREATE TABLE IF NOT EXISTS `tb_customer` (
  `customer_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `vehicle_type` varchar(20) DEFAULT NULL,
  `vehicle_number` varchar(20) DEFAULT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `telphone` varchar(20) DEFAULT NULL,
  `fend_date` varchar(20) NOT NULL,
  `uend_date` varchar(20) NOT NULL,
  `birth_date` varchar(20) NOT NULL,
  `f_flag` varchar(10) NOT NULL,
  `u_flag` varchar(10) NOT NULL,
  `birth_flag` varchar(10) NOT NULL,
  `personal_data` varchar(2000) DEFAULT NULL,
  `personal_data_time` datetime DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 資料表的匯出資料 `tb_customer`
--

INSERT INTO `tb_customer` (`customer_id`, `ht_id`, `name`, `vehicle_type`, `vehicle_number`, `avator`, `telphone`, `fend_date`, `uend_date`, `birth_date`, `f_flag`, `u_flag`, `birth_flag`, `personal_data`, `personal_data_time`, `memo`) VALUES
('3a432ccc-245c-4364-9366-e8b52536fe35', 'C0003', '陳一為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863542', '2018-11-14', '2018-11-07', '2018-11-01', '', '', '', '{"車險到期日":"2018-11-28"}', '2018-10-18 11:30:32', NULL),
('4ˋ03a2f73-947e-416b-9d19-c8a7c3e93849', 'C0004', '陳二為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863012', '2018-11-13', '2018-11-08', '2018-11-06', '', '', '', NULL, '2018-10-18 11:30:32', NULL),
('5c4972ee-8edb-4f11-9197-30734ca1f093', 'C0005', '陳三為', 'CT201H', 'ABZ-1235', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863012', '2018-11-14', '2018-11-14', '2018-11-14', '', '', '', NULL, '2018-10-18 11:30:32', NULL),
('a03b74a9-e871-11e8-bda8-005056af8f8b', '0f5ed5753fb59566648e88cb7ea34fe2', '踢哪??', 'IS300h', 'RBD-0021', 'http://dl.profile.line-cdn.net/0m02adf41c7251251f5ccef2a4b5ba67a996a6138bc8fb', '', '', '', '        ', 'N', 'N', 'N', '{}', '2018-11-15 08:58:55', NULL),
('a042851d-e871-11e8-bda8-005056af8f8b', '7aa1875c2c207ca13910843275289b32', '威宇', 'IS300h', 'RBD-0021', 'https://profile.line-scdn.net/0hT_QnekaKC3BsFyai_Mh0J1BSBR0bOQ04FCIRFh4SAkkRdU0jUXQWQUAUUUhCd0p1VXMWEkkQBhUS', '091299****', '', '', '        ', 'N', 'N', 'N', '{}', '2018-11-15 08:58:55', NULL),
('dd71bed7-610c-421e-af12-4d03264cd5c1', 'C0001', '王一明', 'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '2018-11-08', '2018-11-08', '2018-11-06', '', '', '', '{"討厭的維修時間":"平日上班"}', '2018-10-18 11:30:32', NULL),
('efe25070-8ec2-4bb5-b831-259b01bbd972', 'C0002', '王二明', 'CT200H', 'ABZ-1234', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '0919863010', '2018-11-22', '2018-11-21', '2018-11-21', '', '', '', '{"討厭的維修時間":"平日上班"}', '2018-10-18 11:30:32', NULL);

-- --------------------------------------------------------

--
-- 資料表結構 `tb_manager`
--

CREATE TABLE IF NOT EXISTS `tb_manager` (
  `manager_id` char(40) NOT NULL,
  `ht_id` varchar(50) DEFAULT NULL,
  `login` varchar(10) DEFAULT 'N',
  `compid` varchar(20) DEFAULT NULL,
  `dlrcd` varchar(20) DEFAULT NULL,
  `brnchcd` varchar(20) DEFAULT NULL,
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

--
-- 資料表的匯出資料 `tb_manager`
--

INSERT INTO `tb_manager` (`manager_id`, `ht_id`, `login`, `compid`, `dlrcd`, `brnchcd`, `sectcd`, `manager_type`, `manager_name`, `avator`, `telphone`, `personal_data`, `personal_data_time`, `memo`) VALUES
('9d566c95-e6e8-11e8-bda8-005056af8f8b', 'AA94453', 'Y', NULL, NULL, NULL, NULL, 'D', '預設管理員1', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', 'NULL', '{}', '2018-11-13 10:05:38', ''),
('a037007e-e871-11e8-bda8-005056af8f8b', 'AA99061', 'Y', NULL, NULL, NULL, NULL, 'D', '**忠', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', 'NULL', '{}', '2018-11-15 08:58:55', ''),
('b09408c5-364a-4041-9bd3-8add2493e853', 'SE0001', 'N', NULL, NULL, NULL, NULL, 'CostomerService', '帥哥志豪', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', ''),
('e2ddbfa4-a000-40f2-8da5-43add363aac1', 'SA0001', 'N', NULL, NULL, NULL, NULL, 'Sales', '美女麗雲', 'https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png', '0919863110', '{"常駐據點":"濱江廠","負責數量":"5"}', '2018-10-18 11:43:50', '');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_message`
--

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

--
-- 資料表的匯出資料 `tb_message`
--

INSERT INTO `tb_message` (`message_id`, `message_type`, `content`, `time`, `assistant_ans`, `visualrecog_ans`, `direction_type`, `from`, `to`, `push`, `time_record`) VALUES
('00769b83-db21-11e8-bda8-005056af8f8b', 'text', '123', '2018-10-29 10:19:10.015', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540779548667,"assistant_call":1540779548668,"assistant_return":1540779549442,"mysql_call":1540779549442,"mysql_return":1540779549443,"socket_broadcast":1540779549443,"before_db_log":1540779549445}'),
('00ed7995-db1c-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/0201cdc0-db1c-11e8-8e61-9f627c86b4e0.jpg', '2018-10-29 09:43:17.437', '[]', '香草豆，食品配料，食品，食品，調料，機械，工具，煤黑色，灰色', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540777397440,"visualrecog_call":1540777397447,"visualrecog_return":1540777400531,"assistant_call":1540777401856,"assistant_return":1540777402886,"mysql_call":1540777402890,"mysql_return":1540777402894,"socket_broadcast":1540777402895,"before_db_log":1540777402911}'),
('02873883-db53-11e8-bda8-005056af8f8b', 'text', '我', '2018-10-29 16:17:02.177', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540801022179,"assistant_call":1540801022181,"assistant_return":1540801027830,"mysql_call":1540801027830,"mysql_return":1540801027833,"socket_broadcast":1540801027833,"before_db_log":1540801027839}'),
('03cc8ade-db21-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:19:15.426', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540779554075,"assistant_call":1540779554076,"assistant_return":1540779555038,"mysql_call":1540779555038,"mysql_return":1540779555039,"socket_broadcast":1540779555039,"before_db_log":1540779555041}'),
('0bbb3089-e72e-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-13 18:22:44.410', '[{"intent":"不想上班","confidence":1}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542104564411,"assistant_call":1542104564412,"assistant_return":1542104566866,"mysql_call":1542104566866,"mysql_return":1542104566870,"socket_broadcast":1542104566870,"before_db_log":1542104566871}'),
('0d514501-e7f1-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-14 17:38:40.519', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542188320523,"assistant_call":1542188320524,"assistant_return":1542188321497,"mysql_call":1542188321497,"mysql_return":1542188321518,"socket_broadcast":1542188321518,"before_db_log":1542188321519}'),
('0dab4b48-e71a-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-13 15:59:39.222', '[{"intent":"不想上班","confidence":1}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542095979224,"assistant_call":1542095979225,"assistant_return":1542095980178,"mysql_call":1542095980178,"mysql_return":1542095980189,"socket_broadcast":1542095980189,"before_db_log":1542095980190}'),
('1215456b-db35-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 12:42:49.049', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540788169049,"assistant_call":1540788169055,"assistant_return":1540788169989,"mysql_call":1540788169989,"mysql_return":1540788169992,"socket_broadcast":1540788169993,"before_db_log":1540788169100}'),
('12471786-db35-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 12:42:49.049', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540788169049,"assistant_call":1540788168074,"assistant_return":1540788169409,"mysql_call":1540788169410,"mysql_return":1540788169415,"socket_broadcast":1540788169415,"before_db_log":1540788169427}'),
('14d02c1e-e71a-11e8-bda8-005056af8f8b', 'text', 'default不想上班', '2018-11-13 15:59:52.165', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542095992166,"socket_broadcast":1542095992166,"before_db_log":1542095992167}'),
('1a1e7b2c-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:34:11.842', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780451842,"assistant_call":1540780451852,"assistant_return":1540780452588,"mysql_call":1540780452588,"mysql_return":1540780452590,"socket_broadcast":1540780452591,"before_db_log":1540780451645}'),
('1bc5e56f-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:34:11.842', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780451842,"assistant_call":1540780450928,"assistant_return":1540780454412,"mysql_call":1540780454412,"mysql_return":1540780454416,"socket_broadcast":1540780454416,"before_db_log":1540780454421}'),
('1be15f49-e7f4-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/1fc6d140-e7f4-11e8-b156-5341c1676f3a.jpg', '2018-11-14 18:00:32.696', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542189632701,"visualrecog_call":1542189632706,"visualrecog_return":1542189632738,"assistant_call":1542189633663,"assistant_return":1542189634430,"mysql_call":1542189634430,"mysql_return":1542189634450,"socket_broadcast":1542189634450,"before_db_log":1542189634454}'),
('1e32c6dc-db54-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 16:25:02.898', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540801502900,"assistant_call":1540801502903,"assistant_return":1540801503747,"mysql_call":1540801503749,"mysql_return":1540801503752,"socket_broadcast":1540801503752,"before_db_log":1540801503756}'),
('1eef9e12-dbf0-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/224dd400-dbf0-11e8-a857-c5cba82c95f7.jpg', '2018-10-30 11:01:44.936', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540868504938,"visualrecog_call":1540868504941,"visualrecog_return":1540868504996,"assistant_call":1540868505824,"assistant_return":1540868506739,"mysql_call":1540868506740,"mysql_return":1540868506741,"socket_broadcast":1540868506741,"before_db_log":1540868506746}'),
('2dfc68fd-e970-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-16 15:21:14.254', '[]', '', 'client', '7aa1875c2c207ca13910843275289b32', 'AA99061', 'false', '{"socket_receive":1542352874256,"assistant_call":1542352874256,"assistant_return":1542352875219,"mysql_call":1542352875219,"mysql_return":1542352875236,"socket_broadcast":1542352875236,"before_db_log":1542352875236}'),
('36b44448-e7f4-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/39aebeb0-e7f4-11e8-812f-a3865d289ff8.png', '2018-11-14 18:01:16.106', '[]', '黑顏色，人物，黑色，動物，家畜，狗，獵狗，西高地白梗犬，人', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542189676107,"visualrecog_call":1542189676109,"visualrecog_return":1542189677322,"assistant_call":1542189678549,"assistant_return":1542189679452,"mysql_call":1542189679452,"mysql_return":1542189679457,"socket_broadcast":1542189679457,"before_db_log":1542189679458}'),
('376eb03a-db1b-11e8-bda8-005056af8f8b', 'text', 'mmmm', '2018-10-29 09:37:43.724', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540777063726,"assistant_call":1540777063733,"assistant_return":1540777064846,"mysql_call":1540777064846,"mysql_return":1540777064851,"socket_broadcast":1540777064851,"before_db_log":1540777064857}'),
('37c1b42c-db1c-11e8-bda8-005056af8f8b', 'text', '有別的說法嗎', '2018-10-29 09:44:54.876', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777494879,"socket_broadcast":1540777494885,"before_db_log":1540777494896}'),
('415b05e7-e70a-11e8-bda8-005056af8f8b', 'text', '已為您取消 2018/10/29 08:30 於 LS新莊廠     的 定期保養 預約', '2018-11-13 14:06:34.967', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542089194971,"socket_broadcast":1542089194972,"before_db_log":1542089194973}'),
('4246ce2f-db1b-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 09:38:02.052', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540777082058,"assistant_call":1540777082065,"assistant_return":1540777083042,"mysql_call":1540777083042,"mysql_return":1540777083046,"socket_broadcast":1540777083046,"before_db_log":1540777083051}'),
('427b9beb-db1c-11e8-bda8-005056af8f8b', 'text', '1', '2018-10-29 09:45:12.864', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777512869,"socket_broadcast":1540777512880,"before_db_log":1540777512894}'),
('42ac632e-db1c-11e8-bda8-005056af8f8b', 'text', '2', '2018-10-29 09:45:13.201', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777513203,"socket_broadcast":1540777513208,"before_db_log":1540777513213}'),
('42e0b101-db1c-11e8-bda8-005056af8f8b', 'text', '3', '2018-10-29 09:45:13.540', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777513543,"socket_broadcast":1540777513548,"before_db_log":1540777513556}'),
('4315793e-db1c-11e8-bda8-005056af8f8b', 'text', '4', '2018-10-29 09:45:13.880', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777513884,"socket_broadcast":1540777513889,"before_db_log":1540777513901}'),
('43634362-db1c-11e8-bda8-005056af8f8b', 'text', '5', '2018-10-29 09:45:14.396', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777514399,"socket_broadcast":1540777514404,"before_db_log":1540777514412}'),
('439e8d3c-db1c-11e8-bda8-005056af8f8b', 'text', '6', '2018-10-29 09:45:14.782', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777514785,"socket_broadcast":1540777514792,"before_db_log":1540777514798}'),
('43ee66f7-db1c-11e8-bda8-005056af8f8b', 'text', '7', '2018-10-29 09:45:15.304', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777515309,"socket_broadcast":1540777515316,"before_db_log":1540777515324}'),
('44357eb3-db1c-11e8-bda8-005056af8f8b', 'text', '8', '2018-10-29 09:45:15.777', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777515780,"socket_broadcast":1540777515785,"before_db_log":1540777515790}'),
('446e7033-db1c-11e8-bda8-005056af8f8b', 'text', '9', '2018-10-29 09:45:16.141', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777516147,"socket_broadcast":1540777516155,"before_db_log":1540777516163}'),
('44a986b1-db1c-11e8-bda8-005056af8f8b', 'text', '0', '2018-10-29 09:45:16.528', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777516531,"socket_broadcast":1540777516538,"before_db_log":1540777516551}'),
('4504f435-db1c-11e8-bda8-005056af8f8b', 'text', '1', '2018-10-29 09:45:17.130', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777517134,"socket_broadcast":1540777517140,"before_db_log":1540777517150}'),
('4542568c-db1c-11e8-bda8-005056af8f8b', 'text', '2', '2018-10-29 09:45:17.533', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777517538,"socket_broadcast":1540777517545,"before_db_log":1540777517552}'),
('4585d267-db1c-11e8-bda8-005056af8f8b', 'text', '3', '2018-10-29 09:45:17.975', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777517980,"socket_broadcast":1540777517986,"before_db_log":1540777517994}'),
('45c0cc6c-db1c-11e8-bda8-005056af8f8b', 'text', '4', '2018-10-29 09:45:18.362', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777518367,"socket_broadcast":1540777518372,"before_db_log":1540777518381}'),
('45fd4b6d-db1c-11e8-bda8-005056af8f8b', 'text', '5', '2018-10-29 09:45:18.757', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777518766,"socket_broadcast":1540777518772,"before_db_log":1540777518777}'),
('463ad94b-db1c-11e8-bda8-005056af8f8b', 'text', '6', '2018-10-29 09:45:19.160', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777519164,"socket_broadcast":1540777519172,"before_db_log":1540777519180}'),
('467d211c-db1c-11e8-bda8-005056af8f8b', 'text', '7', '2018-10-29 09:45:19.594', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777519600,"socket_broadcast":1540777519607,"before_db_log":1540777519615}'),
('46d73eef-db1c-11e8-bda8-005056af8f8b', 'text', '8', '2018-10-29 09:45:20.189', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777520192,"socket_broadcast":1540777520199,"before_db_log":1540777520206}'),
('471fe879-db1c-11e8-bda8-005056af8f8b', 'text', '9', '2018-10-29 09:45:20.662', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777520666,"socket_broadcast":1540777520674,"before_db_log":1540777520682}'),
('475806e3-db1c-11e8-bda8-005056af8f8b', 'text', '0', '2018-10-29 09:45:21.026', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777521031,"socket_broadcast":1540777521039,"before_db_log":1540777521050}'),
('4862afb2-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:35:29.481', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780529482,"assistant_call":1540780529494,"assistant_return":1540780530209,"mysql_call":1540780530209,"mysql_return":1540780530211,"socket_broadcast":1540780530212,"before_db_log":1540780529266}'),
('486a5d00-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:35:29.481', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780529482,"assistant_call":1540780528343,"assistant_return":1540780529270,"mysql_call":1540780529270,"mysql_return":1540780529311,"socket_broadcast":1540780529311,"before_db_log":1540780529316}'),
('4f099bde-e7f1-11e8-bda8-005056af8f8b', 'text', '666', '2018-11-14 17:40:30.444', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542188430445,"assistant_call":1542188430446,"assistant_return":1542188431789,"mysql_call":1542188431789,"mysql_return":1542188431793,"socket_broadcast":1542188431793,"before_db_log":1542188431795}'),
('4f1d10ed-db21-11e8-bda8-005056af8f8b', 'text', '123', '2018-10-29 10:21:21.970', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540779680638,"assistant_call":1540779680639,"assistant_return":1540779681395,"mysql_call":1540779681395,"mysql_return":1540779681396,"socket_broadcast":1540779681396,"before_db_log":1540779681398}'),
('4f5e8288-e979-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-16 16:26:35.798', '[]', '', 'client', '7aa1875c2c207ca13910843275289b32', 'AA99061', 'false', '{"socket_receive":1542356795801,"assistant_call":1542356795802,"assistant_return":1542356796686,"mysql_call":1542356796686,"mysql_return":1542356796696,"socket_broadcast":1542356796697,"before_db_log":1542356796703}'),
('4fe273b7-e71b-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-13 16:08:39.787', '[{"intent":"不想上班","confidence":1}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542096519788,"assistant_call":1542096519788,"assistant_return":1542096520774,"mysql_call":1542096520774,"mysql_return":1542096520784,"socket_broadcast":1542096520784,"before_db_log":1542096520784}'),
('50228ff8-db21-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:21:23.725', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540779682378,"assistant_call":1540779682379,"assistant_return":1540779683108,"mysql_call":1540779683109,"mysql_return":1540779683110,"socket_broadcast":1540779683110,"before_db_log":1540779683112}'),
('52dbb698-e7f4-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/55286fb0-e7f4-11e8-b4f4-d9bb02ebab8e.jpg', '2018-11-14 18:02:02.213', '[]', '塑料袋，袋，alizine紅色，人', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542189722213,"visualrecog_call":1542189722215,"visualrecog_return":1542189725257,"assistant_call":1542189726059,"assistant_return":1542189726676,"mysql_call":1542189726676,"mysql_return":1542189726681,"socket_broadcast":1542189726681,"before_db_log":1542189726682}'),
('53bffa35-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:35:43.800', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780543800,"assistant_call":1540780543805,"assistant_return":1540780549427,"mysql_call":1540780549427,"mysql_return":1540780549429,"socket_broadcast":1540780549429,"before_db_log":1540780548334}'),
('541d3325-db23-11e8-bda8-005056af8f8b', 'text', '我想', '2018-10-29 10:35:43.800', '[{"intent":"吃飯","confidence":0.4402834177017212}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780543800,"assistant_call":1540780542682,"assistant_return":1540780548931,"mysql_call":1540780548932,"mysql_return":1540780548938,"socket_broadcast":1540780548938,"before_db_log":1540780548944}'),
('5b669538-e71b-11e8-bda8-005056af8f8b', 'text', 'default不想上班', '2018-11-13 16:09:00.101', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542096540101,"socket_broadcast":1542096540101,"before_db_log":1542096540102}'),
('5c622c3b-dbf0-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/5eca2460-dbf0-11e8-8abf-998b58806d86.png', '2018-10-30 11:03:26.419', '[]', '黑顏色，人物，黑色，動物，家畜，狗，獵狗，西高地白梗犬，人', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540868606422,"visualrecog_call":1540868606430,"visualrecog_return":1540868608440,"assistant_call":1540868609138,"assistant_return":1540868609829,"mysql_call":1540868609830,"mysql_return":1540868609833,"socket_broadcast":1540868609833,"before_db_log":1540868609837}'),
('5df8ad3d-e719-11e8-bda8-005056af8f8b', 'text', '不爽', '2018-11-13 15:54:44.100', '[{"intent":"生氣","confidence":0.31897658824365177}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542095684101,"assistant_call":1542095684102,"assistant_return":1542095684904,"mysql_call":1542095684904,"mysql_return":1542095684908,"socket_broadcast":1542095685410,"before_db_log":1542095685411}'),
('66f60fdb-e885-11e8-bda8-005056af8f8b', 'text', '為您預約維修: \n日期:\n時段:\n服務廠:C-54', '2018-11-15 11:20:38.805', '', '', 'service', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', NULL, '{"socket_receive":1542252038807,"socket_broadcast":1542252038807,"before_db_log":1542252038808}'),
('6dbb34c8-e71b-11e8-bda8-005056af8f8b', 'text', 'zzz', '2018-11-13 16:09:29.979', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542096569980,"assistant_call":1542096569981,"assistant_return":1542096570848,"mysql_call":1542096570848,"mysql_return":1542096570856,"socket_broadcast":1542096570857,"before_db_log":1542096570859}'),
('6de28d9a-e979-11e8-bda8-005056af8f8b', 'text', '00', '2018-11-16 16:27:26.776', '[]', '', 'client', '7aa1875c2c207ca13910843275289b32', 'AA99061', 'false', '{"socket_receive":1542356846777,"assistant_call":1542356846778,"assistant_return":1542356847882,"mysql_call":1542356847883,"mysql_return":1542356847897,"socket_broadcast":1542356847897,"before_db_log":1542356847904}'),
('6ec5bf26-db53-11e8-bda8-005056af8f8b', 'text', '吃什麼', '2018-10-29 16:20:09.430', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540801209431,"socket_broadcast":1540801209437,"before_db_log":1540801209441}'),
('6ff4645c-e7f0-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/73f714e0-e7f0-11e8-8a54-fddb8abe0de4.jpg', '2018-11-14 17:34:15.900', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542188055927,"visualrecog_call":1542188055934,"visualrecog_return":1542188056077,"assistant_call":1542188056728,"assistant_return":1542188057492,"mysql_call":1542188057492,"mysql_return":1542188057519,"socket_broadcast":1542188057519,"before_db_log":1542188057521}'),
('7259be84-e7f2-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-14 17:48:40.527', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542188920529,"socket_broadcast":1542188920530,"before_db_log":1542188920531}'),
('75aa6491-db22-11e8-bda8-005056af8f8b', 'text', 'zzzz', '2018-10-29 10:29:34.840', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780174842,"assistant_call":1540780174850,"assistant_return":1540780175726,"mysql_call":1540780175726,"mysql_return":1540780175731,"socket_broadcast":1540780175731,"before_db_log":1540780175739}'),
('75c5ef14-e71b-11e8-bda8-005056af8f8b', 'text', '12314143124', '2018-11-13 16:09:43.636', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542096583637,"assistant_call":1542096583638,"assistant_return":1542096584326,"mysql_call":1542096584326,"mysql_return":1542096584332,"socket_broadcast":1542096584332,"before_db_log":1542096584332}'),
('76768bfb-e7f2-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-14 17:48:45.938', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542188925939,"assistant_call":1542188925940,"assistant_return":1542188927419,"mysql_call":1542188927419,"mysql_return":1542188927427,"socket_broadcast":1542188927427,"before_db_log":1542188927435}'),
('7d619cd9-e7f2-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-14 17:48:59.029', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542188939031,"socket_broadcast":1542188939032,"before_db_log":1542188939033}'),
('84fce9cb-e884-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-15 11:14:17.780', '[{"intent":"不想上班","confidence":1}]', '', 'client', '0f5ed5753fb59566648e88cb7ea34fe2', 'AA99061', NULL, '{"socket_receive":1542251657782,"assistant_call":1542251657783,"assistant_return":1542251659716,"mysql_call":1542251659716,"mysql_return":1542251659721,"socket_broadcast":1542251659721,"before_db_log":1542251659725}'),
('8c32d107-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:37:23.438', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780643439,"assistant_call":1540780643444,"assistant_return":1540780644099,"mysql_call":1540780644099,"mysql_return":1540780644100,"socket_broadcast":1540780644101,"before_db_log":1540780643039}'),
('8c3af26e-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:37:23.438', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780643439,"assistant_call":1540780642320,"assistant_return":1540780643041,"mysql_call":1540780643041,"mysql_return":1540780643086,"socket_broadcast":1540780643086,"before_db_log":1540780643093}'),
('91748f41-e885-11e8-bda8-005056af8f8b', 'text', '<p>親愛的車主，您好！</p>', '2018-11-15 11:21:50.018', '', '', 'service', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', NULL, '{"socket_receive":1542252110026,"socket_broadcast":1542252110029,"before_db_log":1542252110032}'),
('91be726b-e885-11e8-bda8-005056af8f8b', 'text', '<p>親愛的車主，您好！</p>', '2018-11-15 11:21:50.026', '', '', 'service', 'AA99061', '7aa1875c2c207ca13910843275289b32', NULL, '{"socket_receive":1542252110074,"socket_broadcast":1542252110577,"before_db_log":1542252110580}'),
('92170812-db52-11e8-bda8-005056af8f8b', 'text', '???', '2018-10-29 16:13:57.570', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540800837571,"assistant_call":1540800837577,"assistant_return":1540800839187,"mysql_call":1540800839188,"mysql_return":1540800839192,"socket_broadcast":1540800839192,"before_db_log":1540800839197}'),
('96065af5-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:37:39.960', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780659960,"assistant_call":1540780659970,"assistant_return":1540780660638,"mysql_call":1540780660638,"mysql_return":1540780660639,"socket_broadcast":1540780660640,"before_db_log":1540780659524}'),
('960e5151-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:37:39.960', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780659960,"assistant_call":1540780658806,"assistant_return":1540780659528,"mysql_call":1540780659528,"mysql_return":1540780659570,"socket_broadcast":1540780659570,"before_db_log":1540780659575}'),
('9c7c4561-e884-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-15 11:14:58.235', '[{"intent":"不想上班","confidence":1}]', '', 'client', '0f5ed5753fb59566648e88cb7ea34fe2', 'AA99061', NULL, '{"socket_receive":1542251698235,"assistant_call":1542251698235,"assistant_return":1542251699137,"mysql_call":1542251699137,"mysql_return":1542251699146,"socket_broadcast":1542251699146,"before_db_log":1542251699149}'),
('9f152a41-e884-11e8-bda8-005056af8f8b', 'text', 'default不想上班', '2018-11-15 11:15:03.504', '', '', 'service', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', NULL, '{"socket_receive":1542251703505,"socket_broadcast":1542251703506,"before_db_log":1542251703506}'),
('a14c0f78-db1f-11e8-bda8-005056af8f8b', 'text', '123', '2018-10-29 10:09:19.596', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540778959596,"assistant_call":1540778959602,"assistant_return":1540778960441,"mysql_call":1540778960441,"mysql_return":1540778960446,"socket_broadcast":1540778960446,"before_db_log":1540778960453}'),
('a45e6593-db53-11e8-bda8-005056af8f8b', 'text', '.', '2018-10-29 16:21:38.478', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540801298480,"assistant_call":1540801298484,"assistant_return":1540801299354,"mysql_call":1540801299354,"mysql_return":1540801299357,"socket_broadcast":1540801299357,"before_db_log":1540801299361}'),
('aa87a98e-e723-11e8-bda8-005056af8f8b', 'text', '123123123123123123123', '2018-11-13 17:08:28.826', '', '', 'service', 'AA94453', 'C0003', NULL, '{"socket_receive":1542100108827,"socket_broadcast":1542100108828,"before_db_log":1542100108828}'),
('acd53c11-db1f-11e8-bda8-005056af8f8b', 'text', '123123', '2018-10-29 10:09:38.741', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540778978743,"assistant_call":1540778978752,"assistant_return":1540778979795,"mysql_call":1540778979795,"mysql_return":1540778979799,"socket_broadcast":1540778979799,"before_db_log":1540778979806}'),
('b31b3a04-e970-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-16 15:24:57.803', '[]', '', 'client', '7aa1875c2c207ca13910843275289b32', 'AA99061', 'false', '{"socket_receive":1542353097804,"assistant_call":1542353097805,"assistant_return":1542353098566,"mysql_call":1542353098566,"mysql_return":1542353098571,"socket_broadcast":1542353098571,"before_db_log":1542353098572}'),
('b98f41e3-e7f0-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/bd6face0-e7f0-11e8-8bdb-4377b4610789.jpg', '2018-11-14 17:36:19.186', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542188179190,"visualrecog_call":1542188179192,"visualrecog_return":1542188179238,"assistant_call":1542188179959,"assistant_return":1542188180998,"mysql_call":1542188180998,"mysql_return":1542188181012,"socket_broadcast":1542188181012,"before_db_log":1542188181013}'),
('bb9ecc66-db22-11e8-bda8-005056af8f8b', 'text', '//', '2018-10-29 10:31:26.113', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780286116,"assistant_call":1540780286128,"assistant_return":1540780293090,"mysql_call":1540780293090,"mysql_return":1540780293095,"socket_broadcast":1540780293095,"before_db_log":1540780293103}'),
('bc022e09-db22-11e8-bda8-005056af8f8b', 'text', '...', '2018-10-29 10:31:32.861', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780292865,"assistant_call":1540780292873,"assistant_return":1540780293741,"mysql_call":1540780293742,"mysql_return":1540780293746,"socket_broadcast":1540780293746,"before_db_log":1540780293754}'),
('cc5e6425-db1b-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/cd1d75a0-db1b-11e8-a0a5-eb5ddb67e2b9.jpg', '2018-10-29 09:41:48.724', '[]', '塑料袋，袋，alizine紅色，人', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540777308727,"visualrecog_call":1540777308732,"visualrecog_return":1540777312218,"assistant_call":1540777313505,"assistant_return":1540777314711,"mysql_call":1540777314712,"mysql_return":1540777314718,"socket_broadcast":1540777314718,"before_db_log":1540777314730}'),
('ccc60689-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:11.813', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780751814,"assistant_call":1540780751820,"assistant_return":1540780752404,"mysql_call":1540780752404,"mysql_return":1540780752405,"socket_broadcast":1540780752406,"before_db_log":1540780751378}'),
('cccdff53-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:11.813', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780751814,"assistant_call":1540780750661,"assistant_return":1540780751381,"mysql_call":1540780751381,"mysql_return":1540780751425,"socket_broadcast":1540780751425,"before_db_log":1540780751430}'),
('d0319db5-db23-11e8-bda8-005056af8f8b', 'text', '東西', '2018-10-29 10:39:17.443', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780757443,"assistant_call":1540780757449,"assistant_return":1540780758227,"mysql_call":1540780758228,"mysql_return":1540780758229,"socket_broadcast":1540780758229,"before_db_log":1540780757116}'),
('d0392adc-db23-11e8-bda8-005056af8f8b', 'text', '東西', '2018-10-29 10:39:17.443', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780757443,"assistant_call":1540780756293,"assistant_return":1540780757118,"mysql_call":1540780757119,"mysql_return":1540780757159,"socket_broadcast":1540780757159,"before_db_log":1540780757165}'),
('d311d238-db3e-11e8-bda8-005056af8f8b', 'text', '123', '2018-10-29 13:52:38.337', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540792358337,"socket_broadcast":1540792358342,"before_db_log":1540792358348}'),
('d3ea530d-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:23.667', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780763668,"assistant_call":1540780763678,"assistant_return":1540780764281,"mysql_call":1540780764281,"mysql_return":1540780764282,"socket_broadcast":1540780764283,"before_db_log":1540780763359}'),
('d3f3515c-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:23.667', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780763668,"assistant_call":1540780762745,"assistant_return":1540780763372,"mysql_call":1540780763373,"mysql_return":1540780763407,"socket_broadcast":1540780763407,"before_db_log":1540780763415}'),
('d474ace7-e96e-11e8-bda8-005056af8f8b', 'text', '<p>親愛的車主，您好！</p>', '2018-11-16 15:11:35.003', '', '', 'service', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', 'true', '{"socket_receive":1542352295010,"socket_broadcast":1542352295512,"before_db_log":1542352295513}'),
('d4934c92-e884-11e8-bda8-005056af8f8b', 'image', 'http://localhost:8080/images/uploaded/d73baea0-e884-11e8-baa3-097d06e46308.jpg', '2018-11-15 11:16:28.023', '[]', '塑料袋，袋，alizine紅色，人', 'client', '0f5ed5753fb59566648e88cb7ea34fe2', 'AA99061', NULL, '{"socket_receive":1542251788025,"visualrecog_call":1542251788027,"visualrecog_return":1542251791613,"assistant_call":1542251792323,"assistant_return":1542251793245,"mysql_call":1542251793245,"mysql_return":1542251793251,"socket_broadcast":1542251793251,"before_db_log":1542251793253}'),
('d55cb035-dbe8-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/d6f5f8e0-dbe8-11e8-8f7a-d3d8c4927f81.png', '2018-10-30 10:09:32.049', '[]', '黑顏色，人物，黑色，動物，家畜，狗，獵狗，西高地白梗犬，人', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540865372053,"visualrecog_call":1540865372058,"visualrecog_return":1540865374640,"assistant_call":1540865376083,"assistant_return":1540865376832,"mysql_call":1540865376833,"mysql_return":1540865376836,"socket_broadcast":1540865376836,"before_db_log":1540865376844}'),
('d8881bb8-db3e-11e8-bda8-005056af8f8b', 'text', '243', '2018-10-29 13:52:46.387', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540792366388,"assistant_call":1540792366393,"assistant_return":1540792367493,"mysql_call":1540792367493,"mysql_return":1540792367504,"socket_broadcast":1540792367504,"before_db_log":1540792367512}'),
('ddaa9624-db1b-11e8-bda8-005056af8f8b', 'text', '抱歉 我聽不懂?', '2018-10-29 09:42:23.724', '', '', 'service', 'SE0001', 'C0003', NULL, '{"socket_receive":1540777343728,"socket_broadcast":1540777343739,"before_db_log":1540777343751}'),
('df1623e0-e8c6-11e8-bda8-005056af8f8b', 'text', '00', '2018-11-15 19:09:16.622', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542280156623,"assistant_call":1542280156625,"assistant_return":1542280157409,"mysql_call":1542280157409,"mysql_return":1542280157413,"socket_broadcast":1542280157413,"before_db_log":1542280157414}'),
('e51110a1-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:52.456', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780792457,"assistant_call":1540780792460,"assistant_return":1540780793136,"mysql_call":1540780793136,"mysql_return":1540780793137,"socket_broadcast":1540780793137,"before_db_log":1540780792134}'),
('e5195946-db23-11e8-bda8-005056af8f8b', 'text', '我想吃', '2018-10-29 10:39:52.456', '[{"intent":"吃飯","confidence":0.6755804538726806}]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540780792457,"assistant_call":1540780791418,"assistant_return":1540780792169,"mysql_call":1540780792169,"mysql_return":1540780792181,"socket_broadcast":1540780792182,"before_db_log":1540780792189}'),
('e583f25c-e971-11e8-bda8-005056af8f8b', 'text', '123', '2018-11-16 15:33:31.883', '[]', '', 'client', '7aa1875c2c207ca13910843275289b32', 'AA99061', 'false', '{"socket_receive":1542353611887,"assistant_call":1542353611888,"assistant_return":1542353612636,"mysql_call":1542353612636,"mysql_return":1542353612640,"socket_broadcast":1542353612641,"before_db_log":1542353612642}'),
('eca2bdc3-e96c-11e8-bda8-005056af8f8b', 'text', '<p>親愛的車主，您好！</p>', '2018-11-16 14:57:56.601', '', '', 'service', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', NULL, '{"socket_receive":1542351476603,"socket_broadcast":1542351477106,"before_db_log":1542351477107}'),
('eefa3f76-db1b-11e8-bda8-005056af8f8b', 'image', 'http://localhost:3000/images/uploaded/f01ad390-db1b-11e8-8e85-d7dba9937a16.jpg', '2018-10-29 09:42:47.389', '[]', '黑色，煤黑色，樂器，弦樂器', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540777367390,"visualrecog_call":1540777367398,"visualrecog_return":1540777370625,"assistant_call":1540777371850,"assistant_return":1540777372775,"mysql_call":1540777372776,"mysql_return":1540777372781,"socket_broadcast":1540777372781,"before_db_log":1540777372794}'),
('f33f41f9-db49-11e8-bda8-005056af8f8b', 'text', '123132', '2018-10-29 15:12:15.307', '[]', '', 'client', '102535c1-7253-41cc-87aa-7cb927681807', '71daf8cd-c00e-4797-9fb5-6b62fd88aa96', NULL, '{"socket_receive":1540797135309,"assistant_call":1540797135317,"assistant_return":1540797136723,"mysql_call":1540797136724,"mysql_return":1540797136728,"socket_broadcast":1540797136728,"before_db_log":1540797136734}'),
('f4a43bcc-e7f6-11e8-bda8-005056af8f8b', 'text', '123123123', '2018-11-14 18:20:56.067', '[]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542190856068,"assistant_call":1542190856069,"assistant_return":1542190857106,"mysql_call":1542190857106,"mysql_return":1542190857111,"socket_broadcast":1542190857111,"before_db_log":1542190857112}'),
('f8e6f76f-e718-11e8-bda8-005056af8f8b', 'text', '不爽', '2018-11-13 15:51:54.550', '[{"intent":"生氣","confidence":0.31897658824365177}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542095514553,"assistant_call":1542095514553,"assistant_return":1542095515334,"mysql_call":1542095515334,"mysql_return":1542095515339,"socket_broadcast":1542095515841,"before_db_log":1542095515843}'),
('f935b272-db20-11e8-bda8-005056af8f8b', 'text', '123', '2018-10-29 10:18:57.745', '[]', '', 'client', 'C0003', 'SE0001', NULL, '{"socket_receive":1540779536397,"assistant_call":1540779536398,"assistant_return":1540779537272,"mysql_call":1540779537272,"mysql_return":1540779537273,"socket_broadcast":1540779537273,"before_db_log":1540779537275}'),
('fb245967-e72d-11e8-bda8-005056af8f8b', 'text', '不想上班', '2018-11-13 18:22:18.261', '[{"intent":"不想上班","confidence":1}]', '', 'client', 'C0003', 'AA94453', NULL, '{"socket_receive":1542104538275,"assistant_call":1542104538276,"assistant_return":1542104539025,"mysql_call":1542104539025,"mysql_return":1542104539038,"socket_broadcast":1542104539038,"before_db_log":1542104539039}');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_responsibility`
--

CREATE TABLE IF NOT EXISTS `tb_responsibility` (
  `responsibility_id` char(40) NOT NULL,
  `manager_id` char(40) DEFAULT NULL,
  `customer_id` char(40) DEFAULT NULL,
  `conversation_title` varchar(60) DEFAULT NULL COMMENT '避免為了名字而每次join',
  `customer_nickname` varchar(60) NOT NULL,
  `avator` varchar(200) DEFAULT NULL,
  `last_talk_time` datetime DEFAULT NULL,
  `last_message` varchar(200) DEFAULT NULL,
  `manager_unread` int(11) DEFAULT NULL,
  `customer_unread` int(11) NOT NULL,
  `notify_data` varchar(200) DEFAULT NULL,
  `memo` varchar(200) DEFAULT '',
  PRIMARY KEY (`responsibility_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 資料表的匯出資料 `tb_responsibility`
--

INSERT INTO `tb_responsibility` (`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `customer_nickname`, `avator`, `last_talk_time`, `last_message`, `manager_unread`, `customer_unread`, `notify_data`, `memo`) VALUES
('9a36f401-db48-11e8-bda8-005056af8f8b', '7615de18-69e6-4c28-be61-a87a0b41ab05', '247fb5d1-af16-4e7d-85cf-4654ffd05958', NULL, '', NULL, '2018-10-29 15:02:30', '', 0, 0, NULL, ''),
('a03fc58e-e871-11e8-bda8-005056af8f8b', 'AA99061', '0f5ed5753fb59566648e88cb7ea34fe2', 'IS300h/RBD-0021', '踢哪??', 'http://dl.profile.line-cdn.net/0m02adf41c7251251f5ccef2a4b5ba67a996a6138bc8fb', '2018-11-16 15:11:35', '<p>親愛的車主，您好！</p>', 0, 4, '{}', ''),
('a0454590-e871-11e8-bda8-005056af8f8b', 'AA99061', '7aa1875c2c207ca13910843275289b32', 'IS300h/RBD-0021', '威宇', 'https://profile.line-scdn.net/0hT_QnekaKC3BsFyai_Mh0J1BSBR0bOQ04FCIRFh4SAkkRdU0jUXQWQUAUUUhCd0p1VXMWEkkQBhUS', '2018-11-16 16:27:27', '00', 5, 0, '{}', ''),
('b3da940c-e6e8-11e8-bda8-005056af8f8b', 'AA94453', 'C0001', 'IS300h/RBD-0021', '測試使用者1', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQIGa49DabvTpQldi1JH7KHt2TeGFmn_3g4U2jAegFdvRLFunkYQg', '2018-11-13 10:06:15', '', 0, 0, '{}', ''),
('b3e00a03-e6e8-11e8-bda8-005056af8f8b', 'AA94453', 'C0002', 'IS300h/RBD-0022', '測試使用者2', 'https://im1.book.com.tw/image/getImage?i=https://www.books.com.tw/img/001/079/99/0010799970.jpg&v=5ba225b9&w=348&h=348', '2018-11-13 10:06:15', '', 0, 0, '{}', ''),
('b3e52c14-e6e8-11e8-bda8-005056af8f8b', 'AA94453', 'C0003', 'IS300h/NUM-042', '測試使用者3', 'https://ai-catcher.com/wp-content/uploads/icon_74.png', '2018-11-15 19:09:17', '00', 5, 0, '{}', ''),
('cc78c0db-db1e-11e8-bda8-005056af8f8b', 'c352025d-92bc-4e7a-b7bf-b102086edd8b', 'da6bc242-ceba-451b-ac98-3b9ff67ae332', NULL, '', NULL, '2018-10-29 10:03:16', '', 0, 0, NULL, ''),
('d10b8fd8-d902-11e8-bda8-005056af8f8b', 'SE0001', 'C0003', 'CT201H/ABZ-1235/陳一為', '', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-30 11:03:26', 'http://localhost:3000/images/uploaded/5eca2460-dbf0-11e8-8abf-998b58806d86.png', 5, 0, NULL, ''),
('d10e5e1f-d902-11e8-bda8-005056af8f8b', 'SE0001', 'C0001', 'CT200H/ABZ-1234/王一明', '', 'https://customer-service-xiang.herokuapp.com/images/avatar.png', '2018-10-26 17:37:55', '', 0, 0, NULL, ''),
('e7819bbd-db5b-11e8-bda8-005056af8f8b', '577dc08b-b869-4d16-b5f0-f2a187549a50', 'b958100f-85cd-4182-ac10-fbd86f95d294', NULL, '', NULL, '2018-10-29 17:20:40', '', 0, 0, NULL, ''),
('f0456920-db49-11e8-bda8-005056af8f8b', '71daf8cd-c00e-4797-9fb5-6b62fd88aa96', '102535c1-7253-41cc-87aa-7cb927681807', NULL, '', NULL, '2018-10-29 15:12:15', '123132', 1, 0, NULL, '');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_talk_tricks`
--

CREATE TABLE IF NOT EXISTS `tb_talk_tricks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(10) DEFAULT NULL,
  `manager_id` varchar(50) DEFAULT NULL,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL COMMENT '預期是jsonarray',
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=16 ;

--
-- 資料表的匯出資料 `tb_talk_tricks`
--

INSERT INTO `tb_talk_tricks` (`id`, `type`, `manager_id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
(1, 'dialog', 'SE0001', 'D0003', '["吃什麼","餓了嗎?","再等等吧"]', '吃飯'),
(2, 'dialog', 'SE0001', 'D0004', '["不要同情我!!","妳個混帳","我也是笑笑"]', '同情'),
(3, 'dialog', 'SE0001', 'D0005', '["我們有提供OO","我們有提供那個","我們有提供這個"]', '尋求資訊'),
(4, 'dialog', 'SE0001', 'D0001', '["有什麼需要我幫忙的嗎","hi","哈囉"]', '歡迎'),
(5, 'dialog', 'SE0001', 'D0002', '["去上吧 可憐的孩子","拍拍","不想上班就別上了"]', '不想上班'),
(6, 'dialog', 'SE0001', 'D0006', '["有什麼需要我幫忙的嗎","hi","哈囉"]', '打招呼'),
(7, 'dialog', 'SE0001', 'D0007', '["息怒","妳個混帳","我也是笑笑"]', '生氣'),
(8, 'dialog', 'SE0001', 'D0008', '["抱歉 我聽不懂?","有別的說法嗎","我不懂你的意思"]', 'anything_else'),
(12, 'dialog', 'AA94453', 'D0002', '["default不想上班","default不想上班","default不想上班","超級不想上班"]', NULL),
(14, 'dialog', 'AA94453', 'Normal', '["普通話術1","普通話術2","生日快樂1","生日快樂2","續保話術1","該續保了2","其他1231","其他話術"]', NULL),
(15, 'dialog', 'AA99061', 'Normal', '["普通話術1","普通話術2","生日快樂1","生日快樂2","續保話術1","該續保了2","123214124","其他話術"]', NULL);

-- --------------------------------------------------------

--
-- 資料表結構 `tb_talk_tricks_default`
--

CREATE TABLE IF NOT EXISTS `tb_talk_tricks_default` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dialog_id` varchar(20) DEFAULT NULL,
  `talk_tricks` varchar(2000) DEFAULT NULL,
  `memo` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=14 ;

--
-- 資料表的匯出資料 `tb_talk_tricks_default`
--

INSERT INTO `tb_talk_tricks_default` (`id`, `dialog_id`, `talk_tricks`, `memo`) VALUES
(2, 'D0002', '["default不想上班","default不想上班","default不想上班"]', '不想上班'),
(3, 'D0003', '["default吃飯","default吃飯","default吃飯"]', '吃飯'),
(4, 'D0004', '["default同情","default同情","default同情"]', '同情'),
(5, 'D0005', '["default尋求資訊","default尋求資訊","default尋求資訊"]', '尋求資訊'),
(6, 'D0006', '["default打招呼","default打招呼","default打招呼"]', '打招呼'),
(7, 'D0007', '["default生氣","default生氣","default生氣"]', '生氣'),
(8, 'D0008', '["default anything_else","default anything_else","default anything_else"]', 'anything_else'),
(12, 'D0001', '["default歡迎","default歡迎","default歡迎"]', '歡迎'),
(13, 'Normal', '["普通話術1", "普通話術2", "生日快樂1", "生日快樂2", "續保話術1", "該續保了2", "其他1", "其他話術"]', '一般話術');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_uploaded_picture`
--

CREATE TABLE IF NOT EXISTS `tb_uploaded_picture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` char(40) DEFAULT NULL,
  `picture_name` varchar(100) DEFAULT NULL,
  `picture_url` varchar(200) DEFAULT NULL,
  `upload_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

--
-- 資料表的匯出資料 `tb_uploaded_picture`
--

INSERT INTO `tb_uploaded_picture` (`id`, `customer_id`, `picture_name`, `picture_url`, `upload_time`) VALUES
(1, '3a432ccc-245c-4364-9366-e8b52536fe35', 'tire_press.png', 'http://localhost:3000/uploaded/tire_pressure.png', '2018-10-18 12:46:09');

-- --------------------------------------------------------

--
-- 資料表結構 `x_tb_intent_response`
--

CREATE TABLE IF NOT EXISTS `x_tb_intent_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intent` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

--
-- 資料表的匯出資料 `x_tb_intent_response`
--

INSERT INTO `x_tb_intent_response` (`id`, `intent`, `response_1`, `response_2`, `response_3`) VALUES
(1, '尋求資訊', '有什麼我可以為您服務的地方呢', '我想您需要的是OOXX 請打以下電話', '請問您的車子目前的狀況是?');

-- --------------------------------------------------------

--
-- 資料表結構 `x_tb_visualrecog_response`
--

CREATE TABLE IF NOT EXISTS `x_tb_visualrecog_response` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visualrecog` varchar(50) DEFAULT NULL,
  `response_1` varchar(100) DEFAULT NULL,
  `response_2` varchar(100) DEFAULT NULL,
  `response_3` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=101 ;

--
-- 資料表的匯出資料 `x_tb_visualrecog_response`
--

INSERT INTO `x_tb_visualrecog_response` (`id`, `visualrecog`, `response_1`, `response_2`, `response_3`) VALUES
(1, '胎壓警示燈', '這是胎壓指示燈，表示胎壓偏低，建議回廠檢查', '胎壓警示燈，建議於服務廠就近檢查', NULL);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
