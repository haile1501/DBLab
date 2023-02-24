/* search product */
create or replace function search_product(p_customer_id int, p_product_name varchar(50))
returns table(
    product_name varchar(50),
    product_id int,
    cartons_num int,
    space_per_carton decimal
)
language plpgsql
as $$
begin
    drop table if exists result;
    create temp table result as
    select *
    from product;

    if (p_customer_id is not null)
    then
        delete from result r
        where r.customer_id <> p_customer_id;
    end if;

    if (p_product_name is not null)
    then 
        delete from result r
        where r.product_name <> p_product_name;
    end if;

    return query
    select *
    from result;
end
$$;

/* create product information */
create or replace procedure create_product(p_customer_id int, p_product_name varchar(50), p_space_per_carton decimal)
language plpgsql
as $$
begin
    insert into product(customer_id, product_name, space_per_carton, cartons_num)
    values(p_customer_id, p_product_name, p_space_per_carton, 0);
end
$$;

/* edit product */
create or replace procedure edit_product(p_product_id int, p_product_name varchar(50), p_cartons_num int, p_space_per_carton decimal)
language plpgsql
as $$
begin
    update product
    set product_name = p_product_name,
        cartons_num = p_cartons_num,
        space_per_carton = p_space_per_carton
    where product_id = p_product_id;
end
$$;

/* delete product */
create or replace procedure delete_product(p_product_id int)
language plpgsql
as $$
begin
    delete from product
    where product_id = p_product_id;
end
$$;