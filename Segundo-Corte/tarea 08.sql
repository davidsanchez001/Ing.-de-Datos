
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

/* Subconsulta
select categoria, max(precio) as precio_maximo
from producto
group by categoria
having max(precio) > (
    select avg(precio)
    from producto
)
order by precio_maximo desc;