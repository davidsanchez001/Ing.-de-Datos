#Conceptual ER
select
    'categorias'             as entidad,
    'id_categoria'           as identificador,
    'agrupa los productos del portafolio femsa por tipo de bebida'
                             as descripcion_negocio
union all select
    'proveedores',
    'id_proveedor',
    'empresa que suministra los productos (femsa coca-cola colombia)'
union all select
    'usuarios',
    'id_usuario',
    'personas con acceso al sistema, identificadas por rol'
union all select
    'productos',
    'id_producto',
    'bebidas del portafolio femsa con precio, stock y vencimiento'
union all select
    'ventas',
    'id_venta',
    'transacciones de venta registradas por un usuario en la tienda'
union all select
    'detalle_venta',
    'id_detalle',
    'lineas de producto dentro de cada venta (resuelve n:m venta-producto)'
union all select
    'pedidos',
    'id_pedido',
    'ordenes de compra emitidas al proveedor femsa'
union all select
    'detalle_pedido',
    'id_detalle',
    'lineas de producto dentro de cada pedido (resuelve n:m pedido-producto)'
union all select
    'historial_precios',
    'id_historial',
    'registro de cada cambio de precio por producto'
union all select
    'auditoria_movimientos',
    'id_auditoria',
    'log de operaciones criticas realizadas sobre el sistema'
union all select
    'devoluciones',
    'id_devolucion',
    'registro de productos devueltos asociados a una venta';

#1.2 atributos clave por entidad
select
    'categorias'  as entidad,
    'nombre, descripcion'
                  as atributos_clave
union all select
    'proveedores',
    'nombre, contacto, telefono, email, ciudad'
union all select
    'usuarios',
    'nombre, email, rol (dueno / admin / empleado)'
union all select
    'productos',
    'nombre, precio_compra, precio_venta, stock_actual, stock_minimo, fecha_vencimiento'
union all select
    'ventas',
    'fecha_venta, total, estado (completada / anulada)'
union all select
    'detalle_venta',
    'cantidad, precio_unitario, subtotal'
union all select
    'pedidos',
    'fecha_pedido, fecha_entrega, total, estado (pendiente / recibido / cancelado)'
union all select
    'detalle_pedido',
    'cantidad, precio_unitario, subtotal'
union all select
    'historial_precios',
    'precio_compra_anterior, precio_venta_anterior, precio_compra_nuevo, precio_venta_nuevo, fecha_cambio'
union all select
    'auditoria_movimientos',
    'tabla_afectada, tipo_operacion (insert / update / delete), descripcion, fecha_operacion'
union all select
    'devoluciones',
    'cantidad, motivo, fecha_devolucion';

#1.3 relaciones del modelo conceptual con cardinalidades
select
    'categorias'    as entidad_origen,
    '1'             as cardinalidad_origen,
    'N'             as cardinalidad_destino,
    'productos'     as entidad_destino,
    'una categoria agrupa muchos productos del portafolio'
                    as regla_de_negocio
union all select
    'proveedores', '1', 'N', 'productos',
    'femsa suministra todos los productos de la tienda'
union all select
    'proveedores', '1', 'N', 'pedidos',
    'femsa recibe multiples ordenes de compra de la tienda'
union all select
    'usuarios', '1', 'N', 'ventas',
    'un usuario (empleado/dueno) registra muchas ventas'
union all select
    'usuarios', '1', 'N', 'pedidos',
    'un usuario genera muchas ordenes de compra'
union all select
    'ventas', '1', 'N', 'detalle_venta',
    'una venta incluye una o varias lineas de producto'
union all select
    'productos', '1', 'N', 'detalle_venta',
    'un producto puede aparecer en muchas lineas de venta'
union all select
    'pedidos', '1', 'N', 'detalle_pedido',
    'un pedido incluye uno o varios productos solicitados'
union all select
    'productos', '1', 'N', 'detalle_pedido',
    'un producto puede estar en muchas lineas de pedido'
union all select
    'productos', '1', 'N', 'historial_precios',
    'un producto acumula multiples cambios de precio en el tiempo'
union all select
    'ventas', '1', 'N', 'devoluciones',
    'una venta puede originar una o varias devoluciones'
union all select
    'productos', '1', 'N', 'devoluciones',
    'un producto puede ser devuelto en distintas ocasiones';

#MODELO LOGICO   
drop database if exists tienda_don_pepe;
create database tienda_don_pepe;
use tienda_don_pepe;

create table categorias (
    id_categoria int          auto_increment primary key,
    nombre       varchar(50)  not null,
    descripcion  varchar(100)
);

create table proveedores (
    id_proveedor   int         auto_increment primary key,
    nombre         varchar(80) not null,
    contacto       varchar(80),
    telefono       varchar(20) not null,
    email          varchar(80),
    ciudad         varchar(50),
    activo         tinyint(1),
    fecha_registro date
);

create table usuarios (
    id_usuario     int          auto_increment primary key,
    nombre         varchar(80)  not null,
    email          varchar(80)  not null,
    clave_hash     varchar(255) not null,
    rol            varchar(20)  not null,
    activo         tinyint(1),
    fecha_registro datetime
);

create table productos (
    id_producto       int           auto_increment primary key,
    nombre            varchar(80)   not null,
    id_categoria      int           not null,
    id_proveedor      int           not null,
    precio_compra     decimal(10,2) not null,
    precio_venta      decimal(10,2) not null,
    stock_actual      int           not null,
    stock_minimo      int           not null,
    fecha_vencimiento date,
    unidad_medida     varchar(20),
    activo            tinyint(1),
    fecha_registro    datetime,
    foreign key (id_categoria) references categorias(id_categoria),
    foreign key (id_proveedor) references proveedores(id_proveedor)
);

create table ventas (
    id_venta      int           auto_increment primary key,
    id_usuario    int           not null,
    fecha_venta   datetime,
    total         decimal(12,2),
    estado        varchar(20),
    observaciones varchar(200),
    foreign key (id_usuario) references usuarios(id_usuario)
);

create table detalle_venta (
    id_detalle      int           auto_increment primary key,
    id_venta        int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2),
    foreign key (id_venta)    references ventas(id_venta),
    foreign key (id_producto) references productos(id_producto)
);

create table pedidos (
    id_pedido      int           auto_increment primary key,
    id_proveedor   int           not null,
    id_usuario     int           not null,
    fecha_pedido   datetime,
    fecha_entrega  date,
    total          decimal(12,2),
    estado         varchar(20),
    observaciones  varchar(200),
    foreign key (id_proveedor) references proveedores(id_proveedor),
    foreign key (id_usuario)   references usuarios(id_usuario)
);

create table detalle_pedido (
    id_detalle      int           auto_increment primary key,
    id_pedido       int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2),
    foreign key (id_pedido)   references pedidos(id_pedido),
    foreign key (id_producto) references productos(id_producto)
);

create table historial_precios (
    id_historial           int           auto_increment primary key,
    id_producto            int           not null,
    precio_compra_anterior decimal(10,2),
    precio_venta_anterior  decimal(10,2),
    precio_compra_nuevo    decimal(10,2),
    precio_venta_nuevo     decimal(10,2),
    fecha_cambio           datetime,
    id_usuario             int,
    foreign key (id_producto) references productos(id_producto)
);

create table auditoria_movimientos (
    id_auditoria    int          auto_increment primary key,
    tabla_afectada  varchar(50)  not null,
    id_registro     int          not null,
    tipo_operacion  varchar(10)  not null,
    descripcion     varchar(255),
    id_usuario      int,
    fecha_operacion datetime
);

create table devoluciones (
    id_devolucion    int          auto_increment primary key,
    id_venta         int          not null,
    id_producto      int          not null,
    cantidad         int          not null,
    motivo           varchar(200),
    fecha_devolucion datetime,
    id_usuario       int          not null,
    foreign key (id_venta)    references ventas(id_venta),
    foreign key (id_producto) references productos(id_producto)
);

#2.2 visualizacion del modelo logico via information_schema
select
    table_name      as tabla,
    column_name     as campo,
    ordinal_position as posicion,
    column_type     as tipo_dato,
    is_nullable     as permite_nulo,
    column_key      as tipo_clave
from information_schema.columns
where table_schema = 'tienda_don_pepe'
order by table_name, ordinal_position;

-- claves primarias del modelo
select
    table_name  as tabla,
    column_name as clave_primaria
from information_schema.columns
where table_schema = 'tienda_don_pepe'
  and column_key   = 'pri'
order by table_name;

-- claves foraneas y sus referencias
select
    kcu.table_name              as tabla_origen,
    kcu.column_name             as campo_fk,
    kcu.referenced_table_name   as tabla_destino,
    kcu.referenced_column_name  as campo_pk_referenciado
from information_schema.key_column_usage kcu
where kcu.table_schema            = 'tienda_don_pepe'
  and kcu.referenced_table_name  is not null
order by kcu.table_name;

-- resumen: cuantos campos, pk y fk tiene cada tabla
select
    c.table_name                                            as tabla,
    count(c.column_name)                                    as total_campos,
    sum(case when c.column_key = 'pri' then 1 else 0 end)  as pk,
    sum(case when c.column_key = 'mul' then 1 else 0 end)  as fk
from information_schema.columns c
where c.table_schema = 'tienda_don_pepe'
group by c.table_name
order by c.table_name;

-- describe por tabla
describe categorias;
describe proveedores;
describe usuarios;
describe productos;
describe ventas;
describe detalle_venta;
describe pedidos;
describe detalle_pedido;
describe historial_precios;
describe auditoria_movimientos;
describe devoluciones;

#MODELO FISICO  
drop database if exists tienda_don_pepe;
create database tienda_don_pepe;
use tienda_don_pepe;

create table categorias (
    id_categoria int         auto_increment primary key,
    nombre       varchar(50) not null,
    descripcion  varchar(100),
    constraint uq_cat_nombre unique (nombre)
);

create table proveedores (
    id_proveedor   int         auto_increment primary key,
    nombre         varchar(80) not null,
    contacto       varchar(80),
    telefono       varchar(20) not null,
    email          varchar(80),
    ciudad         varchar(50) default 'bogota',
    activo         tinyint(1)  default 1,
    fecha_registro date        default (current_date)
);

create table usuarios (
    id_usuario     int          auto_increment primary key,
    nombre         varchar(80)  not null,
    email          varchar(80)  not null,
    clave_hash     varchar(255) not null,
    rol            enum('admin','empleado','dueno') not null default 'empleado',
    activo         tinyint(1)   default 1,
    fecha_registro datetime     default now(),
    constraint uq_email unique (email)
);

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
    constraint fk_prod_cat  foreign key (id_categoria)
        references categorias(id_categoria),
    constraint fk_prod_prov foreign key (id_proveedor)
        references proveedores(id_proveedor),
    constraint chk_precios  check (precio_venta >= precio_compra)
);

create table ventas (
    id_venta      int           auto_increment primary key,
    id_usuario    int           not null,
    fecha_venta   datetime      default now(),
    total         decimal(12,2) default 0.00,
    estado        enum('completada','anulada') default 'completada',
    observaciones varchar(200),
    constraint fk_venta_usuario foreign key (id_usuario)
        references usuarios(id_usuario)
);

create table detalle_venta (
    id_detalle      int           auto_increment primary key,
    id_venta        int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2) generated always as
                    (cantidad * precio_unitario) stored,
    constraint fk_dv_venta    foreign key (id_venta)
        references ventas(id_venta),
    constraint fk_dv_producto foreign key (id_producto)
        references productos(id_producto),
    constraint chk_cantidad   check (cantidad > 0)
);

create table pedidos (
    id_pedido      int           auto_increment primary key,
    id_proveedor   int           not null,
    id_usuario     int           not null,
    fecha_pedido   datetime      default now(),
    fecha_entrega  date,
    total          decimal(12,2) default 0.00,
    estado         enum('pendiente','recibido','cancelado') default 'pendiente',
    observaciones  varchar(200),
    constraint fk_ped_prov    foreign key (id_proveedor)
        references proveedores(id_proveedor),
    constraint fk_ped_usuario foreign key (id_usuario)
        references usuarios(id_usuario)
);

create table detalle_pedido (
    id_detalle      int           auto_increment primary key,
    id_pedido       int           not null,
    id_producto     int           not null,
    cantidad        int           not null,
    precio_unitario decimal(10,2) not null,
    subtotal        decimal(12,2) generated always as
                    (cantidad * precio_unitario) stored,
    constraint fk_dp_pedido   foreign key (id_pedido)
        references pedidos(id_pedido),
    constraint fk_dp_producto foreign key (id_producto)
        references productos(id_producto)
);

create table historial_precios (
    id_historial           int           auto_increment primary key,
    id_producto            int           not null,
    precio_compra_anterior decimal(10,2),
    precio_venta_anterior  decimal(10,2),
    precio_compra_nuevo    decimal(10,2),
    precio_venta_nuevo     decimal(10,2),
    fecha_cambio           datetime      default now(),
    id_usuario             int,
    constraint fk_hp_producto foreign key (id_producto)
        references productos(id_producto)
);

create table auditoria_movimientos (
    id_auditoria    int          auto_increment primary key,
    tabla_afectada  varchar(50)  not null,
    id_registro     int          not null,
    tipo_operacion  enum('insert','update','delete') not null,
    descripcion     varchar(255),
    id_usuario      int,
    fecha_operacion datetime     default now()
);

create table devoluciones (
    id_devolucion    int          auto_increment primary key,
    id_venta         int          not null,
    id_producto      int          not null,
    cantidad         int          not null,
    motivo           varchar(200),
    fecha_devolucion datetime     default now(),
    id_usuario       int          not null,
    constraint fk_dev_venta    foreign key (id_venta)
        references ventas(id_venta),
    constraint fk_dev_producto foreign key (id_producto)
        references productos(id_producto)
);

#3.2 insercion de datos
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

insert into proveedores (nombre, contacto, telefono, email, ciudad) values
('femsa coca-cola colombia','[nombre_eliminado]','3001000001',
 'pedidos@coca-cola.com.co','bogota');

insert into usuarios (nombre, email, clave_hash, rol) values
('don pepe rodriguez','donpepe@tienda.com','$2b$10$hash_dueno_1','dueno'),
('empleado-1',        'emp1@tienda.com',   '$2b$10$hash_emp_1',  'empleado'),
('empleado-2',        'emp2@tienda.com',   '$2b$10$hash_emp_2',  'empleado'),
('admin sistema',     'admin@tienda.com',  '$2b$10$hash_admin',  'admin'),
('empleado-3',        'emp3@tienda.com',   '$2b$10$hash_emp_3',  'empleado');

insert into productos
    (nombre, id_categoria, id_proveedor, precio_compra, precio_venta,
     stock_actual, stock_minimo, fecha_vencimiento, unidad_medida)
values
('gas. coca cola x 1.5 lt',             1,1, 4324, 5087,120,5,'2025-12-31','bot'),
('gas. coca cola x 400 ml',             1,1, 2304, 2711, 80,5,'2025-12-31','bot'),
('gas. coca cola original x 2.5 lt',    1,1, 6136, 7219, 60,5,'2025-12-31','bot'),
('gas. coca cola mini x 250 ml',        1,1, 1693, 1992,100,5,'2025-12-31','bot'),
('gas. coca cola x 600 ml',             1,1, 2854, 3358, 75,5,'2025-12-31','bot'),
('gas. coca cola x 1 lt',               1,1, 3271, 3849, 50,5,'2025-12-31','bot'),
('gas. coca cola s/azucar x 1.5 lts',   7,1, 4160, 4894, 70,5,'2025-12-31','bot'),
('gas. coca cola zero mini x 250 ml',   7,1, 1153, 1356, 90,5,'2025-12-31','bot'),
('gas. coca cola zero x 400 ml',        7,1, 2344, 2758, 65,5,'2025-12-31','bot'),
('gas. coca cola s/azucar x 2.5 lts',  7,1, 6117, 7197, 40,5,'2025-12-31','bot'),
('agua brisa litro bot',                2,1, 1558, 1833,200,5,'2026-06-30','bot'),
('agua brisa bidon x 6 litros',         2,1, 6298, 7409, 80,5,'2026-06-30','und'),
('agua brisa bot x 600 ml',             2,1, 1395, 1641,150,5,'2026-06-30','bot'),
('agua brisa manzana bot x 1.5 lt',     2,1, 3205, 3770, 55,5,'2026-06-30','bot'),
('agua brisa maracuya bot x 1.5 lt',    2,1, 3358, 3951, 45,5,'2026-06-30','bot'),
('gas. quatro toron x 1.5 ml',          1,1, 3564, 4193, 50,5,'2025-12-31','bot'),
('gas. quatro toron x 400 ml',          1,1, 2125, 2500, 60,5,'2025-12-31','bot'),
('gas. sprite x 1.5ml',                 1,1, 3776, 4443, 50,5,'2025-12-31','bot'),
('gas. kola roman x 400ml',             1,1, 2000, 2353, 55,5,'2025-12-31','bot'),
('jg. del valle fresh naranja x1.5 m',  3,1, 3403, 4004, 45,5,'2025-10-31','bot'),
('jg. del valle fresh citrus x 400 ml', 3,1, 1606, 1889, 60,5,'2025-10-31','bot'),
('jg. del valle fresh fru/citri x 2.5', 3,1, 4742, 5579, 35,5,'2025-10-31','bot'),
('gas. sprite x 400 ml',                1,1, 2040, 2400, 55,5,'2025-12-31','bot'),
('gas. schweppes ginger x 1.5 lt',      1,1, 3826, 4501, 40,5,'2025-12-31','bot'),
('gas. kola roman x 1.5 lts',           1,1, 3139, 3693, 45,5,'2025-12-31','bot'),
('gas. coca cola lata x 330 ml',       10,1, 3272, 3850, 70,5,'2025-12-31','und'),
('gas. quatro s/azucar x 1.5 lt',       7,1, 3272, 3850, 35,5,'2025-12-31','bot'),
('gas. schweppes soda 1.5 ml',          1,1, 3442, 4050, 40,5,'2025-12-31','bot'),
('gas. quatro toronj x 3 lts',          1,1, 5969, 7023, 30,5,'2025-12-31','bot'),
('gas. schweppes ginger ale x 400 ml',  1,1, 2202, 2591, 45,5,'2025-12-31','bot'),
('agua manantial bot x 600 ml',         2,1, 2295, 2700, 80,5,'2026-06-30','bot'),
('agua brisa manzana x 600 ml',         2,1, 2320, 2730, 60,5,'2026-06-30','bot'),
('agua brisa x 600 ml con gas',         2,1, 1360, 1599, 75,5,'2026-06-30','bot'),
('agua brisa maracuya x 600 ml',        2,1, 2185, 2571, 50,5,'2026-06-30','bot'),
('agua brisa bot limon x 600 ml',       2,1, 2340, 2753, 55,5,'2026-06-30','bot'),
('jg. del valle mandarina x 1.5 l',     3,1, 3612, 4250, 40,5,'2025-10-31','bot'),
('jg. del valle mandarina x 400ml',     3,1, 1615, 1900, 55,5,'2025-10-31','bot'),
('jg. del valle mandarina x 2.5 l',     3,1, 4802, 5650, 30,5,'2025-10-31','bot'),
('beb. monster mango ltx473ml',         4,1, 6715, 7900, 35,5,'2025-12-31','und'),
('gas. sprite x 3 lts',                 1,1, 6134, 7217, 25,5,'2025-12-31','bot'),
('gas. coca cola zero lata 330 ml',    10,1, 2775, 3265, 40,5,'2025-12-31','und'),
('gas. sprite s/azucar x 1.5 lt',      7,1, 3272, 3850, 30,5,'2025-12-31','bot'),
('gas. kola roman s/azucar x 1.5lt',   7,1, 3187, 3750, 25,5,'2025-12-31','bot'),
('agua brisa limon bot x 1.5 lt',       2,1, 3400, 4000, 30,5,'2026-06-30','bot'),
('agua manantial bot x 500 ml',         2,1, 2465, 2900, 40,5,'2026-06-30','bot'),
('beb. monster verde ltx473 ml',        4,1, 7055, 8300, 25,5,'2025-12-31','und'),
('beb. monster ultra ltx473ml',         4,1, 6715, 7900, 20,5,'2025-12-31','und'),
('beb. fuze tea negro durazno 400 ml',  5,1, 2690, 3165, 35,5,'2025-12-31','bot'),
('beb. fuze tea negro limon 400ml',     5,1, 2741, 3225, 30,5,'2025-12-31','bot'),
('beb. powerade frut/trop x 500 ml',    6,1, 3060, 3600, 30,5,'2025-12-31','bot');

insert into ventas (id_usuario, fecha_venta, total, estado) values
(2,'2025-01-05 08:15:00', 45800,'completada'),
(2,'2025-01-05 10:30:00', 23400,'completada'),
(3,'2025-01-06 09:00:00', 67200,'completada'),
(2,'2025-01-07 11:20:00', 18700,'completada'),
(3,'2025-01-08 14:00:00', 89500,'completada'),
(2,'2025-01-09 08:45:00', 34200,'completada'),
(5,'2025-01-10 09:00:00',112000,'completada'),
(3,'2025-01-11 10:30:00', 29400,'completada'),
(2,'2025-01-12 11:00:00', 58700,'completada'),
(5,'2025-01-13 14:30:00', 41200,'completada'),
(3,'2025-01-15 08:00:00', 95300,'completada'),
(2,'2025-01-16 09:15:00', 47600,'completada'),
(5,'2025-01-17 10:45:00', 33800,'completada'),
(2,'2025-01-18 11:30:00',128000,'completada'),
(3,'2025-01-20 14:00:00', 72400,'completada'),
(2,'2025-01-22 08:30:00', 85900,'completada'),
(5,'2025-01-24 09:00:00', 26700,'completada'),
(3,'2025-01-25 10:15:00', 63200,'completada'),
(2,'2025-01-27 11:45:00', 44100,'completada'),
(3,'2025-01-29 14:00:00',135000,'completada'),
(2,'2025-02-01 08:00:00', 39400,'completada'),
(5,'2025-02-02 09:30:00', 57800,'completada'),
(3,'2025-02-03 10:00:00', 91200,'completada'),
(2,'2025-02-05 11:15:00', 22300,'completada'),
(3,'2025-02-06 14:30:00',114000,'completada'),
(5,'2025-02-07 08:45:00', 68500,'completada'),
(2,'2025-02-08 09:00:00', 37600,'completada'),
(3,'2025-02-10 10:30:00', 98700,'completada'),
(2,'2025-02-11 11:00:00', 31400,'completada'),
(5,'2025-02-12 14:00:00',142000,'completada'),
(3,'2025-02-14 08:15:00',107000,'completada'),
(2,'2025-02-15 09:45:00', 73200,'completada'),
(5,'2025-02-17 10:00:00', 49800,'completada'),
(3,'2025-02-18 11:30:00', 86300,'completada'),
(2,'2025-02-20 14:15:00', 61700,'completada'),
(5,'2025-02-22 08:00:00',124000,'completada'),
(3,'2025-02-24 09:15:00', 38900,'completada'),
(2,'2025-02-25 10:45:00', 79400,'completada'),
(5,'2025-02-27 11:00:00', 55200,'completada'),
(3,'2025-02-28 14:30:00',158000,'completada'),
(2,'2025-03-01 08:30:00', 47300,'completada'),
(3,'2025-03-03 09:00:00', 93600,'completada'),
(5,'2025-03-04 10:15:00', 71400,'completada'),
(2,'2025-03-05 11:45:00', 28900,'completada'),
(3,'2025-03-06 14:00:00',118000,'completada'),
(5,'2025-03-07 08:00:00', 54700,'completada'),
(2,'2025-03-08 09:30:00',102000,'completada'),
(3,'2025-03-10 10:00:00', 42500,'completada'),
(5,'2025-03-11 11:15:00',136000,'completada'),
(2,'2025-03-12 14:45:00', 77800,'completada'),
(3,'2025-03-13 08:30:00', 63400,'completada'),
(5,'2025-03-14 09:00:00',109000,'completada'),
(2,'2025-03-15 10:30:00', 48200,'completada'),
(3,'2025-03-17 11:00:00', 89700,'completada'),
(5,'2025-03-18 14:15:00', 61500,'completada'),
(2,'2025-03-20 08:45:00',151000,'completada'),
(3,'2025-03-22 09:15:00', 34600,'completada'),
(5,'2025-03-24 10:45:00',105000,'completada'),
(2,'2025-03-26 11:30:00', 78300,'completada'),
(3,'2025-03-28 14:00:00', 66900,'completada');

insert into detalle_venta (id_venta, id_producto, cantidad, precio_unitario) values
(1, 1, 4,5087),(1,11, 6,1833),(1,13, 3,1641),
(2, 2, 5,2711),(2,23, 3,2400),
(3, 1, 8,5087),(3,12, 2,7409),(3,20, 3,4004),
(4,11, 6,1833),(4,13, 4,1641),
(5, 1,10,5087),(5,26, 5,3850),(5,12, 3,7409),
(6, 2, 4,2711),(6,11, 8,1833),
(7, 1,12,5087),(7,12, 4,7409),(7, 2, 6,2711),
(8,11, 5,1833),(8,13, 6,1641),(8,23, 4,2400),
(9, 1, 6,5087),(9,12, 3,7409),(9,11, 8,1833),
(10,13, 8,1641),(10,11, 6,1833),(10,20, 4,4004),
(11, 1,10,5087),(11,26, 6,3850),(11,12, 4,7409),
(12,11, 8,1833),(12,12, 3,7409),(12, 2, 5,2711),
(13,13, 6,1641),(13,23, 5,2400),(13,20, 3,4004),
(14, 1,12,5087),(14, 2, 8,2711),(14,26, 6,3850),(14,12,4,7409),
(15,11, 6,1833),(15,13, 8,1641),(15,12, 3,7409);

insert into pedidos (id_proveedor,id_usuario,fecha_pedido,fecha_entrega,total,estado) values
(1,1,'2025-01-08','2025-01-10',  980000,'recibido'),
(1,1,'2025-01-20','2025-01-22', 1250000,'recibido'),
(1,4,'2025-02-03','2025-02-05',  875000,'recibido'),
(1,1,'2025-02-15','2025-02-17', 1540000,'recibido'),
(1,1,'2025-02-25','2025-02-27',  760000,'recibido'),
(1,4,'2025-03-05','2025-03-07', 1120000,'recibido'),
(1,1,'2025-03-15','2025-03-17',  930000,'recibido'),
(1,4,'2025-03-22','2025-03-24', 1380000,'recibido'),
(1,1,'2025-04-01','2025-04-03', 1680000,'pendiente'),
(1,4,'2025-04-10','2025-04-12',  820000,'pendiente');

insert into detalle_pedido (id_pedido,id_producto,cantidad,precio_unitario) values
(1, 1,120,4324),(1,11,200,1558),(1,13,150,1395),
(2, 1,150,4324),(2,12, 60,6298),(2, 2,100,2304),
(3,11,180,1558),(3,12, 50,6298),(3,20, 60,3403),
(4, 1,200,4324),(4,26, 80,3272),(4,23,100,2040),
(5,13,200,1395),(5,11,150,1558),(5, 2, 80,2304),
(6, 1,160,4324),(6,12, 70,6298),(6,23, 90,2040),
(7,11,200,1558),(7,13,180,1395),(7,20, 50,3403),
(8, 1,180,4324),(8,12, 80,6298),(8,26, 60,3272),
(9, 1,240,4324),(9,11,300,1558),(9,12, 90,6298),
(10,13,200,1395),(10,2,120,2304),(10,23,80,2040);

insert into devoluciones (id_venta,id_producto,cantidad,motivo,id_usuario) values
(3, 12,1,'bidon con fuga',                 2),
(7, 26,2,'lata abollada',                  3),
(14, 1,1,'botella sin sello de seguridad', 5),
(20,11,2,'producto vencido',               2),
(25,13,1,'botella golpeada',               3);

#3.3 procedimientos almacenados
delimiter //

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
        set p_mensaje  = concat('error: stock insuficiente. disponible: ',
                                v_stock, ' unidades.');
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
        set p_mensaje = concat('venta #', p_id_venta,
                               ' registrada por $', v_subtotal);
    end if;
end //

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

    select estado into v_estado
    from pedidos where id_pedido = p_id_pedido;

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
        set p_mensaje = concat('pedido #', p_id_pedido,
                               ' recibido. inventario actualizado.');
    end if;
end //

create procedure sp_reporte_ventas(
    in p_fecha_inicio date,
    in p_fecha_fin    date
)
begin
    select date(v.fecha_venta) as fecha,
           count(v.id_venta)   as num_ventas,
           sum(v.total)        as total_dia,
           avg(v.total)        as ticket_promedio,
           max(v.total)        as venta_maxima
    from ventas v
    where date(v.fecha_venta) between p_fecha_inicio and p_fecha_fin
      and v.estado = 'completada'
    group by date(v.fecha_venta)
    order by fecha;
end //

delimiter ;

#3.4 triggers
delimiter //

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

#3.5 vistas
create or replace view v_inventario_alertas as
select
    p.id_producto,
    p.nombre                                        as producto,
    c.nombre                                        as categoria,
    pv.nombre                                       as proveedor,
    p.stock_actual,
    p.stock_minimo,
    p.precio_compra,
    p.precio_venta,
    (p.precio_venta - p.precio_compra)              as margen,
    p.fecha_vencimiento,
    datediff(p.fecha_vencimiento, curdate())         as dias_para_vencer,
    case when p.stock_actual <= p.stock_minimo
         then 'stock bajo' else 'ok'
    end                                             as alerta_stock,
    case
        when p.fecha_vencimiento is not null
             and datediff(p.fecha_vencimiento, curdate()) <= 0  then 'vencido'
        when p.fecha_vencimiento is not null
             and datediff(p.fecha_vencimiento, curdate()) <= 15 then 'vence pronto'
        else 'ok'
    end                                             as alerta_vencimiento
from productos p
join categorias  c  on p.id_categoria = c.id_categoria
join proveedores pv on p.id_proveedor = pv.id_proveedor
where p.activo = 1;

create or replace view v_ventas_por_producto as
select
    p.id_producto,
    p.nombre                        as producto,
    c.nombre                        as categoria,
    sum(dv.cantidad)                as total_unidades,
    sum(dv.subtotal)                as total_ingresos,
    avg(dv.precio_unitario)         as precio_promedio,
    count(distinct dv.id_venta)     as num_transacciones
from detalle_venta dv
join productos p  on dv.id_producto = p.id_producto
join categorias c on p.id_categoria = c.id_categoria
join ventas v     on dv.id_venta    = v.id_venta
where v.estado = 'completada'
group by p.id_producto, p.nombre, c.nombre;

create or replace view v_kpi_mensual as
select
    year(fecha_venta)   as anio,
    month(fecha_venta)  as mes,
    count(*)            as total_ventas,
    sum(total)          as ingresos_totales,
    avg(total)          as ticket_promedio,
    max(total)          as venta_maxima,
    min(total)          as venta_minima
from ventas
where estado = 'completada'
group by year(fecha_venta), month(fecha_venta);

create or replace view v_sugerencia_pedidos as
select
    p.id_producto,
    p.nombre                                  as producto,
    pv.nombre                                 as proveedor,
    pv.telefono                               as contacto_proveedor,
    p.stock_actual,
    p.stock_minimo,
    (p.stock_minimo - p.stock_actual)         as deficit,
    case
        when p.stock_actual <= p.stock_minimo          then 'pedir urgente'
        when p.stock_actual <= (p.stock_minimo * 1.5)  then 'pedir pronto'
        else                                                'stock suficiente'
    end                                       as recomendacion
from productos p
join proveedores pv on p.id_proveedor = pv.id_proveedor
where p.activo = 1
order by deficit desc;

#3.6 visualizacion del modelo fisico via information_schema
select
    tc.table_name       as tabla,
    tc.constraint_name  as nombre_constraint,
    tc.constraint_type  as tipo,
    kcu.column_name     as campo,
    kcu.referenced_table_name  as tabla_referenciada,
    kcu.referenced_column_name as campo_referenciado
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
    on  tc.constraint_name = kcu.constraint_name
    and tc.table_schema    = kcu.table_schema
    and tc.table_name      = kcu.table_name
where tc.table_schema = 'tienda_don_pepe'
order by tc.table_name, tc.constraint_type;

-- campos calculados (generated always as)
select
    table_name              as tabla,
    column_name             as campo_generado,
    column_type             as tipo,
    generation_expression   as expresion
from information_schema.columns
where table_schema = 'tienda_don_pepe'
  and extra like '%generated%';

-- indices del modelo fisico
select
    table_name   as tabla,
    index_name   as indice,
    column_name  as campo,
    non_unique   as permite_duplicados,
    index_type   as tipo
from information_schema.statistics
where table_schema = 'tienda_don_pepe'
order by table_name, index_name;

-- show create table (ddl exacto generado por mysql)
show create table categorias;
show create table proveedores;
show create table usuarios;
show create table productos;
show create table ventas;
show create table detalle_venta;
show create table pedidos;
show create table detalle_pedido;
show create table historial_precios;
show create table auditoria_movimientos;
show create table devoluciones;

-- resumen final del modelo fisico
select
    (select count(*) from information_schema.tables
     where table_schema = 'tienda_don_pepe'
       and table_type   = 'base table')              as total_tablas,
    (select count(*) from information_schema.columns
     where table_schema = 'tienda_don_pepe')          as total_campos,
    (select count(*) from information_schema.table_constraints
     where table_schema    = 'tienda_don_pepe'
       and constraint_type = 'primary key')           as total_pk,
    (select count(*) from information_schema.table_constraints
     where table_schema    = 'tienda_don_pepe'
       and constraint_type = 'foreign key')           as total_fk,
    (select count(*) from information_schema.table_constraints
     where table_schema    = 'tienda_don_pepe'
       and constraint_type = 'unique')                as total_unique,
    (select count(*) from information_schema.statistics
     where table_schema    = 'tienda_don_pepe')       as total_indices;
