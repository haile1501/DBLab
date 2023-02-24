/*
ex: parent_location = 'A'
	sub_layout = [{"location_code": "A1", "capacity": 1000}, {"location_code": "A2", "capacity": 1000}]
*/

/* Create layout */

create or replace function create_layout(parent_location text, layout json)
returns void
language plpgsql
as
$$
declare
	i json;
begin
	for i in select * from json_array_elements(layout)
	loop
		insert into wh_location(location_code, parent_location, capacity, available_space)
		values(i->>'location_code', parent_location, cast(i->>'capacity' as decimal), cast(i->>'capacity' as decimal));
	end loop;
end $$;

/* Detail information about location */
/* code: pattern like 'a%'*/
create or replace function get_location_by_code(code text)
returns table (
	product_id int,
	spacee decimal,
	product_name varchar(50),
	company_name varchar(50),
	cartons_num int
)
language plpgsql
as
$$
begin
	return query select 
		p.product_id, 
		lp.spacee, 
		p.product_name,
		c.company_name,
		cast((lp.spacee/p.space_per_carton) as int) as cartons_num
	from location_product lp, product p, customer c
	where location_code like code
	and lp.product_id = p.product_id
	and p.customer_id = c.customer_id;
end
$$;

/* Retrieve all location of a product */

create or replace function get_all_locations_of_product(id int)
returns table(
	location_code text,
	spacee decimal,
	cartons_num int
)
language plpgsql
as
$$
begin
	return query select
		lp.location_code,
		lp.spacee,
		cast((lp.spacee/p.space_per_carton) as int) as cartons_num
	from location_product lp, product p
	where lp.product_id = p.product_id
	and p.product_id = id;
end
$$;

/* Get available space */

create or replace function get_available_space()
returns decimal
language plpgsql
as
$$
declare
	available decimal;
begin
    select into available sum(available_space)
    from wh_location
    where parent_location = null;
	return available;
end
$$;

----- trigger to restore space when deleting location_product
create or replace function delete_update_location_product_trigger()
returns trigger
language plpgsql
as $$
begin
	if (TG_OP = 'DELETE') then
		update wh_location l
		set available_space = available_space + old.spacee
		where l.location_code = old.location_code;
	else
		update wh_location l
		set available_space = available_space + old.spacee - new.spacee
		where l.location_code = old.location_code;
	end if;
	return null;
end
$$;

CREATE OR REPLACE TRIGGER delete_update_location_product AFTER UPDATE OR DELETE ON location_product
FOR EACH ROW
EXECUTE FUNCTION delete_update_location_product_trigger();