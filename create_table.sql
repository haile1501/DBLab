create table customer
(
	customer_id serial,
	company_name varchar(50),
	telephone_number varchar(12),
	email varchar(50),
	address varchar(50),
	
	constraint customer_pk primary key (customer_id)
);

--------------------------------------------
create table reservation
(
	reservation_id serial,
	customer_id int,
	reservate_date date,
	expire_date date,
	deposite_deadline date,
	requested_space decimal,
	reservation_type varchar(10),
	status varchar(15),
	
	constraint reservation_pk primary key (reservation_id),
	constraint reservation_type check (reservation_type in ('fixed', 'flexible')),
	constraint reservation_status check (status in ('pending', 'paid', 'terminated')),
	constraint reservation_customer_id_fk foreign key (customer_id) references customer(customer_id)
    on delete cascade
);

--------------------------------------------
create table product
(
	product_id serial,
	customer_id int,
	product_name varchar(50),
	cartons_num int,
	space_per_carton decimal,
	
	constraint product_pk primary key (product_id),
	constraint product_customer_fk foreign key (customer_id) references customer(customer_id)
	on delete cascade
);

--------------------------------------------
create table employee (
	employee_id serial primary key not null,
	manager_id int,
	employee_name varchar(30) not null,
	address varchar(50),
	telephone varchar(10),
	
	constraint manager_fk foreign key(manager_id) references employee(employee_id)
);

--------------------------------------------
create table wh_location (
	location_code text unique primary key not null,
	parent_location text,
	capacity decimal not null check(capacity > 0),
	available_space decimal,
	
	constraint parent_location_fk foreign key(parent_location) references wh_location(location_code)
	on delete cascade
	on update cascade
);

--------------------------------------------
create table location_product (
	location_code text not null,
	product_id int not null,
	spacee decimal check(spacee > 0),
	
	constraint location_fk foreign key(location_code) references wh_location(location_code)
	on update cascade
	on delete cascade,
	constraint product_fk foreign key(product_id) references product(product_id)
	on update cascade
	on delete cascade,
	constraint location_product_pk primary key(location_code, product_id)
);

--------------------------------------------
create table report (
	report_id serial primary key not null,
	product_id int not null,
	employee_id int not null,
	location_code text not null,
	report_time date not null,
	status varchar(15) check(status in ('pending', 'confirmed')),
	description text,
	
	constraint location_fk foreign key(location_code) references wh_location(location_code)
	on update cascade
	on delete cascade,
	constraint product_fk foreign key(product_id) references product(product_id)
	on delete cascade
	on update cascade,
	constraint employee_fk foreign key(employee_id) references employee(employee_id)
	on delete cascade
	on update cascade
);

--------------------------------------------
create table bill (
	reservation_id int not null,
	bill_period date,
	amount decimal,
	status varchar(15) check (status = 'pending' or status = 'paid' or status='terminated'),
	deadline date,
	
	constraint bill_pk primary key(reservation_id, bill_period),
	constraint reservation_fk foreign key(reservation_id) references reservation(reservation_id)
);

--------------------------------------------
create table operation(
	operation_id serial primary key not null,
	customer_id int not null,
	scheduled_time date,
	arrived_time date,
	status varchar(15) check(status in('pending', 'arrived')),
	operation_type varchar(15) check(operation_type in('receiving', 'shipping')),
	transport_company varchar(30),
	telephone varchar(10),
	vehicle varchar(10),
	additional_info text,
	
	constraint customer_fk foreign key(customer_id) references customer(customer_id)
);

--------------------------------------------
create table batch (
	product_id int not null,
	operation_id int not null,
	cartons_num int check(cartons_num > 0),
	
	constraint product_fk foreign key(product_id) references product(product_id)
	on delete cascade,
	constraint operation_fk foreign key(operation_id) references operation(operation_id)
	on delete cascade,
	constraint batch_pk primary key(product_id, operation_id)
);

--------------------------------------------
create table employee_operation(
	employee_id int not null,
	operation_id int not null,
	
	constraint operation_fk foreign key(operation_id) references operation(operation_id)
	on delete cascade,
	constraint employee_fk foreign key(employee_id) references employee(employee_id)
	on delete cascade,
	constraint employee_operation_pk primary key(employee_id, operation_id)
);

create table batch_location (
	operation_id int not null,
	cartons_num int,
	location_code text not null,
	
	constraint operation_fk foreign key(operation_id) references operation(operation_id)
	on delete cascade,
	constraint location_fk foreign key(location_code) references wh_location(location_code)
	on update cascade
	on delete cascade
);











