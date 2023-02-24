-----Create profile-----
--drop procedure CreateCustomerProfile;
create or replace procedure CreateCustomerProfile(p_com_name varchar(30), p_telephone varchar(10), p_email varchar(20), p_address varchar(50))
language plpgsql
as $$
begin
	if (p_telephone !~ '^[0-9 ]+$')
		then raise notice 'Telephone number not formated correctly';
		return;
	else
		insert into customer(company_name, telephone_number, email, address)
		values(p_com_name, p_telephone, p_email, p_address);
	end if;
end
$$;
------------------------

-----Edit profile-----
--drop procedure EditCustomerProfile;
create or replace procedure EditCustomerProfile(p_id int, p_com_name varchar(30), p_telephone varchar(10), p_email varchar(20), p_address varchar(50))
language plpgsql
as $$
begin
	if (p_telephone !~ '^[0-9 ]+$')
		then raise notice 'Telephone number not formated correctly';
		return;
	else
		update customer
		set company_name = p_com_name,
			telephone_number = p_telephone,
			email = p_email,
			address = p_address
		where customer_id = p_id;
	end if;
end
$$;
----------------------

-----Delete profile-----
create or replace procedure DeleteCustomerProfile(id int)
language plpgsql
as $$
begin
	delete from customer as c
	where c.customer_id = id;
end
$$;
------------------------

-----Filter profile-----
create or replace function FilterCustomerProfile(p_name varchar(30), p_telephone varchar(10), p_email varchar(20), p_address varchar(50))
returns table
(
	customer_id int,
	company_name varchar(50),
	telephone_number varchar(12),
	email varchar(50),
	address varchar(50)
)
language plpgsql
as $$
declare 
begin
	drop table if exists m_result;
	create temp table m_result as
	select *
	from customer;
	
	if (p_name is not null)
	then
		delete from m_result as c
		where c.company_name <> p_name;
	end if;
	
	if (p_telephone is not null)
	then
		delete from m_result as c
		where c.telephone_number <> p_telephone;
	end if;
	
	if (p_email is not null)
	then
		delete from m_result as c
		where c.email <> p_email;
	end if;
	
	if (p_address is not null)
	then
		delete from m_result as c
		where c.address <> p_address;
	end if;
	
	return query
	select *
	from m_result;
end
$$;

------------------------
