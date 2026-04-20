-- =====================================================
-- DDL: CREACION DE BASE DE DATOS Y TABLAS
-- =====================================================
drop database if exists tienda_tech;
create database tienda_tech character set utf8mb4;
use tienda_tech;

create table clientes (
    cliente_id     int auto_increment primary key,
    nombre         varchar(100) not null,
    email          varchar(100) unique not null,
    ciudad         varchar(60),
    fecha_registro date default (current_date)
);

create table productos (
    producto_id int auto_increment primary key,
    nombre      varchar(100) not null,
    categoria   varchar(60),
    precio      decimal(10,2) not null check (precio > 0),
    stock       int default 0
);

create table pedidos (
    pedido_id    int auto_increment primary key,
    cliente_id   int not null,
    producto_id  int not null,
    cantidad     int not null check (cantidad > 0),
    fecha_pedido date default (current_date),
    estado       varchar(20) default 'pendiente'
                 check (estado in ('pendiente','entregado','cancelado')),
    foreign key (cliente_id)  references clientes(cliente_id),
    foreign key (producto_id) references productos(producto_id)
);

-- =====================================================
-- DML: DATOS DE PRUEBA
-- =====================================================
insert into clientes values
 (1,'ana lopez','ana@mail.com','bogota','2023-01-15'),
 (2,'carlos ruiz','carlos@mail.com','medellin','2023-03-22'),
 (3,'maria torres','maria@mail.com','cali','2023-05-10'),
 (4,'pedro gomez','pedro@mail.com','bogota','2023-07-08'),
 (5,'sofia herrera','sofia@mail.com','barranquilla','2023-09-01'),
 (6,'luis martinez','luis@mail.com','bogota','2024-01-20'),
 (7,'camila vargas','camila@mail.com','cali','2024-02-14'),
 (8,'diego morales','diego@mail.com','medellin','2024-03-30');

insert into productos values
 (1,'laptop pro 15','computadores',3500000.00,12),
 (2,'mouse inalambrico','perifericos',85000.00,50),
 (3,'teclado mecanico','perifericos',220000.00,30),
 (4,'monitor 27','pantallas',1200000.00,8),
 (5,'auriculares bt','audio',350000.00,25),
 (6,'webcam hd','perifericos',180000.00,20),
 (7,'disco ssd 1tb','almacenamiento',420000.00,40),
 (8,'tablet 10','moviles',1800000.00,6);

insert into pedidos values
 (1,1,1,1,'2024-01-10','entregado'),(2,1,2,2,'2024-01-15','entregado'),
 (3,2,3,1,'2024-02-05','entregado'),(4,2,5,1,'2024-02-20','cancelado'),
 (5,3,4,1,'2024-03-01','entregado'),(6,3,7,2,'2024-03-15','pendiente'),
 (7,4,2,3,'2024-04-02','entregado'),(8,4,6,1,'2024-04-10','pendiente'),
 (9,5,8,1,'2024-04-18','entregado'),(10,6,1,2,'2024-05-05','entregado'),
 (11,6,3,1,'2024-05-12','pendiente'),(12,7,5,2,'2024-05-20','entregado'),
 (13,1,7,1,'2024-06-01','entregado'),(14,8,4,1,'2024-06-10','cancelado'),
 (15,5,2,4,'2024-06-15','entregado'),(16,3,1,1,'2024-07-01','pendiente');
 
#punto 1
alter table pedidos add column total_valor decimal(12,2) default 0;

update pedidos pe
inner join productos pr on pe.producto_id = pr.producto_id
set pe.total_valor = pe.cantidad * pr.precio;

create index idx_pedidos_estado on pedidos(estado);

select pedido_id, cliente_id, producto_id, cantidad, estado, total_valor
from pedidos
order by pedido_id;

#punto 2
create table log_cambios_estado (
    log_id          int auto_increment primary key,
    pedido_id       int not null,
    estado_anterior varchar(20),
    estado_nuevo    varchar(20),
    fecha_cambio    datetime default now(),
    foreign key (pedido_id) references pedidos(pedido_id)
);

create view vista_log_reciente as
select
    log_id,
    pedido_id,
    estado_anterior,
    estado_nuevo,
    fecha_cambio
from log_cambios_estado
order by fecha_cambio desc
limit 10;

select * from vista_log_reciente;

#punto 3
/* (a) insertar nuevo cliente */
insert into clientes (nombre, email, ciudad)
values ('laura rios', 'laura@mail.com', 'manizales');

/* (b) insertar pedido para laura rios — producto_id=3, cantidad=2 */
insert into pedidos (cliente_id, producto_id, cantidad, estado)
values (
    (select cliente_id from clientes where email = 'laura@mail.com'),
    3,
    2,
    'pendiente'
);

/* (c) decrementar stock del producto_id=3 en 2 unidades */
update productos
set stock = stock - 2
where producto_id = 3;

/* (d) consulta join: nombre cliente, nombre producto, estado del pedido recien creado */
select
    c.nombre   as cliente,
    pr.nombre  as producto,
    pe.estado,
    pe.cantidad,
    pe.fecha_pedido
from pedidos pe
inner join clientes c  on pe.cliente_id  = c.cliente_id
inner join productos pr on pe.producto_id = pr.producto_id
where c.email = 'laura@mail.com'
order by pe.pedido_id desc
limit 1;

#punto 4
update productos p
set p.precio = p.precio * 1.08
where p.stock < (
    select avg(p2.stock)
    from productos p2
    where p2.categoria = p.categoria
);

delete from pedidos
where estado = 'cancelado'
and not exists (
    select 1
    from pedidos pe2
    where pe2.cliente_id = pedidos.cliente_id
      and pe2.estado = 'entregado'
);

select pedido_id, cliente_id, estado from pedidos order by pedido_id;

#punto 5
select
    c.nombre       as cliente,
    c.ciudad,
    pr.nombre      as producto,
    pe.cantidad,
    pe.fecha_pedido,
    (pe.cantidad * pr.precio) as total
from pedidos pe
inner join clientes c   on pe.cliente_id  = c.cliente_id
inner join productos pr on pe.producto_id = pr.producto_id
where pe.estado = 'entregado'
  and (pe.cantidad * pr.precio) > (
      select avg(pe2.cantidad * pr2.precio)
      from pedidos pe2
      inner join productos pr2 on pe2.producto_id = pr2.producto_id
      where pe2.estado = 'entregado'
  )
order by total desc;

#punto 6
create view vista_ventas_ciudad as
select
    c.ciudad,
    count(pe.pedido_id)                    as total_pedidos_entregados,
    sum(pe.cantidad * pr.precio)           as suma_ingresos,
    avg(pe.cantidad * pr.precio)           as promedio_ingreso_por_pedido
from pedidos pe
inner join clientes c   on pe.cliente_id  = c.cliente_id
inner join productos pr on pe.producto_id = pr.producto_id
where pe.estado = 'entregado'
group by c.ciudad;

select
    ciudad,
    total_pedidos_entregados,
    suma_ingresos,
    promedio_ingreso_por_pedido
from vista_ventas_ciudad
where suma_ingresos > 5000000
order by suma_ingresos desc;

#punto 7
create view vista_productos_populares as
select
    pr.producto_id,
    pr.nombre,
    pr.categoria,
    pr.precio,
    count(distinct pe.cliente_id) as total_clientes_distintos
from pedidos pe
inner join productos pr on pe.producto_id = pr.producto_id
where pe.estado = 'entregado'
group by pr.producto_id, pr.nombre, pr.categoria, pr.precio
having count(distinct pe.cliente_id) > 1;

select
    producto_id,
    nombre,
    categoria,
    precio,
    total_clientes_distintos
from vista_productos_populares
where categoria = 'perifericos';

#punto 8
delimiter //
create function fn_ingreso_cliente(p_cliente_id int)
returns decimal(12,2)
deterministic
begin
    declare v_total decimal(12,2);

    select sum(pe.cantidad * pr.precio)
    into v_total
    from pedidos pe
    inner join productos pr on pe.producto_id = pr.producto_id
    where pe.cliente_id = p_cliente_id
      and pe.estado = 'entregado';

    if v_total is null then
        set v_total = 0;
    end if;

    return v_total;
end //
delimiter ;

select
    c.nombre,
    c.ciudad,
    fn_ingreso_cliente(c.cliente_id) as ingreso_total
from clientes c
order by ingreso_total desc;

#punto 9
delimiter //
create function fn_stock_suficiente(p_producto_id int, p_cantidad_solicitada int)
returns int
deterministic
begin
    declare v_stock int;

    select stock into v_stock
    from productos
    where producto_id = p_producto_id;

    if v_stock >= p_cantidad_solicitada then
        return 1;
    else
        return 0;
    end if;
end //
delimiter ;

select
    nombre,
    stock
from productos
where fn_stock_suficiente(producto_id, 5) = 0
order by stock asc;

#punto 10
delimiter //
create procedure sp_actualizar_estado_pedido(
    in  p_pedido_id    int,
    in  p_nuevo_estado varchar(20)
)
begin
    declare v_estado_anterior varchar(20);
    declare v_cliente_id      int;
    declare v_producto_id     int;
    declare v_cantidad        int;

    /* (a) verificar que el pedido exista */
    select estado, cliente_id, producto_id, cantidad
    into v_estado_anterior, v_cliente_id, v_producto_id, v_cantidad
    from pedidos
    where pedido_id = p_pedido_id;

    if v_estado_anterior is null then
        select 'error: el pedido no existe' as mensaje;
    else
        /* (b) registrar en el log el cambio de estado */
        insert into log_cambios_estado (pedido_id, estado_anterior, estado_nuevo)
        values (p_pedido_id, v_estado_anterior, p_nuevo_estado);

        /* (c) actualizar el estado del pedido */
        update pedidos
        set estado = p_nuevo_estado
        where pedido_id = p_pedido_id;

        /* (d) si el nuevo estado es cancelado, restaurar el stock */
        if p_nuevo_estado = 'cancelado' then
            update productos
            set stock = stock + v_cantidad
            where producto_id = v_producto_id;
        end if;

        select concat('pedido #', p_pedido_id, ' actualizado a: ', p_nuevo_estado) as mensaje;
    end if;
end //
delimiter ;

call sp_actualizar_estado_pedido(6, 'cancelado');

select * from log_cambios_estado;
select producto_id, nombre, stock from productos where producto_id = 7;

#punto 11
delimiter //
create procedure sp_resumen_cliente(
    in p_cliente_id int
)
begin
    select
        c.nombre                                                 as cliente,
        c.ciudad,
        sum(case when pe.estado = 'entregado'  then 1 else 0 end) as pedidos_entregados,
        sum(case when pe.estado = 'pendiente'  then 1 else 0 end) as pedidos_pendientes,
        sum(case when pe.estado = 'cancelado'  then 1 else 0 end) as pedidos_cancelados,
        sum(case when pe.estado = 'entregado'
                 then pe.cantidad * pr.precio
                 else 0 end)                                     as ingreso_total
    from clientes c
    inner join pedidos pe  on c.cliente_id   = pe.cliente_id
    inner join productos pr on pe.producto_id = pr.producto_id
    where c.cliente_id = p_cliente_id
    group by c.cliente_id, c.nombre, c.ciudad;
end //
delimiter ;

call sp_resumen_cliente(1);

call sp_resumen_cliente(2);

#punto 12
create view vista_pedidos_pendientes as
select
    pe.pedido_id,
    c.nombre                              as cliente,
    pr.nombre                             as producto,
    pe.cantidad,
    pr.precio                             as precio_unitario,
    datediff(curdate(), pe.fecha_pedido)  as dias_espera
from pedidos pe
inner join clientes c   on pe.cliente_id  = c.cliente_id
inner join productos pr on pe.producto_id = pr.producto_id
where pe.estado = 'pendiente';

delimiter //
create procedure sp_alertar_retrasos(
    in p_dias_limite int
)
begin
    select
        pedido_id,
        cliente,
        producto,
        cantidad,
        precio_unitario,
        dias_espera
    from vista_pedidos_pendientes
    where dias_espera > p_dias_limite
    order by dias_espera desc;
end //
delimiter ;

call sp_alertar_retrasos(30);

select * from vista_pedidos_pendientes;

#punto 13
alter table productos
add column descuento decimal(5,2) default 0
check (descuento >= 0 and descuento <= 50);

update productos set descuento = 10 where producto_id = 1;
update productos set descuento = 5  where producto_id = 4;
update productos set descuento = 15 where producto_id = 8;

delimiter //
create function fn_precio_final(p_producto_id int)
returns decimal(12,2)
deterministic
begin
    declare v_precio    decimal(10,2);
    declare v_descuento decimal(5,2);

    select precio, descuento
    into v_precio, v_descuento
    from productos
    where producto_id = p_producto_id;

    return v_precio * (1 - v_descuento / 100);
end //
delimiter ;

select
    nombre,
    precio,
    descuento,
    fn_precio_final(producto_id) as precio_final
from productos
order by fn_precio_final(producto_id) desc
limit 3;

#punto 14
delimiter //
create procedure sp_registrar_pedido(
    in  p_cliente_id  int,
    in  p_producto_id int,
    in  p_cantidad    int
)
begin
    declare v_cliente_existe int default 0;
    declare v_stock          int default 0;
    declare v_nuevo_pedido   int;

    /* (a) validar que el cliente exista */
    select count(*) into v_cliente_existe
    from clientes
    where cliente_id = p_cliente_id;

    if v_cliente_existe = 0 then
        select 'error: el cliente no existe' as mensaje;
    else
        /* (b) validar que el stock sea suficiente */
        select stock into v_stock
        from productos
        where producto_id = p_producto_id;

        if v_stock < p_cantidad then
            select concat('error: stock insuficiente. disponible: ', v_stock) as mensaje;
        else
            /* (c) insertar el pedido con estado pendiente */
            insert into pedidos (cliente_id, producto_id, cantidad, estado)
            values (p_cliente_id, p_producto_id, p_cantidad, 'pendiente');

            set v_nuevo_pedido = last_insert_id();

            /* (d) descontar el stock del producto */
            update productos
            set stock = stock - p_cantidad
            where producto_id = p_producto_id;

            /* (e) retornar el pedido recien creado con join */
            select
                pe.pedido_id,
                c.nombre   as cliente,
                pr.nombre  as producto,
                pe.cantidad,
                pe.estado,
                pe.fecha_pedido
            from pedidos pe
            inner join clientes c   on pe.cliente_id  = c.cliente_id
            inner join productos pr on pe.producto_id = pr.producto_id
            where pe.pedido_id = v_nuevo_pedido;
        end if;
    end if;
end //
delimiter ;

call sp_registrar_pedido(3, 2, 1);

/* prueba: cliente inexistente */
call sp_registrar_pedido(99, 2, 1);

call sp_registrar_pedido(1, 8, 100);

#punto 15
delimiter //
create function fn_clasificar_producto(p_producto_id int)
returns varchar(20)
deterministic
begin
    declare v_precio decimal(10,2);

    select precio into v_precio
    from productos
    where producto_id = p_producto_id;

    if v_precio > 1000000 then
        return 'premium';
    elseif v_precio >= 200000 then
        return 'estandar';
    else
        return 'basico';
    end if;
end //
delimiter ;

create view vista_catalogo_clasificado as
select
    nombre,
    categoria,
    precio,
    fn_clasificar_producto(producto_id) as clasificacion,
    stock
from productos;

select
    nombre,
    categoria,
    precio,
    clasificacion,
    stock
from vista_catalogo_clasificado
where clasificacion = 'premium'
  and stock > 5;
  
#punto 16
create view vista_clientes_vip as
select
    c.cliente_id,
    c.nombre,
    c.ciudad,
    count(pe.pedido_id) as total_pedidos_entregados
from clientes c
inner join pedidos pe on c.cliente_id = pe.cliente_id
where pe.estado = 'entregado'
group by c.cliente_id, c.nombre, c.ciudad
having count(pe.pedido_id) > (
    /* promedio de pedidos entregados por cliente */
    select avg(conteo)
    from (
        select count(*) as conteo
        from pedidos
        where estado = 'entregado'
        group by cliente_id
    ) as sub_avg
);

select * from vista_clientes_vip;

select
    vip.nombre     as cliente,
    pr.nombre      as producto,
    pe.fecha_pedido,
    pe.estado
from vista_clientes_vip vip
inner join pedidos pe  on vip.cliente_id  = pe.cliente_id
inner join productos pr on pe.producto_id = pr.producto_id
where pe.pedido_id in (
    select pe2.pedido_id
    from pedidos pe2
    where pe2.cliente_id = vip.cliente_id
    order by pe2.fecha_pedido desc
    limit 2
)
order by vip.nombre, pe.fecha_pedido desc;

#ejercicios propios
/* ejercicio a — select con like: buscar clientes cuyo nombre empiece con 'a' */
select cliente_id, nombre, ciudad
from clientes
where nombre like 'a%';

/* ejercicio b — alias y order by: listar productos ordenados por precio desc */
select
    nombre         as 'nombre producto',
    categoria      as 'tipo',
    precio         as 'valor',
    stock          as 'unidades disponibles'
from productos
order by precio desc;

/* ejercicio c — group by + having: categorias con mas de 1 producto */
select
    categoria,
    count(*)       as total_productos,
    avg(precio)    as precio_promedio
from productos
group by categoria
having count(*) > 1
order by total_productos desc;

/* ejercicio d — left join: clientes que no tienen ningun pedido */
select
    c.cliente_id,
    c.nombre,
    c.ciudad,
    count(pe.pedido_id) as total_pedidos
from clientes c
left join pedidos pe on c.cliente_id = pe.cliente_id
group by c.cliente_id, c.nombre, c.ciudad
order by c.nombre;

/* ejercicio e — subconsulta en where: productos con precio mayor al promedio */
select nombre, categoria, precio
from productos
where precio > (select avg(precio) from productos)
order by precio desc;

/* ejercicio f — update masivo: marcar todos los pedidos pendientes
   con mas de 90 dias como cancelados */
update pedidos
set estado = 'cancelado'
where estado = 'pendiente'
  and datediff(curdate(), fecha_pedido) > 90;

/* ejercicio g — alter table: agregar columna telefono a clientes */
alter table clientes
add column telefono varchar(20) after ciudad;

/* ejercicio h — rename table: renombrar log_cambios_estado a log_pedidos */
rename table log_cambios_estado to log_pedidos;

/* ejercicio i — truncate: vaciar la tabla log_pedidos (conserva estructura) */
/* truncate table log_pedidos; */
/* (comentado para no perder los datos del ejercicio 10) */

/* ejercicio j — drop column: eliminar la columna telefono recien agregada */
alter table clientes drop column telefono;

/* ejercicio k — describe: ver estructura de las tablas principales */
describe clientes;
describe productos;
describe pedidos;

/* ejercicio l — index: crear indice en clientes por ciudad */
create index idx_clientes_ciudad on clientes(ciudad);

/* ejercicio m — consulta con not: clientes que no son de bogota */
select nombre, ciudad
from clientes
where not ciudad = 'bogota'
order by ciudad;

/* ejercicio n — between: productos con precio entre 100,000 y 500,000 */
select nombre, precio, stock
from productos
where precio between 100000 and 500000
order by precio;