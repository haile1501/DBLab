-------------------Create report for each location--------------------

CREATE OR REPLACE FUNCTION create_report_for_each_location (
	t_product_id int,
	t_employee_id int,
	t_location_code text,
	t_report_time date,
	t_status varchar(15),
	t_description text
)RETURNS VOID AS
$$
BEGIN
	INSERT INTO report(product_id, employee_id, location_code, report_time, status, description) VALUES (t_product_id, t_employee_id, t_location_code, t_report_time, t_status, t_description);
END;
$$
LANGUAGE plpgsql;

-------------------staff update report----------------

CREATE OR REPLACE FUNCTION staff_update_report (
	t_employee_id  int, 
	t_password text,
	t_report_id int,
	t_status varchar(15)) 
RETURNS VOID AS
$$
DECLARE t_manager_id int;
BEGIN
	SELECT manager_id INTO t_manager_id
	FROM employee
	WHERE employee_id = t_employee_id AND password = t_password;
	
	IF manager_id IS NULL THEN
		RAISE EXCEPTION 'Invalid employee_id or password';
	END IF;
	
	UPDATE report 
	SET status = t_status
	WHERE report_id = t_report_id;
	
	RAISE NOTICE 'Report % updated by employee %',t_report_id, t_employee_id;
END;
$$
LANGUAGE plpgsql;

------------------delete report-----------------

CREATE OR REPLACE FUNCTION delete_report (t_report_id int )
RETURNS VOID AS 
$$
BEGIN 
	DELETE FROM report WHERE report_id = t_report_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_report(
	t_status varchar(15), 
	t_location_code varchar(15),
	t_product_id int
)
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
)
AS $$
BEGIN 
	DROP TABLE IF EXISTS r_result;
	create temp TABLE r_result as
	SELECT *
	FROM REPORT;
	
	if(t_status is not null )
	then
		DELETE FROM r_result as c
		where c.status <> t_status;
	end if;
	
	if(t_location_code is not null)
	then
		delete from r_result as c
		where c.location_code <> t_location_code;
	end if;
	
	if(t_product_id is not null)
	then 
		delete from r_result as c
		where c.product_id <> t_product_id;
	end if;
	
	return query
	select *
	from r_result;
end;
$$

language plpgsql;