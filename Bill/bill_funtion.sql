-----CreateBill-----
create or replace procedure CreateBill(p_res_id int, p_bill_period date, p_deadline date)
language plpgsql
as $$
begin
	insert into bill(reservation_id, bill_period, status, deadline)
	values(p_res_id, p_bill_period, 'pending', p_deadline);
end
$$;
--------------------

-----UpdateBill-----
create or replace procedure UpdateBill(p_res_id int, p_bill_period date, p_status varchar(15))
language plpgsql
as $$
begin
	update bill
	set status = p_status
	where reservation_id = p_res_id and bill_period = p_bill_period;
end
$$;
-------------------

-----CreateBillFunctionTrigger-----
create or replace function CreateBill()
returns trigger
language plpgsql
as $$
declare
	m_amount int;
	flexible_price int;
	fixed_price int;
begin
	flexible_price:= 100;
	fixed_price:= 80;
	
	if (new.reservation_type = 'flexible')
	then m_amount = new.requested_space * 100;
	else
		m_amount = new.requested_space * 80 * DATE_PART('month', new.expire_date) - DATE_PART('month', new.expire_date);
	end if;
		
	insert into bill(reservation_id, bill_period, status, deadline, amount)
	values(new.reservation_id, new.reservate_date, 'pending', new.deposite_deadline, m_amount);

	return null;
end
$$;
--------------------

-----OnReservationCreated-----
create or replace trigger on_reservation_created
after insert on reservation
for each row
execute procedure CreateBill();
------------------------------


-----UpdateReservationFunction-----
create or replace function UpdateReservation()
returns trigger
language plpgsql
as $$
begin
	update reservation
	set status = new.status
	where reservation.reservation_id = new.reservation_id;

	return null;
end
$$;
-----------------------------------

-----OnBillUpdate-----
create or replace trigger on_bill_updated
after update on bill
for each row
execute procedure UpdateReservation()
----------------------