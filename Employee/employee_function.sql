-----AddEmployee-----
create or replace procedure CreateEmployee(p_manager_id int, p_employee_name varchar(30), p_address varchar(50), p_telephone varchar(10))
language plpgsql
as $$
begin
	if (p_telephone !~ '^[0-9 ]+$')
		then raise notice 'Telephone number not formated correctly';
		return;
	else
		insert into employee(manager_id, employee_name, address, telephone)
		values(p_manager_id, p_employee_name, p_address, p_telephone);
	end if;
end
$$;
---------------------

-----FindEmployee-----
create or replace function FindEmployee(p_id int, p_name varchar(30))
returns table
(
	employee_id int,
	manager_id int,
	employee_name varchar(30),
	address varchar(50),
	telephone varchar(10)
)as
$$
begin
	
	drop table if exists m_result;
	create temp table m_result as
	select *
	from employee;
	
	if (p_id is not null)
	then
		delete from m_result as c
		where c.employee_id <> p_id;
	end if;
	
	if (p_name is not null)
	then
		delete from m_result as c
		where c.employee_name <> p_name;
	end if;

	return query
	select *
	from m_result;
end;
$$

language plpgsql;
----------------------

-----EditEmployee-----
create or replace procedure EditEmployee(p_employee_id int, p_manager_id int, p_employee_name varchar(30), p_address varchar(50), p_telephone varchar(10))
language plpgsql
as $$
begin
	if (p_telephone !~ '^[0-9 ]+$')
		then raise notice 'Telephone number not formated correctly';
		return;
	else
		update employee
		set manager_id = p_manager_id, 
			employee_name = p_employee_name,
			address = p_address, 
			telephone = p_telephone
		where employee_id = p_employee_id;
	end if;
end
$$;
----------------------

-----DeleteEmployee-----
create or replace procedure DeleteEmployee(p_employee_id int)
language plpgsql
as $$
begin
	delete from employee
	where employee_id = p_employee_id;
end
$$;
----------------------

