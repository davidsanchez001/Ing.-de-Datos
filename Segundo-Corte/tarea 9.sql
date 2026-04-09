/*Bases de datos */
/*Consultas 0000-00-00*/

DROP DATABASE IF EXISTS ejercicioClase;
create database ejercicioClase;
use ejercicioClase;

create table cliente(
codigo int primary key auto_increment,
nombre varchar(20) not null,
domicilio varchar(30) not null,
ciudad varchar(20) not null,
provincia varchar(20) not null,
telefono varchar(20) not null
);

insert into cliente (nombre,domicilio,ciudad,provincia,telefono)
values('tatiana','cra52#165-20','Bogotá','Bogotá DC','31025698');

insert into cliente (nombre,domicilio,ciudad,provincia,telefono)
values('tatiana','cra52#165-20','Bogotá','Bogotá DC','31025698');

insert into cliente (nombre,domicilio,ciudad,provincia,telefono) values
('tatiana','cra52#165-20','Bogotá','Bogotá DC','31025698'),
('Maria Paula','cra52#165-20','Bogotá','Bogotá DC','32566'),
('Mercedes','cra52#165-20','Bogotá','Bogotá DC','33665');

/*Consulta general Select*/

select * from cliente;

/*Consultas específicas*/
select codigo,nombre from cliente;

/*clausula where condiciones operadores lógicos or (o) and(y) negacion not,
aritméticos +- multi divi modulo % comparación == = <> < > <= >0*/

select domicilio from cliente where nombre='tatiana'or codigo=1;

select * from cliente where nombre='tatiana';
select * from cliente where nombre<>'tatiana';
select * from cliente where codigo>=2;
select * from cliente where codigo<=3;

select * from cliente where not nombre='tatiana'; 

/*Alias select campo1 as 'nombre que se desea mostrar'from nombreTabla*/
select nombre as 'Nombre Cliente', domicilio as 'Dirección Cliente',
ciudad,provincia as 'Departamento',telefono from cliente;

/*ordenar order by asc desc* select camposaConsultar 
from nombreTabla order by campoOrdenar tipoOrden*/

select * from cliente order by telefono asc;
select * from cliente order by telefono desc;

select nombre as 'Nombre Cliente', domicilio,ciudad,telefono from
cliente where nombre='tatiana' order by telefono asc;

/*Consultas agrupando group by select camposAConsultar from nombreTabla
condicion group by campoAgrupar orden*/
select nombre as 'Nombre Cliente', domicilio,ciudad,telefono 
from cliente where nombre='tatiana' 
group by nombre, domicilio, ciudad, telefono 
order by telefono desc;

/* like not like select camposConsular from nombreTabla 
condicion like valoraConsultar*/

select * from cliente where nombre like '%ti%';

select * from cliente where nombre like 'M%';
select * from cliente where nombre like '%a';


create table producto (
    id int primary key,
    nombre varchar(50),
    precio decimal(10,2),
    categoria varchar(50)
);
create table departamento (
    id int primary key,
    nombre varchar(50)
);
insert into departamento (id, nombre) values
(1, 'ventas'),
(2, 'tecnologia'),
(3, 'contabilidad');
create table empleados (
    id int primary key,
    nombre varchar(50),
    deptoId int,
    salario int,
    foreign key (deptoId) references departamento(id)
);
insert into empleados (id, nombre, deptoId, salario) values
(1, 'Ana', 1, 500),
(2, 'Maria', 2, 600),
(3, 'Juan', 1, 700),
(4, 'Laura', 3, 800),
(5, 'Alejandro', 2, 900);
insert into producto (id, nombre, precio, categoria) values
(1, 'Monitor', 150, 'tecnologia'),
(2, 'Teclado', 20, 'tecnologia'),
(3, 'Mouse', 10, 'tecnologia'),
(4, 'Esfero', 2, 'papeleria'),
(5, 'Cuaderno', 5, 'papeleria');

#Subconsulta
select categoria, max(precio) as precio_maximo
from producto
group by categoria
having max(precio) > (
    select avg(precio)
    from producto
)
order by precio_maximo desc;

select * from producto;

create table pedido (
    id int primary key auto_increment,
    fecha date,
    cliente_id int,
    total decimal(10,2),
    foreign key (cliente_id) references cliente(codigo)
);

create table detalle_pedido (
    id int primary key auto_increment,
    pedido_id int,
    producto_id int,
    cantidad int,
    precio_unitario decimal(10,2),
    foreign key (pedido_id) references pedido(id),
    foreign key (producto_id) references producto(id)
);

create table pedidos (
    id_pedido int auto_increment primary key,
    id_cliente int not null,
    fecha_pedido datetime default now(),
    estado enum('pendiente', 'enviado', 'entregado', 'cancelado'),
    total decimal(12,2) default 0,
    foreign key (id_cliente) references clientes(id_cliente)
);

create table detalle_pedido(
    id_detalle int auto_increment primary key,
    id_pedido int not null, 
    id_producto int not null,
    precio_unit decimal(10,2) not null,
    foreign key(id_pedido) references pedidos(id_pedido),
    foreign key(id_producto) references productos(id_producto)
);
select p.idpedido, c.nombre

select 
    c.nombre AS cliente,
    p.id AS pedido,
    pr.nombre AS producto,
    dp.cantidad,
    dp.precio_unitario
from pedido p
inner join cliente c ON p.cliente_id = c.codigo
INNER JOIN detalle_pedido dp ON dp.pedido_id = p.id
INNER JOIN producto pr ON dp.producto_id = pr.id;