drop database if exists tienda_don_pepe;
create database tienda_don_pepe;
use tienda_don_pepe;

-- tabla: categorias
create table categorias (
    id_categoria int auto_increment primary key,
    nombre       varchar(50) not null,
    descripcion  varchar(100),
    constraint uq_cat_nombre unique (nombre)
);

-- tabla: proveedores
create table proveedores (
    id_proveedor   int auto_increment primary key,
    nombre         varchar(80) not null,
    contacto       varchar(80),
    telefono       varchar(20) not null,
    email          varchar(80),
    ciudad         varchar(50) default 'bogota',
    activo         tinyint(1)  default 1,
    fecha_registro date        default (current_date)
);

-- tabla: productos
create table productos (
    id_producto       int auto_increment primary key,
    nombre            varchar(80)   not null,
    id_categoria      int           not null,
    id_proveedor      int           not null,
    precio_compra     decimal(10,2) not null,
    precio_venta      decimal(10,2) not null,
    stock_actual      int           not null default 0,
    stock_minimo      int           not null default 5,
    fecha_vencimiento date,
    unidad_medida     varchar(20)   default 'und',
    activo            tinyint(1)    default 1,
    fecha_registro    datetime      default now(),
    constraint fk_prod_cat  foreign key (id_categoria) references categorias(id_categoria),
    constraint fk_prod_prov foreign key (id_proveedor) references proveedores(id_proveedor),
    constraint chk_precios  check (precio_venta >= precio_compra)
);

-- tabla: usuarios
create table usuarios (
    id_usuario     int auto_increment primary key,
    nombre         varchar(80)  not null,
    email          varchar(80)  not null unique,
    clave_hash     varchar(255) not null,
    rol            enum('admin','empleado','dueno') not null default 'empleado',
    activo         tinyint(1)   default 1,
    fecha_registro datetime     default now()
);

-- tabla: ventas
create table ventas (
    id_venta      int auto_increment primary key,
    id_usuario    int           not null,
    fecha_venta   datetime      default now(),
    total         decimal(12,2) default 0.00,
    estado        enum('completada','anulada') default 'completada',
    observaciones varchar(200),
    constraint fk_venta_usuario foreign key (id_usuario) references usuarios(id_usuario)
);

-- tabla: detalle_venta (resuelve relacion n:m entre ventas y productos)
create table detalle_venta (
    id_detalle      int auto_increment primary key,
    id_venta        int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2) generated always as (cantidad * precio_unitario) stored,
    constraint fk_dv_venta    foreign key (id_venta)    references ventas(id_venta),
    constraint fk_dv_producto foreign key (id_producto) references productos(id_producto),
    constraint chk_cantidad   check (cantidad > 0)
);

-- tabla: pedidos
create table pedidos (
    id_pedido      int auto_increment primary key,
    id_proveedor   int           not null,
    id_usuario     int           not null,
    fecha_pedido   datetime      default now(),
    fecha_entrega  date,
    total          decimal(12,2) default 0.00,
    estado         enum('pendiente','recibido','cancelado') default 'pendiente',
    observaciones  varchar(200),
    constraint fk_ped_prov    foreign key (id_proveedor) references proveedores(id_proveedor),
    constraint fk_ped_usuario foreign key (id_usuario)   references usuarios(id_usuario)
);

-- tabla: detalle_pedido (resuelve relacion n:m entre pedidos y productos)
create table detalle_pedido (
    id_detalle      int auto_increment primary key,
    id_pedido       int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2) generated always as (cantidad * precio_unitario) stored,
    constraint fk_dp_pedido   foreign key (id_pedido)   references pedidos(id_pedido),
    constraint fk_dp_producto foreign key (id_producto) references productos(id_producto)
);

-- tabla: historial_precios (rqf-31)
create table historial_precios (
    id_historial           int auto_increment primary key,
    id_producto            int           not null,
    precio_compra_anterior decimal(10,2),
    precio_venta_anterior  decimal(10,2),
    precio_compra_nuevo    decimal(10,2),
    precio_venta_nuevo     decimal(10,2),
    fecha_cambio           datetime      default now(),
    id_usuario             int,
    constraint fk_hp_producto foreign key (id_producto) references productos(id_producto)
);

-- tabla: auditoria_movimientos (rqf-29)
create table auditoria_movimientos (
    id_auditoria    int auto_increment primary key,
    tabla_afectada  varchar(50)  not null,
    id_registro     int          not null,
    tipo_operacion  enum('insert','update','delete') not null,
    descripcion     varchar(255),
    id_usuario      int,
    fecha_operacion datetime     default now()
);

-- tabla: devoluciones (rqf-34)
create table devoluciones (
    id_devolucion    int auto_increment primary key,
    id_venta         int          not null,
    id_producto      int          not null,
    cantidad         int          not null,
    motivo           varchar(200),
    fecha_devolucion datetime     default now(),
    id_usuario       int          not null,
    constraint fk_dev_venta    foreign key (id_venta)    references ventas(id_venta),
    constraint fk_dev_producto foreign key (id_producto) references productos(id_producto)
);

-- categorias (10 registros)
insert into categorias (nombre, descripcion) values
('bebidas',       'gaseosas, aguas, jugos y bebidas energeticas'),
('lacteos',       'leche, queso, yogurt y derivados'),
('abarrotes',     'arroz, azucar, aceite y productos de despensa'),
('snacks',        'papas, galletas, mani y pasabocas'),
('aseo personal', 'jabon, shampoo, cremas y cuidado personal'),
('aseo hogar',    'detergente, limpiadores y desengrasantes'),
('panaderia',     'pan, galletas y productos de horno'),
('licores',       'cerveza, aguardiente y vinos'),
('congelados',    'helados, carnes y productos frios'),
('miscelanea',    'pilas, velas, bolsas y otros');

-- proveedores (10 registros)
insert into proveedores (nombre, contacto, telefono, email, ciudad) values
('postobon s.a.',                 '[nombre_eliminado]', '3001234567', 'ventas@postobon.com',       'bogota'),
('alpina productos alimenticios', '[nombre_eliminado]', '3017654321', 'pedidos@alpina.com.co',     'bogota'),
('arroz diana',                   '[nombre_eliminado]', '3109876543', 'comercial@arrozdiana.com',  'bogota'),
('bimbo de colombia',             '[nombre_eliminado]', '3125551234', 'pedidos@bimbo.com.co',      'bogota'),
('bavaria s.a.',                  '[nombre_eliminado]', '3001112233', 'ventas@bavaria.com.co',     'bogota'),
('colombina s.a.',                '[nombre_eliminado]', '3044445566', 'comercial@colombina.com',   'cali'),
('unilever colombia',             '[nombre_eliminado]', '3167778899', 'pedidos@unilever.co',       'bogota'),
('proaseo colombia',              '[nombre_eliminado]', '3183334455', 'ventas@proaseo.com.co',     'medellin'),
('distribuidora norte',           '[nombre_eliminado]', '3201234321', 'distrinorte@gmail.com',     'bogota'),
('helados popsy',                 '[nombre_eliminado]', '3219998877', 'pedidos@popsy.com.co',      'bogota');

-- usuarios (5 registros)
insert into usuarios (nombre, email, clave_hash, rol) values
('don pepe rodriguez', 'donpepe@tienda.com', '$2b$10$hash_dueno_1', 'dueno'),
('empleado-1',         'emp1@tienda.com',    '$2b$10$hash_emp_1',   'empleado'),
('empleado-2',         'emp2@tienda.com',    '$2b$10$hash_emp_2',   'empleado'),
('admin sistema',      'admin@tienda.com',   '$2b$10$hash_admin',   'admin'),
('empleado-3',         'emp3@tienda.com',    '$2b$10$hash_emp_3',   'empleado');

-- productos (50 registros)
insert into productos (nombre, id_categoria, id_proveedor, precio_compra, precio_venta, stock_actual, stock_minimo, fecha_vencimiento, unidad_medida) values
('gaseosa cola 1.5l',          1, 1,  2800,  3500, 45, 10, '2025-12-31', 'bot'),
('gaseosa naranja 1.5l',       1, 1,  2800,  3500, 30, 10, '2025-12-31', 'bot'),
('agua cristal 600ml',         1, 1,   900,  1500, 80, 20, '2026-06-30', 'bot'),
('jugo hit mango 200ml',       1, 1,  1200,  1800, 60, 15, '2025-11-30', 'und'),
('gaseosa manzana 500ml',      1, 1,  1800,  2500, 25,  8, '2025-10-31', 'bot'),
('leche entera 1l',            2, 2,  2600,  3200, 40, 15, '2025-04-30', 'und'),
('leche deslactosada 1l',      2, 2,  3000,  3800, 20,  8, '2025-04-28', 'und'),
('yogurt 200g',                2, 2,  1500,  2000, 35, 10, '2025-05-15', 'und'),
('queso campesino 250g',       2, 2,  4500,  5500, 18,  5, '2025-04-25', 'und'),
('kumis 200ml',                2, 2,  1800,  2400, 22,  8, '2025-05-10', 'und'),
('arroz diana 500g',           3, 3,  1800,  2500, 55, 20, '2026-12-31', 'und'),
('arroz diana 1kg',            3, 3,  3200,  4200, 48, 15, '2026-12-31', 'und'),
('azucar manuelita 1kg',       3, 9,  2800,  3500, 60, 20, '2026-06-30', 'und'),
('aceite gourmet 1l',          3, 9,  8500, 10500, 25, 10, '2026-03-31', 'bot'),
('sal refisal 1kg',            3, 9,   900,  1500, 70, 20, '2027-01-01', 'und'),
('papa margarita 105g',        4, 6,  1800,  2500, 50, 15, '2025-08-31', 'und'),
('tosh integral 117g',         4, 6,  2200,  3000, 35, 10, '2025-09-30', 'und'),
('chitos 70g',                 4, 6,  1200,  1800, 45, 12, '2025-07-31', 'und'),
('mani salado 100g',           4, 9,  1500,  2200, 30, 10, '2025-10-31', 'und'),
('galletas festival 150g',     4, 6,  2500,  3200, 40, 12, '2025-11-30', 'und'),
('jabon rey 230g',             5, 7,  2200,  3000, 40, 10, '2027-06-30', 'und'),
('shampoo 200ml',              5, 7,  9500, 12000, 20,  5, '2026-12-31', 'und'),
('crema dental 75ml',          5, 7,  4500,  6000, 30,  8, '2026-08-31', 'und'),
('desodorante 150ml',          5, 7,  8500, 11000, 15,  5, '2026-10-31', 'und'),
('papel higienico x4',         5, 8,  6500,  8500, 25,  8, '2027-12-31', 'paq'),
('detergente ariel 500g',      6, 7,  6800,  8500, 30, 10, '2027-03-31', 'und'),
('suavitel 500ml',             6, 7,  4500,  6000, 25,  8, '2026-12-31', 'bot'),
('pinesol 500ml',              6, 8,  4200,  5500, 20,  6, '2026-09-30', 'bot'),
('esponja x2',                 6, 8,  3500,  5000, 20,  6, '2027-12-31', 'paq'),
('bolsas basura negras x10',   6, 9,  2800,  4000, 35, 10, '2027-12-31', 'paq'),
('pan tajado bimbo 600g',      7, 4,  4200,  5500, 25,  8, '2025-04-20', 'und'),
('pan integral bimbo 400g',    7, 4,  3800,  5000, 20,  6, '2025-04-21', 'und'),
('mogolla x6 bimbo',           7, 4,  2500,  3500, 18,  5, '2025-04-19', 'und'),
('galleta oreo 36g',           7, 6,   800,  1200, 60, 15, '2025-12-31', 'und'),
('tostadas 120g',              7, 6,  2200,  3000, 30, 10, '2025-10-31', 'und'),
('cerveza club colombia 330ml',8, 5,  2500,  3500, 80, 20, '2025-10-31', 'und'),
('cerveza aguila 330ml',       8, 5,  2200,  3000, 90, 25, '2025-10-31', 'und'),
('cerveza poker 330ml',        8, 5,  2000,  2800, 70, 20, '2025-10-31', 'und'),
('aguardiente 375ml',          8, 9, 18000, 24000, 15,  5, '2027-01-01', 'bot'),
('ron 375ml',                  8, 9, 22000, 28000, 10,  4, '2027-01-01', 'bot'),
('helado vainilla 130ml',      9,10,  2200,  3000, 30,  8, '2025-06-30', 'und'),
('helado chocolate 130ml',     9,10,  2200,  3000, 28,  8, '2025-06-30', 'und'),
('paleta bon ice 80ml',        9,10,  1000,  1500, 50, 12, '2025-07-31', 'und'),
('salchichon zenu 250g',       9, 9,  5500,  7000, 20,  6, '2025-05-15', 'und'),
('jamon zenu 250g',            9, 9,  6000,  7500, 18,  6, '2025-05-20', 'und'),
('pilas duracell aa x2',      10, 9,  4500,  6500, 25,  8, '2028-12-31', 'paq'),
('velas blancas x10',         10, 9,  2500,  3500, 30,  8, '2030-01-01', 'paq'),
('bolsas plasticas x100',     10, 9,  1800,  2800, 40, 10, '2030-01-01', 'paq'),
('fosforos x10 cajas',        10, 9,  1200,  2000, 50, 12, '2028-01-01', 'paq'),
('chicles x3',                10, 6,   800,  1500, 45, 10, '2026-03-31', 'und');

-- ventas - cabeceras (60 registros)
insert into ventas (id_usuario, fecha_venta, total, estado) values
(2,'2025-01-05 08:15:00', 18500,'completada'),
(2,'2025-01-05 09:30:00', 12000,'completada'),
(3,'2025-01-06 10:00:00', 25500,'completada'),
(2,'2025-01-07 11:20:00',  8500,'completada'),
(3,'2025-01-08 14:00:00', 32000,'completada'),
(2,'2025-01-09 08:45:00', 15000,'completada'),
(5,'2025-01-10 09:00:00', 42000,'completada'),
(3,'2025-01-11 10:30:00', 11500,'completada'),
(2,'2025-01-12 11:00:00', 28000,'completada'),
(5,'2025-01-13 14:30:00', 19000,'completada'),
(3,'2025-01-15 08:00:00', 35000,'completada'),
(2,'2025-01-16 09:15:00', 22000,'completada'),
(5,'2025-01-17 10:45:00', 16000,'completada'),
(2,'2025-01-18 11:30:00', 44000,'completada'),
(3,'2025-01-20 14:00:00', 27000,'completada'),
(2,'2025-01-22 08:30:00', 38000,'completada'),
(5,'2025-01-24 09:00:00', 13500,'completada'),
(3,'2025-01-25 10:15:00', 29000,'completada'),
(2,'2025-01-27 11:45:00', 21000,'completada'),
(3,'2025-01-29 14:00:00', 51000,'completada'),
(2,'2025-02-01 08:00:00', 17500,'completada'),
(5,'2025-02-02 09:30:00', 23000,'completada'),
(3,'2025-02-03 10:00:00', 34000,'completada'),
(2,'2025-02-05 11:15:00',  9500,'completada'),
(3,'2025-02-06 14:30:00', 45000,'completada'),
(5,'2025-02-07 08:45:00', 26000,'completada'),
(2,'2025-02-08 09:00:00', 18000,'completada'),
(3,'2025-02-10 10:30:00', 37000,'completada'),
(2,'2025-02-11 11:00:00', 14500,'completada'),
(5,'2025-02-12 14:00:00', 52000,'completada'),
(3,'2025-02-14 08:15:00', 41000,'completada'),
(2,'2025-02-15 09:45:00', 28500,'completada'),
(5,'2025-02-17 10:00:00', 19500,'completada'),
(3,'2025-02-18 11:30:00', 33000,'completada'),
(2,'2025-02-20 14:15:00', 24000,'completada'),
(5,'2025-02-22 08:00:00', 47000,'completada'),
(3,'2025-02-24 09:15:00', 16500,'completada'),
(2,'2025-02-25 10:45:00', 31000,'completada'),
(5,'2025-02-27 11:00:00', 22500,'completada'),
(3,'2025-02-28 14:30:00', 58000,'completada'),
(2,'2025-03-01 08:30:00', 20000,'completada'),
(3,'2025-03-03 09:00:00', 35500,'completada'),
(5,'2025-03-04 10:15:00', 27500,'completada'),
(2,'2025-03-05 11:45:00', 12500,'completada'),
(3,'2025-03-06 14:00:00', 48000,'completada'),
(5,'2025-03-07 08:00:00', 23500,'completada'),
(2,'2025-03-08 09:30:00', 39000,'completada'),
(3,'2025-03-10 10:00:00', 17000,'completada'),
(5,'2025-03-11 11:15:00', 54000,'completada'),
(2,'2025-03-12 14:45:00', 30000,'completada'),
(3,'2025-03-13 08:30:00', 26500,'completada'),
(5,'2025-03-14 09:00:00', 43000,'completada'),
(2,'2025-03-15 10:30:00', 19000,'completada'),
(3,'2025-03-17 11:00:00', 36000,'completada'),
(5,'2025-03-18 14:15:00', 25000,'completada'),
(2,'2025-03-20 08:45:00', 61000,'completada'),
(3,'2025-03-22 09:15:00', 14000,'completada'),
(5,'2025-03-24 10:45:00', 42500,'completada'),
(2,'2025-03-26 11:30:00', 32000,'completada'),
(3,'2025-03-28 14:00:00', 28000,'completada');

-- detalle de ventas (45 lineas)
insert into detalle_venta (id_venta, id_producto, cantidad, precio_unitario) values
(1, 1, 2, 3500),(1, 6, 1, 3200),(1,11, 2, 2500),
(2,36, 2, 3500),(2,37, 1, 3000),
(3, 1, 3, 3500),(3,16, 2, 2500),(3,21, 1, 3000),
(4, 6, 1, 3200),(4, 8, 1, 2000),
(5,36, 4, 3500),(5,37, 2, 3000),(5,11, 3, 2500),
(6, 1, 2, 3500),(6,31, 1, 5500),
(7,36, 5, 3500),(7,37, 3, 3000),(7,38, 4, 2800),
(8, 6, 1, 3200),(8,16, 1, 2500),(8,34, 1, 1200),
(9, 1, 3, 3500),(9,11, 2, 2500),(9,36, 2, 3500),
(10, 8, 2, 2000),(10, 6, 1, 3200),(10,41, 1, 3000),
(11,36, 4, 3500),(11, 1, 2, 3500),(11,31, 1, 5500),
(12, 6, 2, 3200),(12,11, 3, 2500),(12,37, 1, 3000),
(13,16, 2, 2500),(13,21, 1, 3000),(13,34, 1, 1200),
(14,36, 5, 3500),(14,37, 3, 3000),(14,38, 4, 2800),(14, 1, 2, 3500),
(15, 6, 1, 3200),(15, 8, 2, 2000),(15,11, 2, 2500);

-- pedidos a proveedores (10 registros)
insert into pedidos (id_proveedor, id_usuario, fecha_pedido, fecha_entrega, total, estado) values
(1,1,'2025-01-10','2025-01-12', 350000,'recibido'),
(2,1,'2025-01-15','2025-01-17', 280000,'recibido'),
(3,4,'2025-01-20','2025-01-22', 420000,'recibido'),
(5,1,'2025-02-01','2025-02-03', 650000,'recibido'),
(1,1,'2025-02-10','2025-02-12', 380000,'recibido'),
(4,4,'2025-02-18','2025-02-20', 240000,'recibido'),
(7,1,'2025-03-01','2025-03-03', 520000,'recibido'),
(2,4,'2025-03-10','2025-03-12', 310000,'recibido'),
(5,1,'2025-03-20','2025-03-22', 720000,'pendiente'),
(1,4,'2025-03-25','2025-03-27', 410000,'pendiente');

-- detalle de pedidos (30 lineas)
insert into detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) values
(1, 1, 50, 2800),(1, 2, 30, 2800),(1, 3,100,  900),
(2, 6, 40, 2600),(2, 7, 20, 3000),(2, 8, 30, 1500),
(3,11, 60, 1800),(3,12, 50, 3200),(3,13, 40, 2800),
(4,36,100, 2500),(4,37,120, 2200),(4,38, 80, 2000),
(5, 1, 60, 2800),(5, 4, 50, 1200),(5, 5, 30, 1800),
(6,31, 40, 4200),(6,32, 30, 3800),(6,33, 20, 2500),
(7,21, 30, 2200),(7,26, 25, 6800),(7,22, 15, 9500),
(8, 6, 50, 2600),(8, 9, 20, 4500),(8,10, 25, 1800),
(9,36,150, 2500),(9,37,150, 2200),(9,38,100, 2000),
(10,1, 80, 2800),(10,2, 60, 2800),(10,3,120,  900);

-- devoluciones (5 registros)
insert into devoluciones (id_venta, id_producto, cantidad, motivo, id_usuario) values
(3,  6, 1, 'producto vencido',       2),
(7, 36, 2, 'lata golpeada',          3),
(14,37, 1, 'temperatura incorrecta', 5),
(20,11, 1, 'empaque roto',           2),
(25, 8, 1, 'producto en mal estado', 3);

select * from categorias;
select * from proveedores;
select * from usuarios;
select * from productos;
select * from ventas;
select * from detalle_venta;
select * from pedidos;
select * from detalle_pedido;
select * from devoluciones;

-- e1. productos con stock bajo (rqf-15)
select p.nombre, p.stock_actual, p.stock_minimo,
       (p.stock_minimo - p.stock_actual) as unidades_faltantes
from productos p
where p.stock_actual <= p.stock_minimo and p.activo = 1
order by unidades_faltantes desc;

-- e2. productos proximos a vencer en los proximos 30 dias (rqf-16)
select nombre, fecha_vencimiento, stock_actual,
       datediff(fecha_vencimiento, curdate()) as dias_para_vencer
from productos
where fecha_vencimiento is not null
  and fecha_vencimiento between curdate() and date_add(curdate(), interval 30 day)
order by fecha_vencimiento asc;

-- e3. margen de ganancia por producto (rqf-25)
select nombre, precio_compra, precio_venta,
       (precio_venta - precio_compra) as margen_bruto,
       round(((precio_venta - precio_compra) / precio_compra) * 100, 2) as margen_porcentaje
from productos
where activo = 1
order by margen_porcentaje desc;

-- e4. productos por categoria con precio promedio (rqf-26)
select c.nombre as categoria,
       count(p.id_producto) as total_productos,
       avg(p.precio_venta)  as precio_promedio_venta
from productos p
join categorias c on p.id_categoria = c.id_categoria
where p.activo = 1
group by c.id_categoria, c.nombre
order by total_productos desc;

-- e5. valorizacion del inventario actual (rqf-24)
select p.nombre, c.nombre as categoria,
       p.stock_actual, p.precio_compra,
       (p.stock_actual * p.precio_compra) as valor_inventario
from productos p
join categorias c on p.id_categoria = c.id_categoria
order by valor_inventario desc;

-- e6. clasificacion abc por precio de venta (rqf-32)
select nombre, precio_venta,
       case
           when precio_venta >= 8000               then 'a - alto valor'
           when precio_venta between 3000 and 7999  then 'b - valor medio'
           else                                          'c - bajo valor'
       end as clasificacion_abc
from productos
where activo = 1
order by precio_venta desc;

-- e7. productos por proveedor con valor total de inventario (rqf-33)
select pv.nombre as proveedor,
       count(p.id_producto) as total_productos,
       sum(p.stock_actual * p.precio_compra) as valor_total_inventario
from productos p
join proveedores pv on p.id_proveedor = pv.id_proveedor
group by pv.id_proveedor, pv.nombre
order by valor_total_inventario desc;

-- e8. total de ventas por dia (rqf-12)
select date(fecha_venta) as fecha,
       count(*) as num_ventas,
       sum(total) as total_dia
from ventas
where estado = 'completada'
group by date(fecha_venta)
order by fecha desc;

-- e9. ventas por mes con comparativo (rqf-35)
select year(fecha_venta)  as anio,
       month(fecha_venta) as mes,
       count(*) as num_ventas,
       sum(total) as total_mensual,
       avg(total) as promedio_por_venta
from ventas
where estado = 'completada'
group by year(fecha_venta), month(fecha_venta)
order by anio desc, mes desc;

-- e10. promedio diario de ventas por mes (rqf-18)
select year(fecha_venta)  as anio,
       month(fecha_venta) as mes,
       sum(total) as total_mes,
       count(distinct date(fecha_venta)) as dias_con_ventas,
       round(sum(total) / count(distinct date(fecha_venta)), 0) as promedio_diario
from ventas
where estado = 'completada'
group by year(fecha_venta), month(fecha_venta)
order by anio, mes;

-- e11. rendimiento por empleado
select u.nombre as empleado, u.rol,
       count(v.id_venta) as ventas_realizadas,
       sum(v.total)      as total_vendido
from ventas v
join usuarios u on v.id_usuario = u.id_usuario
where v.estado = 'completada'
group by u.id_usuario, u.nombre, u.rol
order by total_vendido desc;

-- e12. pedidos por proveedor y estado
select pv.nombre as proveedor, p.estado,
       count(*) as num_pedidos,
       sum(p.total) as total_compras
from pedidos p
join proveedores pv on p.id_proveedor = pv.id_proveedor
group by pv.id_proveedor, pv.nombre, p.estado
order by total_compras desc;

-- e13. pedidos pendientes de entrega
select p.id_pedido, pv.nombre as proveedor,
       p.fecha_pedido, p.fecha_entrega, p.total
from pedidos p
join proveedores pv on p.id_proveedor = pv.id_proveedor
where p.estado = 'pendiente'
order by p.fecha_entrega asc;

-- e14. productos mas pedidos historicamente
select pr.nombre, sum(dp.cantidad) as total_pedido
from detalle_pedido dp
join productos pr on dp.id_producto = pr.id_producto
group by pr.id_producto, pr.nombre
order by total_pedido desc
limit 10;

-- m1. reporte detallado: venta + producto + empleado + categoria (rqf-13)
select v.id_venta, date(v.fecha_venta) as fecha,
       u.nombre as empleado,
       p.nombre as producto, c.nombre as categoria,
       dv.cantidad, dv.precio_unitario, dv.subtotal
from ventas v
join usuarios u       on v.id_usuario   = u.id_usuario
join detalle_venta dv on dv.id_venta    = v.id_venta
join productos p      on dv.id_producto = p.id_producto
join categorias c     on p.id_categoria = c.id_categoria
where v.estado = 'completada'
order by v.fecha_venta desc, v.id_venta;

-- m2. productos mas vendidos (rqf-14)
select p.nombre as producto, c.nombre as categoria,
       sum(dv.cantidad) as total_unidades_vendidas,
       sum(dv.subtotal) as total_ingresos,
       count(distinct dv.id_venta) as num_ventas
from detalle_venta dv
join productos p  on dv.id_producto = p.id_producto
join categorias c on p.id_categoria = c.id_categoria
join ventas v     on dv.id_venta    = v.id_venta
where v.estado = 'completada'
group by p.id_producto, p.nombre, c.nombre
order by total_unidades_vendidas desc
limit 10;

-- m3. rotacion mensual por producto (rqf-17)
select p.nombre,
       month(v.fecha_venta) as mes,
       sum(dv.cantidad)     as unidades_vendidas,
       avg(dv.cantidad)     as promedio_diario_unidades
from detalle_venta dv
join productos p on dv.id_producto = p.id_producto
join ventas v    on dv.id_venta    = v.id_venta
where v.estado = 'completada'
group by p.id_producto, p.nombre, month(v.fecha_venta)
order by mes, unidades_vendidas desc;

-- m4. pedidos con detalle de productos y proveedor
select pd.id_pedido, pv.nombre as proveedor,
       pr.nombre as producto,
       dp.cantidad, dp.precio_unitario, dp.subtotal,
       pd.estado
from pedidos pd
join proveedores pv    on pd.id_proveedor = pv.id_proveedor
join detalle_pedido dp on dp.id_pedido    = pd.id_pedido
join productos pr      on dp.id_producto  = pr.id_producto
order by pd.id_pedido, pr.nombre;

-- s1. productos con ventas superiores al promedio general
select p.nombre, sum(dv.cantidad) as total_vendido
from detalle_venta dv
join productos p on dv.id_producto = p.id_producto
group by p.id_producto, p.nombre
having sum(dv.cantidad) > (
    select avg(total_x_prod) from (
        select sum(cantidad) as total_x_prod
        from detalle_venta
        group by id_producto
    ) as subq
)
order by total_vendido desc;

-- s2. categorias cuyo ingreso supera el promedio por categoria (rqf-28 kpi)
select c.nombre as categoria, sum(dv.subtotal) as ingresos_categoria
from detalle_venta dv
join productos p  on dv.id_producto = p.id_producto
join categorias c on p.id_categoria = c.id_categoria
group by c.id_categoria, c.nombre
having sum(dv.subtotal) > (
    select avg(ingreso_cat) from (
        select sum(dv2.subtotal) as ingreso_cat
        from detalle_venta dv2
        join productos p2 on dv2.id_producto = p2.id_producto
        group by p2.id_categoria
    ) as subq2
)
order by ingresos_categoria desc;

-- s3. cantidad sugerida de pedido basada en historico de ventas (rqf-19)
select p.nombre as producto,
       p.stock_actual,
       p.stock_minimo,
       coalesce(round(avg(ventas_mes.total_mes) * 1.2), 0) as cantidad_sugerida_pedido
from productos p
left join (
    select dv.id_producto,
           month(v.fecha_venta) as mes,
           sum(dv.cantidad)     as total_mes
    from detalle_venta dv
    join ventas v on dv.id_venta = v.id_venta
    where v.estado = 'completada'
    group by dv.id_producto, month(v.fecha_venta)
) as ventas_mes on p.id_producto = ventas_mes.id_producto
where p.activo = 1
group by p.id_producto, p.nombre, p.stock_actual, p.stock_minimo
order by cantidad_sugerida_pedido desc;

-- mod1. actualizar precio de venta de gaseosa cola 1.5l
update productos
set precio_venta = 3800
where nombre = 'gaseosa cola 1.5l';

-- mod2. aumentar stock al recibir pedido de cervezas
update productos
set stock_actual = stock_actual + 50
where nombre = 'cerveza club colombia 330ml';

-- mod3. desactivar producto descontinuado
update productos
set activo = 0
where nombre = 'paleta bon ice 80ml';

-- mod4. actualizar contacto del proveedor bavaria
update proveedores
set telefono = '3001112244',
    email    = 'nuevacontacto@bavaria.com.co'
where nombre = 'bavaria s.a.';

-- mod5. anular venta duplicada
update ventas
set estado        = 'anulada',
    observaciones = 'venta duplicada por error del sistema'
where id_venta = 5;

-- eliminacion: borrar devolucion registrada por error
delete from devoluciones where id_devolucion = 5;

delimiter //

-- sp1: registrar venta completa con descuento automatico de inventario
create procedure sp_registrar_venta(
    in  p_id_usuario  int,
    in  p_id_producto int,
    in  p_cantidad    int,
    out p_id_venta    int,
    out p_mensaje     varchar(200)
)
begin
    declare v_stock    int;
    declare v_precio   decimal(10,2);
    declare v_subtotal decimal(12,2);

    declare exit handler for sqlexception
    begin
        rollback;
        set p_id_venta = -1;
        set p_mensaje  = 'error: transaccion revertida por fallo interno.';
    end;

    select stock_actual, precio_venta
    into   v_stock, v_precio
    from   productos
    where  id_producto = p_id_producto and activo = 1;

    if v_stock is null then
        set p_id_venta = 0;
        set p_mensaje  = 'error: producto no encontrado o inactivo.';
    elseif v_stock < p_cantidad then
        set p_id_venta = 0;
        set p_mensaje  = concat('error: stock insuficiente. disponible: ', v_stock, ' unidades.');
    else
        start transaction;

        set v_subtotal = v_precio * p_cantidad;

        insert into ventas (id_usuario, total)
        values (p_id_usuario, v_subtotal);
        set p_id_venta = last_insert_id();

        insert into detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
        values (p_id_venta, p_id_producto, p_cantidad, v_precio);

        update productos
        set stock_actual = stock_actual - p_cantidad
        where id_producto = p_id_producto;

        commit;
        set p_mensaje = concat('venta #', p_id_venta, ' registrada por $', v_subtotal);
    end if;
end //

-- sp2: recibir pedido y actualizar inventario automaticamente
create procedure sp_recibir_pedido(
    in  p_id_pedido int,
    out p_mensaje   varchar(200)
)
begin
    declare v_estado  varchar(20);
    declare done      int default 0;
    declare v_id_prod int;
    declare v_cant    int;

    declare cur_detalle cursor for
        select id_producto, cantidad
        from detalle_pedido
        where id_pedido = p_id_pedido;

    declare continue handler for not found set done = 1;
    declare exit handler for sqlexception
    begin
        rollback;
        set p_mensaje = 'error: no se pudo procesar el pedido.';
    end;

    select estado into v_estado from pedidos where id_pedido = p_id_pedido;

    if v_estado is null then
        set p_mensaje = 'error: pedido no encontrado.';
    elseif v_estado != 'pendiente' then
        set p_mensaje = concat('error: el pedido ya esta en estado: ', v_estado);
    else
        start transaction;

        update pedidos set estado = 'recibido' where id_pedido = p_id_pedido;

        open cur_detalle;
        loop_detalle: loop
            fetch cur_detalle into v_id_prod, v_cant;
            if done then leave loop_detalle; end if;
            update productos
            set stock_actual = stock_actual + v_cant
            where id_producto = v_id_prod;
        end loop;
        close cur_detalle;

        commit;
        set p_mensaje = concat('pedido #', p_id_pedido, ' recibido. inventario actualizado.');
    end if;
end //

-- sp3: reporte kpi de ventas por rango de fechas
create procedure sp_reporte_ventas(
    in p_fecha_inicio date,
    in p_fecha_fin    date
)
begin
    select date(v.fecha_venta)  as fecha,
           count(v.id_venta)    as num_ventas,
           sum(v.total)         as total_dia,
           avg(v.total)         as ticket_promedio,
           max(v.total)         as venta_maxima
    from ventas v
    where date(v.fecha_venta) between p_fecha_inicio and p_fecha_fin
      and v.estado = 'completada'
    group by date(v.fecha_venta)
    order by fecha;
end //

delimiter ;

-- invocaciones de prueba
call sp_registrar_venta(2, 1, 3, @nueva_venta, @msg_venta);
select @nueva_venta as id_venta_creado, @msg_venta as mensaje;

call sp_recibir_pedido(9, @msg_pedido);
select @msg_pedido as resultado_pedido;

call sp_reporte_ventas('2025-01-01', '2025-03-31');

delimiter //

-- trigger 1: registrar cambio de precios en historial (rqf-31, rqf-29)
create trigger trg_historial_precios
before update on productos
for each row
begin
    if old.precio_compra != new.precio_compra
    or old.precio_venta  != new.precio_venta then
        insert into historial_precios (
            id_producto,
            precio_compra_anterior, precio_venta_anterior,
            precio_compra_nuevo,    precio_venta_nuevo,
            fecha_cambio
        ) values (
            old.id_producto,
            old.precio_compra, old.precio_venta,
            new.precio_compra, new.precio_venta,
            now()
        );
    end if;
end //

-- trigger 2: auditar eliminaciones en tabla devoluciones (rqf-29)
create trigger trg_auditoria_devoluciones
before delete on devoluciones
for each row
begin
    insert into auditoria_movimientos (
        tabla_afectada, id_registro, tipo_operacion,
        descripcion, fecha_operacion
    ) values (
        'devoluciones',
        old.id_devolucion,
        'delete',
        concat('devolucion eliminada. venta #', old.id_venta,
               ' producto #', old.id_producto,
               ' cant: ', old.cantidad),
        now()
    );
end //

-- trigger 3: recalcular total de venta al insertar linea de detalle
create trigger trg_actualizar_total_venta
after insert on detalle_venta
for each row
begin
    update ventas
    set total = (
        select sum(subtotal)
        from detalle_venta
        where id_venta = new.id_venta
    )
    where id_venta = new.id_venta;
end //

delimiter ;

-- vista 1: inventario actual con alertas de stock y vencimiento
create or replace view v_inventario_alertas as
select
    p.id_producto,
    p.nombre          as producto,
    c.nombre          as categoria,
    pv.nombre         as proveedor,
    p.stock_actual,
    p.stock_minimo,
    p.precio_compra,
    p.precio_venta,
    (p.precio_venta - p.precio_compra)       as margen,
    p.fecha_vencimiento,
    datediff(p.fecha_vencimiento, curdate())  as dias_para_vencer,
    case when p.stock_actual <= p.stock_minimo
         then 'stock bajo' else 'ok'
    end as alerta_stock,
    case
        when p.fecha_vencimiento is not null
             and datediff(p.fecha_vencimiento, curdate()) <= 0   then 'vencido'
        when p.fecha_vencimiento is not null
             and datediff(p.fecha_vencimiento, curdate()) <= 15  then 'vence pronto'
        else 'ok'
    end as alerta_vencimiento
from productos p
join categorias  c  on p.id_categoria = c.id_categoria
join proveedores pv on p.id_proveedor = pv.id_proveedor
where p.activo = 1;

-- vista 2: resumen de ventas por producto para bi (rqf-13, rqf-14, rqf-27)
create or replace view v_ventas_por_producto as
select
    p.id_producto,
    p.nombre                    as producto,
    c.nombre                    as categoria,
    sum(dv.cantidad)            as total_unidades,
    sum(dv.subtotal)            as total_ingresos,
    avg(dv.precio_unitario)     as precio_promedio,
    count(distinct dv.id_venta) as num_transacciones
from detalle_venta dv
join productos p  on dv.id_producto = p.id_producto
join categorias c on p.id_categoria = c.id_categoria
join ventas v     on dv.id_venta    = v.id_venta
where v.estado = 'completada'
group by p.id_producto, p.nombre, c.nombre;

-- vista 3: kpis mensuales para power bi (rqf-28, rqf-27)
create or replace view v_kpi_mensual as
select
    year(fecha_venta)  as anio,
    month(fecha_venta) as mes,
    count(*)           as total_ventas,
    sum(total)         as ingresos_totales,
    avg(total)         as ticket_promedio,
    max(total)         as venta_maxima,
    min(total)         as venta_minima
from ventas
where estado = 'completada'
group by year(fecha_venta), month(fecha_venta);

-- vista 4: productos sugeridos para reorden (rqf-19)
create or replace view v_sugerencia_pedidos as
select
    p.id_producto,
    p.nombre          as producto,
    pv.nombre         as proveedor,
    pv.telefono       as contacto_proveedor,
    p.stock_actual,
    p.stock_minimo,
    (p.stock_minimo - p.stock_actual) as deficit,
    case
        when p.stock_actual <= p.stock_minimo         then 'pedir urgente'
        when p.stock_actual <= (p.stock_minimo * 1.5) then 'pedir pronto'
        else                                               'stock suficiente'
    end as recomendacion
from productos p
join proveedores pv on p.id_proveedor = pv.id_proveedor
where p.activo = 1
order by deficit desc;

-- consultas de verificacion sobre las vistas
select * from v_inventario_alertas
where alerta_stock = 'stock bajo' or alerta_vencimiento = 'vence pronto';

select * from v_ventas_por_producto order by total_ingresos desc limit 10;
select * from v_kpi_mensual         order by anio, mes;
select * from v_sugerencia_pedidos  where recomendacion != 'stock suficiente';
