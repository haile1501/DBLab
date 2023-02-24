----------------create operation-------------

CREATE OR REPLACE FUNCTION create_employee_operation(
	t_employee_id int,
	t_operation_id int
)
RETURNS VOID AS
$$
BEGIN
	INSERT INTO employee_operation(employee_id, operation_id) VALUES (t_employee_id, t_operation_id);
END;
$$
LANGUAGE plpgsql;

/*
	batches = [{"product_id": 1, "cartons_num": 100},
			   {"product_id": 2, "cartons_num": 50}]
*/

CREATE OR REPLACE PROCEDURE create_operation (
	t_customer_id int,
	t_scheduled_time date,
	t_operation_type varchar(15),
	t_transport_company varchar(30),
	t_telephone varchar(10),
	t_vehicle varchar(10),
	t_additional_info text, 
	t_employee_id int,
	batches json
)
AS
$$
DECLARE 
	i json;
	t_operation_id int;
BEGIN 
	INSERT INTO operation(customer_id, 
	scheduled_time, status, 
	operation_type, transport_company, telephone, 
	vehicle, additional_info) 
	VALUES (t_customer_id, t_scheduled_time, 
	'pending', t_operation_type, t_transport_company, 
	t_telephone, t_vehicle, t_additional_info)
	RETURNING operation_id INTO t_operation_id;

	PERFORM create_employee_operation(t_employee_id, t_operation_id);

	FOR i IN SELECT * FROM json_array_elements(batches)
	LOOP
		INSERT INTO batch(product_id, operation_id, cartons_num)
		VALUES (CAST(i->>'product_id' AS int), t_operation_id, CAST(i->>'cartons_num' AS int));
	END LOOP;

	COMMIT;
END;
$$
LANGUAGE plpgsql; 

/* Update 'arrived' operation status */
create or replace function arrived_operation_trigger()
returns trigger
language plpgsql
as $$
declare
	ele_batch record;
	ele_location record;
	possible_cartons int;
	remaining_cartons int;
begin
	if new.status = 'arrived' then
		if new.operation_type = 'receiving' then
			for ele_batch in select p1.product_id, b.cartons_num, p1.space_per_carton
			from batch b, product p1
			where b.operation_id = new.operation_id
			and p1.product_id = b.product_id
			loop
				update product p
				set cartons_num = cartons_num + ele_batch.cartons_num
				where p.product_id = ele_batch.product_id
				and p.customer_id = new.customer_id;

				remaining_cartons:= ele_batch.cartons_num;

				for ele_location in select available_space, location_code
				from wh_location
				where parent_location is not null
				and available_space> 0
				loop
					possible_cartons:= floor(ele_location.available_space/ele_batch.space_per_carton);
					if possible_cartons >= remaining_cartons
					then
						update wh_location l
						set available_space = available_space - remaining_cartons * ele_batch.space_per_carton
						where ele_location.location_code = l.location_code;

						if exists (select * from location_product lp
						where lp.location_code = ele_location.location_code and lp.product_id = ele_batch.product_id)
						then
							update location_product lp2
							set spacee = spacee + remaining_cartons * ele_batch.space_per_carton
							where lp2.location_code = ele_location.location_code;
						else
							insert into location_product(location_code, product_id, spacee)
							values(ele_location.location_code, ele_batch.product_id, remaining_cartons * ele_batch.space_per_carton);
						end if;

						call create_batch_location(new.operation_id, remaining_cartons, ele_location.location_code);

						exit;
					else
						update wh_location l
						set available_space = available_space - possible_cartons * ele_batch.space_per_carton
						where ele_location.location_code = l.location_code;

						if exists (select * from location_product lp
						where lp.location_code = ele_location.location_code and lp.product_id = ele_batch.product_id)
						then
							update location_product lp2
							set spacee = spacee + possible_cartons * ele_batch.space_per_carton
							where lp2.location_code = ele_location.location_code;
						else
							insert into location_product(location_code, product_id, spacee)
							values(ele_location.location_code, ele_batch.product_id, possible_cartons * ele_batch.space_per_carton);
						end if;

						call create_batch_location(new.operation_id, possible_cartons, ele_location.location_code);

						remaining_cartons:= remaining_cartons - possible_cartons;
					end if;
				end loop;
			end loop;
		else
			for ele_batch in select p1.product_id, b.cartons_num, p1.space_per_carton
			from batch b, product p1
			where b.operation_id = new.operation_id
			and p1.product_id = b.product_id
			loop
				update product p
				set cartons_num = p.cartons_num - ele_batch.cartons_num
				where p.product_id = ele_batch.product_id
				and p.customer_id = new.customer_id;

				remaining_cartons:= ele_batch.cartons_num;

				for ele_location in select spacee, location_code from location_product lp
				where lp.product_id = ele_batch.product_id
				loop
					possible_cartons:= floor(ele_location.spacee/ele_batch.space_per_carton);
					if remaining_cartons = 0
					then exit;
					end if;

					if possible_cartons <= remaining_cartons
					then
						delete from location_product lp
						where lp.product_id = ele_batch.product_id;
						remaining_cartons:= remaining_cartons - possible_cartons;

						call create_batch_location(new.operation_id, possible_cartons, ele_location.location_code);
					else
						update location_product lp
						set spacee = spacee - ele_batch.space_per_carton * remaining_cartons
						where lp.product_id = ele_batch.product_id;

						call create_batch_location(new.operation_id, remaining_cartons, ele_location.location_code);
					end if;
				end loop;
			end loop;
		end if;
	end if;

	return new;
end
$$;

DROP TRIGGER arrived_operation_update_trigger ON operation;
CREATE TRIGGER arrived_operation_update_trigger AFTER UPDATE ON operation
FOR EACH ROW
EXECUTE FUNCTION arrived_operation_trigger();

----------sort by scheduled time---------------

CREATE OR REPLACE FUNCTION sort_operation_by_scheduled_time ()
RETURNS TABLE (
	operation_id int,
	reservation_id int,
	scheduled_time date,
	arrived_time date,
	status varchar(15),
	operation_type varchar(15),
	transport_company varchar(30),
	telephone varchar(10),
	vehicle varchar(10),
	additional_info text
)AS $$
BEGIN
	RETURN QUERY SELECT operation_id, reservation_id, scheduled_time, arrived_time, status, operation_type, transport_company, telephone, vehicle, additional_info
	FROM operation
	ORDER BY scheduled_time;
END;
$$
LANGUAGE plpgsql;


----------filter by status/type-----------------

CREATE OR REPLACE FUNCTION filter_operation_by_status_type (t_status varchar(15), t_operation_type varchar(15))
RETURNS TABLE (
	operation_id int,
	reservation_id int,
	scheduled_time date,
	arrived_time date,
	status varchar(15),
	operation_type varchar(15),
	transport_company varchar(30),
	telephone varchar(10),
	vehicle varchar(10),
	additional_info text
)AS $$
BEGIN
	RETURN QUERY SELECT operation_id, reservation_id, scheduled_time, arrived_time, status, operation_type, transport_company, telephone, vehicle, additional_info
	FROM operation
	WHERE status = t_status OR status is NULL AND opertaion_type = t_operation_type OR t_operation_type IS NULL;
END;
$$
LANGUAGE plpgsql;


create or replace procedure create_batch_location(p_operation_id int, p_cartons_num int, p_location_code text)
language plpgsql
as $$
begin
	insert into batch_location(operation_id, cartons_num, location_code)
	values(p_operation_id, p_cartons_num, p_location_code);
end
$$;

