--------Search by customer_name---------

CREATE INDEX idx_company_name ON customer (company_name);


CREATE OR REPLACE FUNCTION get_reservation_by_customer_name (t_company_name varchar(50))
RETURNS TABLE (
	reservation_id integer,
	customer_id integer,
	reservate_date date,
	expire_date date,
	deposite_deadline date,
	requested_space decimal,
	reservation_type varchar(10),
	status varchar(10)
)AS $$
BEGIN 
	RETURN QUERY SELECT reservation_id, customer_id, reservate_date, expire_date, deposite_deadline, requested_space, reservation_type, status
	FROM reservation as re
	WHERE re.customer_id = ( SELECT c.customer_id
				 FROM customer as c
				 WHERE c.company_name = t_company_name);
END;
$$
LANGUAGE plpgsql;

---------------get reservation by filter---------


CREATE OR REPLACE FUNCTION get_reservation_by_filter (t_reservate_date date, t_expire_date date, t_status varchar(15) )
RETURNS TABLE (
	reservation_id integer,
	customer_id integer,
	reservate_date date,
	expire_date date,
	deposite_deadline date,
	requested_space decimal,
	reservation_type varchar(10),
	status varchar(10)
)AS $$
BEGIN
	RETURN QUERY SELECT reservation_id, customer_id, reservate_date, expire_date, deposite_deadline, requested_space, reservation_type, status
	FROM reservation
	WHERE reservate_date = t_reservate_date OR t_reservate_date IS NULL AND expire_date = t_expire_date OR t_expire_date IS NULL AND status = t_status OR t_status IS NULL;
END;
$$
LANGUAGE plpgsql;


------------------Sort by request space=----------------

CREATE OR REPLACE FUNCTION get_reservation_by_space()
RETURNS TABLE (
	reservation_id integer,
	customer_id integer,
	reservate_date date,
	expire_date date,
	deposite_deadline date,
	requested_space decimal,
	reservation_type varchar(10),
	status varchar(10)
) AS $$
BEGIN 
	RETURN QUERY SELECT reservation_id, customer_id, reservate_date, expire_date, deposite_deadline, requested_space, reservation_type, status
	FROM reservation
	ORDER BY request_space;
END;
$$
LANGUAGE plpgsql;

-----------------Make reservation----------------

CREATE OR REPLACE FUNCTION make_reservation (
	t_customer_id int, 
	t_reservate_date date, 
	t_expire_date date, 
	t_deposit_deadline date,
	t_requested_space decimal, 
	t_reservation_type varchar(10), 
	t_status varchar(15) ) 
RETURNS VOID AS $$
BEGIN
	INSERT INTO reservation(customer_id, reservate_date, expire_date, deposite_deadline, requested_space, reservation_type, status) VALUES (t_customer_id, t_reservate_date, t_expire_date, t_deposite_deadline, t_requested_space, t_reservation_type, t_status);
END;
$$
LANGUAGE plpgsql;

-----------------Update reservation status-----------------

CREATE OR REPLACE FUNCTION update_reservation(
	new_status varchar(15), 
	p_reservation_id int )
RETURNS VOID AS $$
BEGIN
	UPDATE reservation
	SET status = new_status
	WHERE reservation_id = p_reservation_id;
END;
$$
LANGUAGE plpgsql;


------ create reservation ------
create or replace procedure create_reservation(p_customer_id int, p_expire_date date, p_deposite_deadline date, p_requested_space decimal, p_reservation_type varchar(10))
language plpgsql
as $$
begin
	insert into reservation(customer_id, reservate_date, expire_date, deposite_deadline, requested_space, reservation_type, status)
	values(p_customer_id, CURRENT_DATE, p_expire_date, p_deposite_deadline, p_requested_space, p_reservation_type, 'pending');
end
$$;