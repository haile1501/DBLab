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

------------------filter by status--------------

CREATE OR REPLACE FUNCTION filter_by_status (t_status varchar(15))
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
) AS $$
BEGIN 
	RETURN QUERY SELECT report_id, product_id, employee_id, location_code, report_time, status, description
	FROM report
	WHERE status = t_status;
END;
$$
LANGUAGE plpgsql;

------------------sort by report time-------------

CREATE OR REPLACE FUNCTION sort_by_report_time ()
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
) AS $$
BEGIN 
	RETURN QUERY SELECT report_id, product_id, employee_id, location_code, report_time, status, description
	FROM report
	ORDER BY report_time;
END;
$$
LANGUAGE plpgsql;

------------------search by customer-------------


CREATE OR REPLACE FUNCTION search_report_by_customer (t_customer_id int)
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
) AS $$
BEGIN 
	RETURN QUERY SELECT report_id, product_id, employee_id, location_code, report_time, status, description
	FROM report r
	LEFT JOIN product p ON r.product_id = p.product_id
	LEFT JOIN reservation re ON p.customer_id = re.customer_id 
	WHERE re.customer_id = t_customer_id;
END;
$$
LANGUAGE plpgsql;

----------------------search by location --------------
CREATE INDEX idx_location_code ON report (location_code);

CREATE OR REPLACE FUNCTION search_by_location_code (t_location_code text)
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
) AS $$
BEGIN 
	RETURN QUERY SELECT report_id, product_id, employee_id, location_code, report_time, status, description
	FROM report
	WHERE location_code = t_location_code;
END;
$$
LANGUAGE plpgsql;

--------------------search by product------------------
CREATE INDEX idx_product_id ON report (product_id);

CREATE OR REPLACE FUNCTION search_report_list_by_product(t_product_id int)
RETURNS TABLE (
	report_id int,
	product_id int,
	employee_id int,
	location_code text,
	report_time date,
	status varchar(15),
	description text
) AS $$
BEGIN 
	RETURN QUERY SELECT report_id, product_id, employee_id, location_code, report_time, status, description
	FROM report
	WHERE product_id = t_product_id;
END;
$$
LANGUAGE plpgsql;

