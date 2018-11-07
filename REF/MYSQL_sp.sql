DELIMITER $$
DROP PROCEDURE IF EXISTS sp_send_message $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_send_message`(
	IN p_message_type VARCHAR(20) , 
	IN p_content VARCHAR(2000) , 
	IN p_intent_str VARCHAR(2000) ,
	IN p_recognition_result VARCHAR(2000) ,
	IN p_time VARCHAR(20) ,
	IN p_direction VARCHAR(20) ,
	IN p_from_id VARCHAR(50) ,
	IN p_to_id VARCHAR(50) 
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
	
END $$

-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_select_manager_list $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_manager_list`(
	IN p_manager_id VARCHAR(50)
)
BEGIN
	/* 20181022 By Ben */
	/* call sp_select_manager_list("SE0001"); */
	
	SELECT customer_id, conversation_title, avator, last_talk_time, last_message, unread, note
	from tb_responsibility WHERE manager_id = p_manager_id ORDER BY last_talk_time DESC;
	
END $$

-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_bind_client $$
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
		(`responsibility_id`, `manager_id`, `customer_id`, `conversation_title`, `avator`, `last_talk_time`, `last_message`, `unread`)
		VALUES
		(UUID(), p_manager_id, p_customer_id, p_conversation_title, p_conversation_avator,  NOW(), '', 0 );
	END IF;
	
END $$

-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_select_talk_history $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_talk_history`(
	IN p_endpoint VARCHAR(50),
	IN p_manager_id VARCHAR(50),
	IN p_customer_id VARCHAR(50),
	IN p_skip int,
	IN p_limit int
)
BEGIN
	/* 20181024 By Ben */
	/* call sp_select_talk_history("client","SE0001","C0003",null,null); */
	DECLARE p_skip_exec int default 0;
	DECLARE p_limit_exec int default 3;
	
	IF p_skip IS NOT NULL THEN	
		SET p_skip_exec = p_skip;
	END IF;
	IF p_limit IS NOT NULL THEN	
		SET p_limit_exec = p_limit;
	END IF;
	
	IF p_endpoint = "service" AND p_skip IS NULL AND p_limit IS NULL THEN
		SET p_limit_exec = (SELECT unread FROM tb_responsibility WHERE manager_id = p_manager_id AND customer_id = p_customer_id LIMIT 0,1)+1;
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
	
END $$

-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_select_talk_tricks $$
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
	
END $$


-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_update_talk_tricks $$
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
	
END $$


-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_update_manager $$
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
	
END $$

-- ###################################### --
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_select_conversation_info $$
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
	
END $$