drop database if exists tienda_don_pepe;
create database tienda_don_pepe;
use tienda_don_pepe;

-- tabla: categorias
create table categorias (
    id_categoria int          auto_increment primary key,
    nombre       varchar(50)  not null,
    descripcion  varchar(100),
    constraint uq_cat_nombre unique (nombre)
);

-- tabla: proveedores
create table proveedores (
    id_proveedor   int          auto_increment primary key,
    nombre         varchar(80)  not null,
    contacto       varchar(80),
    telefono       varchar(20)  not null,
    email          varchar(80),
    ciudad         varchar(50)  default 'bogota',
    activo         tinyint(1)   default 1,
    fecha_registro date         default (current_date)
);

-- tabla: usuarios
create table usuarios (
    id_usuario     int          auto_increment primary key,
    nombre         varchar(80)  not null,
    email          varchar(80)  not null unique,
    clave_hash     varchar(255) not null,
    rol            enum('admin','empleado','dueno') not null default 'empleado',
    activo         tinyint(1)   default 1,
    fecha_registro datetime     default now()
);

-- tabla: productos
-- stock_minimo default 5 segun diccionario del entregable 2
create table productos (
    id_producto       int           auto_increment primary key,
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

-- tabla: ventas
create table ventas (
    id_venta      int           auto_increment primary key,
    id_usuario    int           not null,
    fecha_venta   datetime      default now(),
    total         decimal(12,2) default 0.00,
    estado        enum('completada','anulada') default 'completada',
    observaciones varchar(200),
    constraint fk_venta_usuario foreign key (id_usuario) references usuarios(id_usuario)
);

-- tabla: detalle_venta (resuelve relacion n:m entre ventas y productos)
create table detalle_venta (
    id_detalle      int           auto_increment primary key,
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
    id_pedido      int           auto_increment primary key,
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
    id_detalle      int           auto_increment primary key,
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
    id_historial           int           auto_increment primary key,
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
    id_auditoria    int          auto_increment primary key,
    tabla_afectada  varchar(50)  not null,
    id_registro     int          not null,
    tipo_operacion  enum('insert','update','delete') not null,
    descripcion     varchar(255),
    id_usuario      int,
    fecha_operacion datetime     default now()
);

-- tabla: devoluciones (rqf-34)
create table devoluciones (
    id_devolucion    int          auto_increment primary key,
    id_venta         int          not null,
    id_producto      int          not null,
    cantidad         int          not null,
    motivo           varchar(200),
    fecha_devolucion datetime     default now(),
    id_usuario       int          not null,
    constraint fk_dev_venta    foreign key (id_venta)    references ventas(id_venta),
    constraint fk_dev_producto foreign key (id_producto) references productos(id_producto)
);

#3
-- categorias (10 registros)
insert into categorias (nombre, descripcion) values
('gaseosas',           'coca-cola, sprite, quatro, kola roman y schweppes'),
('aguas',              'agua brisa y agua manantial en todas sus presentaciones'),
('jugos',              'jugos del valle fresh y del valle frutal'),
('energeticas',        'monster energy en todas sus variedades'),
('te y bebidas',       'fuze tea en todas sus presentaciones'),
('hidratantes',        'powerade y flashlyte'),
('gaseosas sin azucar','linea zero: coca-cola zero, sprite zero, quatro zero'),
('packs y combos',     'presentaciones multiunidad y combos promocionales'),
('bebidas vegetales',  'ades de soya, almendra y derivados'),
('latas',              'presentaciones en lata: coca-cola lata, monster lata');

-- proveedores (1 registro - unico proveedor real del excel)
insert into proveedores (nombre, contacto, telefono, email, ciudad) values
('femsa coca-cola colombia', '[nombre_eliminado]', '3001000001', 'pedidos@coca-cola.com.co', 'bogota');

-- usuarios (5 registros)
insert into usuarios (nombre, email, clave_hash, rol) values
('don pepe rodriguez', 'donpepe@tienda.com', '$2b$10$hash_dueno_1', 'dueno'),
('empleado-1',         'emp1@tienda.com',    '$2b$10$hash_emp_1',   'empleado'),
('empleado-2',         'emp2@tienda.com',    '$2b$10$hash_emp_2',   'empleado'),
('admin sistema',      'admin@tienda.com',   '$2b$10$hash_admin',   'admin'),
('empleado-3',         'emp3@tienda.com',    '$2b$10$hash_emp_3',   'empleado');

insert into productos
    (nombre, id_categoria, id_proveedor, precio_compra, precio_venta,
     stock_actual, stock_minimo, fecha_vencimiento, unidad_medida)
values
-- gaseosas coca-cola - clase a (mayor rotacion segun excel)
('gas. coca cola x 1.5 lt',             1, 1, 4324, 5087, 120,  5, '2025-12-31', 'bot'),
('gas. coca cola x 400 ml',             1, 1, 2304, 2711,  80,  5, '2025-12-31', 'bot'),
('gas. coca cola original x 2.5 lt',    1, 1, 6136, 7219,  60,  5, '2025-12-31', 'bot'),
('gas. coca cola mini x 250 ml',        1, 1, 1693, 1992, 100,  5, '2025-12-31', 'bot'),
('gas. coca cola x 600 ml',             1, 1, 2854, 3358,  75,  5, '2025-12-31', 'bot'),
('gas. coca cola x 1 lt',               1, 1, 3271, 3849,  50,  5, '2025-12-31', 'bot'),
-- gaseosas zero - clase a
('gas. coca cola s/azucar x 1.5 lts',   7, 1, 4160, 4894,  70,  5, '2025-12-31', 'bot'),
('gas. coca cola zero mini x 250 ml',   7, 1, 1153, 1356,  90,  5, '2025-12-31', 'bot'),
('gas. coca cola zero x 400 ml',        7, 1, 2344, 2758,  65,  5, '2025-12-31', 'bot'),
('gas. coca cola s/azucar x 2.5 lts',  7, 1, 6117, 7197,  40,  5, '2025-12-31', 'bot'),
-- aguas brisa y manantial - clase a
('agua brisa litro bot',                2, 1, 1558, 1833, 200,  5, '2026-06-30', 'bot'),
('agua brisa bidon x 6 litros',         2, 1, 6298, 7409,  80,  5, '2026-06-30', 'und'),
('agua brisa bot x 600 ml',             2, 1, 1395, 1641, 150,  5, '2026-06-30', 'bot'),
('agua brisa manzana bot x 1.5 lt',     2, 1, 3205, 3770,  55,  5, '2026-06-30', 'bot'),
('agua brisa maracuya bot x 1.5 lt',    2, 1, 3358, 3951,  45,  5, '2026-06-30', 'bot'),
-- gaseosas quatro y sprite - clase a
('gas. quatro toron x 1.5 ml',          1, 1, 3564, 4193,  50,  5, '2025-12-31', 'bot'),
('gas. quatro toron x 400 ml',          1, 1, 2125, 2500,  60,  5, '2025-12-31', 'bot'),
('gas. sprite x 1.5ml',                 1, 1, 3776, 4443,  50,  5, '2025-12-31', 'bot'),
('gas. kola roman x 400ml',             1, 1, 2000, 2353,  55,  5, '2025-12-31', 'bot'),
-- jugos del valle - clase a
('jg. del valle fresh naranja x1.5 m',  3, 1, 3403, 4004,  45,  5, '2025-10-31', 'bot'),
('jg. del valle fresh citrus x 400 ml', 3, 1, 1606, 1889,  60,  5, '2025-10-31', 'bot'),
('jg. del valle fresh fru/citri x 2.5', 3, 1, 4742, 5579,  35,  5, '2025-10-31', 'bot'),
-- gaseosas - clase b
('gas. sprite x 400 ml',                1, 1, 2040, 2400,  55,  5, '2025-12-31', 'bot'),
('gas. schweppes ginger x 1.5 lt',      1, 1, 3826, 4501,  40,  5, '2025-12-31', 'bot'),
('gas. kola roman x 1.5 lts',           1, 1, 3139, 3693,  45,  5, '2025-12-31', 'bot'),
('gas. coca cola lata x 330 ml',       10, 1, 3272, 3850,  70,  5, '2025-12-31', 'und'),
('gas. quatro s/azucar x 1.5 lt',       7, 1, 3272, 3850,  35,  5, '2025-12-31', 'bot'),
('gas. schweppes soda 1.5 ml',          1, 1, 3442, 4050,  40,  5, '2025-12-31', 'bot'),
('gas. quatro toronj x 3 lts',          1, 1, 5969, 7023,  30,  5, '2025-12-31', 'bot'),
('gas. schweppes ginger ale x 400 ml',  1, 1, 2202, 2591,  45,  5, '2025-12-31', 'bot'),
-- aguas - clase b
('agua manantial bot x 600 ml',         2, 1, 2295, 2700,  80,  5, '2026-06-30', 'bot'),
('agua brisa manzana x 600 ml',         2, 1, 2320, 2730,  60,  5, '2026-06-30', 'bot'),
('agua brisa x 600 ml con gas',         2, 1, 1360, 1599,  75,  5, '2026-06-30', 'bot'),
('agua brisa maracuya x 600 ml',        2, 1, 2185, 2571,  50,  5, '2026-06-30', 'bot'),
('agua brisa bot limon x 600 ml',       2, 1, 2340, 2753,  55,  5, '2026-06-30', 'bot'),
-- jugos del valle - clase b
('jg. del valle mandarina x 1.5 l',     3, 1, 3612, 4250,  40,  5, '2025-10-31', 'bot'),
('jg. del valle mandarina x 400ml',     3, 1, 1615, 1900,  55,  5, '2025-10-31', 'bot'),
('jg. del valle mandarina x 2.5 l',     3, 1, 4802, 5650,  30,  5, '2025-10-31', 'bot'),
-- energeticas - clase b
('beb. monster mango ltx473ml',         4, 1, 6715, 7900,  35,  5, '2025-12-31', 'und'),
('gas. sprite x 3 lts',                 1, 1, 6134, 7217,  25,  5, '2025-12-31', 'bot'),
-- gaseosas - clase c
('gas. coca cola zero lata 330 ml',    10, 1, 2775, 3265,  40,  5, '2025-12-31', 'und'),
('gas. sprite s/azucar x 1.5 lt',      7, 1, 3272, 3850,  30,  5, '2025-12-31', 'bot'),
('gas. kola roman s/azucar x 1.5lt',   7, 1, 3187, 3750,  25,  5, '2025-12-31', 'bot'),
-- aguas - clase c
('agua brisa limon bot x 1.5 lt',       2, 1, 3400, 4000,  30,  5, '2026-06-30', 'bot'),
('agua manantial bot x 500 ml',         2, 1, 2465, 2900,  40,  5, '2026-06-30', 'bot'),
-- energeticas - clase c
('beb. monster verde ltx473 ml',        4, 1, 7055, 8300,  25,  5, '2025-12-31', 'und'),
('beb. monster ultra ltx473ml',         4, 1, 6715, 7900,  20,  5, '2025-12-31', 'und'),
-- te - clase c
('beb. fuze tea negro durazno 400 ml',  5, 1, 2690, 3165,  35,  5, '2025-12-31', 'bot'),
('beb. fuze tea negro limon 400ml',     5, 1, 2741, 3225,  30,  5, '2025-12-31', 'bot'),
-- hidratantes - clase c
('beb. powerade frut/trop x 500 ml',    6, 1, 3060, 3600,  30,  5, '2025-12-31', 'bot');

insert into ventas (id_usuario, fecha_venta, total, estado) values
(2,'2025-01-05 08:15:00',  45800,'completada'),
(2,'2025-01-05 10:30:00',  23400,'completada'),
(3,'2025-01-06 09:00:00',  67200,'completada'),
(2,'2025-01-07 11:20:00',  18700,'completada'),
(3,'2025-01-08 14:00:00',  89500,'completada'),
(2,'2025-01-09 08:45:00',  34200,'completada'),
(5,'2025-01-10 09:00:00', 112000,'completada'),
(3,'2025-01-11 10:30:00',  29400,'completada'),
(2,'2025-01-12 11:00:00',  58700,'completada'),
(5,'2025-01-13 14:30:00',  41200,'completada'),
(3,'2025-01-15 08:00:00',  95300,'completada'),
(2,'2025-01-16 09:15:00',  47600,'completada'),
(5,'2025-01-17 10:45:00',  33800,'completada'),
(2,'2025-01-18 11:30:00', 128000,'completada'),
(3,'2025-01-20 14:00:00',  72400,'completada'),
(2,'2025-01-22 08:30:00',  85900,'completada'),
(5,'2025-01-24 09:00:00',  26700,'completada'),
(3,'2025-01-25 10:15:00',  63200,'completada'),
(2,'2025-01-27 11:45:00',  44100,'completada'),
(3,'2025-01-29 14:00:00', 135000,'completada'),
(2,'2025-02-01 08:00:00',  39400,'completada'),
(5,'2025-02-02 09:30:00',  57800,'completada'),
(3,'2025-02-03 10:00:00',  91200,'completada'),
(2,'2025-02-05 11:15:00',  22300,'completada'),
(3,'2025-02-06 14:30:00', 114000,'completada'),
(5,'2025-02-07 08:45:00',  68500,'completada'),
(2,'2025-02-08 09:00:00',  37600,'completada'),
(3,'2025-02-10 10:30:00',  98700,'completada'),
(2,'2025-02-11 11:00:00',  31400,'completada'),
(5,'2025-02-12 14:00:00', 142000,'completada'),
(3,'2025-02-14 08:15:00', 107000,'completada'),
(2,'2025-02-15 09:45:00',  73200,'completada'),
(5,'2025-02-17 10:00:00',  49800,'completada'),
(3,'2025-02-18 11:30:00',  86300,'completada'),
(2,'2025-02-20 14:15:00',  61700,'completada'),
(5,'2025-02-22 08:00:00', 124000,'completada'),
(3,'2025-02-24 09:15:00',  38900,'completada'),
(2,'2025-02-25 10:45:00',  79400,'completada'),
(5,'2025-02-27 11:00:00',  55200,'completada'),
(3,'2025-02-28 14:30:00', 158000,'completada'),
(2,'2025-03-01 08:30:00',  47300,'completada'),
(3,'2025-03-03 09:00:00',  93600,'completada'),
(5,'2025-03-04 10:15:00',  71400,'completada'),
(2,'2025-03-05 11:45:00',  28900,'completada'),
(3,'2025-03-06 14:00:00', 118000,'completada'),
(5,'2025-03-07 08:00:00',  54700,'completada'),
(2,'2025-03-08 09:30:00', 102000,'completada'),
(3,'2025-03-10 10:00:00',  42500,'completada'),
(5,'2025-03-11 11:15:00', 136000,'completada'),
(2,'2025-03-12 14:45:00',  77800,'completada'),
(3,'2025-03-13 08:30:00',  63400,'completada'),
(5,'2025-03-14 09:00:00', 109000,'completada'),
(2,'2025-03-15 10:30:00',  48200,'completada'),
(3,'2025-03-17 11:00:00',  89700,'completada'),
(5,'2025-03-18 14:15:00',  61500,'completada'),
(2,'2025-03-20 08:45:00', 151000,'completada'),
(3,'2025-03-22 09:15:00',  34600,'completada'),
(5,'2025-03-24 10:45:00', 105000,'completada'),
(2,'2025-03-26 11:30:00',  78300,'completada'),
(3,'2025-03-28 14:00:00',  66900,'completada');

insert into detalle_venta (id_venta, id_producto, cantidad, precio_unitario) values
(1,  1,  4, 5087),(1, 11,  6, 1833),(1, 13,  3, 1641),
(2,  2,  5, 2711),(2, 23,  3, 2400),
(3,  1,  8, 5087),(3, 12,  2, 7409),(3, 20,  3, 4004),
(4, 11,  6, 1833),(4, 13,  4, 1641),
(5,  1, 10, 5087),(5, 26,  5, 3850),(5, 12,  3, 7409),
(6,  2,  4, 2711),(6, 11,  8, 1833),
(7,  1, 12, 5087),(7, 12,  4, 7409),(7,  2,  6, 2711),
(8, 11,  5, 1833),(8, 13,  6, 1641),(8, 23,  4, 2400),
(9,  1,  6, 5087),(9, 12,  3, 7409),(9, 11,  8, 1833),
(10,13,  8, 1641),(10,11,  6, 1833),(10,20,  4, 4004),
(11, 1, 10, 5087),(11,26,  6, 3850),(11,12,  4, 7409),
(12,11,  8, 1833),(12,12,  3, 7409),(12, 2,  5, 2711),
(13,13,  6, 1641),(13,23,  5, 2400),(13,20,  3, 4004),
(14, 1, 12, 5087),(14, 2,  8, 2711),(14,26,  6, 3850),(14,12, 4, 7409),
(15,11,  6, 1833),(15,13,  8, 1641),(15,12,  3, 7409);

-- pedidos a femsa coca-cola (10 registros)
insert into pedidos (id_proveedor, id_usuario, fecha_pedido, fecha_entrega, total, estado) values
(1, 1,'2025-01-08','2025-01-10',  980000,'recibido'),
(1, 1,'2025-01-20','2025-01-22', 1250000,'recibido'),
(1, 4,'2025-02-03','2025-02-05',  875000,'recibido'),
(1, 1,'2025-02-15','2025-02-17', 1540000,'recibido'),
(1, 1,'2025-02-25','2025-02-27',  760000,'recibido'),
(1, 4,'2025-03-05','2025-03-07', 1120000,'recibido'),
(1, 1,'2025-03-15','2025-03-17',  930000,'recibido'),
(1, 4,'2025-03-22','2025-03-24', 1380000,'recibido'),
(1, 1,'2025-04-01','2025-04-03', 1680000,'pendiente'),
(1, 4,'2025-04-10','2025-04-12',  820000,'pendiente');

-- detalle de pedidos 
insert into detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) values
(1,  1, 120, 4324),(1, 11, 200, 1558),(1, 13, 150, 1395),
(2,  1, 150, 4324),(2, 12,  60, 6298),(2,  2, 100, 2304),
(3, 11, 180, 1558),(3, 12,  50, 6298),(3, 20,  60, 3403),
(4,  1, 200, 4324),(4, 26,  80, 3272),(4, 23, 100, 2040),
(5, 13, 200, 1395),(5, 11, 150, 1558),(5,  2,  80, 2304),
(6,  1, 160, 4324),(6, 12,  70, 6298),(6, 23,  90, 2040),
(7, 11, 200, 1558),(7, 13, 180, 1395),(7, 20,  50, 3403),
(8,  1, 180, 4324),(8, 12,  80, 6298),(8, 26,  60, 3272),
(9,  1, 240, 4324),(9, 11, 300, 1558),(9, 12,  90, 6298),
(10,13, 200, 1395),(10, 2, 120, 2304),(10,23,  80, 2040);

-- devoluciones (5 registros)
insert into devoluciones (id_venta, id_producto, cantidad, motivo, id_usuario) values
(3,  12, 1, 'bidon con fuga',                    2),
(7,  26, 2, 'lata abollada',                     3),
(14,  1, 1, 'botella sin sello de seguridad',    5),
(20, 11, 2, 'producto vencido',                  2),
(25, 13, 1, 'botella golpeada',                  3);

#4
select * from categorias;
select * from proveedores;
select * from usuarios;
select * from productos;
select * from ventas;
select * from detalle_venta;
select * from pedidos;
select * from detalle_pedido;
select * from devoluciones;

#5
-- e1. productos con stock bajo (rqf-15)
select p.nombre, p.stock_actual, p.stock_minimo,
       (p.stock_minimo - p.stock_actual) as unidades_faltantes
from productos p
where p.stock_actual <= p.stock_minimo and p.activo = 1
order by unidades_faltantes desc;

-- e2. productos proximos a vencer en 30 dias (rqf-16)
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

-- e6. clasificacion abc de productos (rqf-32)
select nombre, precio_venta,
       case
           when precio_venta >= 6000               then 'a - alto valor'
           when precio_venta between 3000 and 5999  then 'b - valor medio'
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

-- e9. ventas por mes (rqf-35)
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

-- e12. pedidos por estado
select p.estado,
       count(*) as num_pedidos,
       sum(p.total) as total_compras
from pedidos p
group by p.estado
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

#6
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
       avg(dv.cantidad)     as promedio_por_venta
from detalle_venta dv
join productos p on dv.id_producto = p.id_producto
join ventas v    on dv.id_venta    = v.id_venta
where v.estado = 'completada'
group by p.id_producto, p.nombre, month(v.fecha_venta)
order by mes, unidades_vendidas desc;

-- m4. pedidos con detalle de productos
select pd.id_pedido, pv.nombre as proveedor,
       pr.nombre as producto,
       dp.cantidad, dp.precio_unitario, dp.subtotal,
       pd.estado
from pedidos pd
join proveedores pv    on pd.id_proveedor = pv.id_proveedor
join detalle_pedido dp on dp.id_pedido    = pd.id_pedido
join productos pr      on dp.id_producto  = pr.id_producto
order by pd.id_pedido, pr.nombre;

#7
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

-- s3. cantidad sugerida de pedido basada en historico (rqf-19)
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

#8
-- mod1. actualizar precio del bidon (variacion real detectada en excel)
update productos
set precio_venta = 7650
where nombre = 'agua brisa bidon x 6 litros';

-- mod2. aumentar stock al recibir pedido de coca-cola 1.5lt
update productos
set stock_actual = stock_actual + 120
where nombre = 'gas. coca cola x 1.5 lt';

-- mod3. desactivar producto sin ventas en 2025 segun excel
update productos
set activo = 0
where nombre = 'agua brisa limon bot x 1.5 lt';

-- mod4. actualizar email del proveedor
update proveedores
set email = 'nuevopedidos@coca-cola.com.co'
where nombre = 'femsa coca-cola colombia';

-- mod5. anular venta duplicada
update ventas
set estado        = 'anulada',
    observaciones = 'venta duplicada por error del sistema'
where id_venta = 5;

-- eliminacion: borrar devolucion registrada por error
delete from devoluciones where id_devolucion = 5;

#9
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
call sp_registrar_venta(2, 1, 5, @nueva_venta, @msg_venta);
select @nueva_venta as id_venta_creado, @msg_venta as mensaje;

call sp_recibir_pedido(9, @msg_pedido);
select @msg_pedido as resultado_pedido;

call sp_reporte_ventas('2025-01-01', '2025-03-31');

#10
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

-- trigger 2: auditar eliminaciones en devoluciones (rqf-29)
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

#11
-- vista 1: inventario con alertas de stock y vencimiento (rqf-15, rqf-16, rqf-24)
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
    (p.precio_venta - p.precio_compra)      as margen,
    p.fecha_vencimiento,
    datediff(p.fecha_vencimiento, curdate()) as dias_para_vencer,
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
