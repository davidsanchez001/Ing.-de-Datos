#CONFIGURACIÓN E INICIALIZACIÓN
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE            = '';
SET time_zone           = '-05:00';

DROP DATABASE IF EXISTS tienda_don_pepe;
CREATE DATABASE tienda_don_pepe
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_spanish_ci;

USE tienda_don_pepe;

SET FOREIGN_KEY_CHECKS = 1;

#CREACIÓN DE TABLAS
#RQF-06/RQF-07: Gestión de Categorías
CREATE TABLE categorias (
    id_categoria INT          AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(50)  NOT NULL,
    descripcion  VARCHAR(100),
    CONSTRAINT uq_cat_nombre UNIQUE (nombre)
);

#RQF-08/RQF-09/RQF-10: Gestión de Proveedores
CREATE TABLE proveedores (
    id_proveedor   INT          AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(80)  NOT NULL,
    contacto       VARCHAR(80),
    telefono       VARCHAR(20)  NOT NULL,
    email          VARCHAR(80),
    ciudad         VARCHAR(50)  DEFAULT 'bogota',
    activo         TINYINT(1)   DEFAULT 1,
    fecha_registro DATE         DEFAULT (CURRENT_DATE)
);

#RQF-01 al RQF-05: Gestión de Usuarios
CREATE TABLE usuarios (
    id_usuario     INT          AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(80)  NOT NULL,
    email          VARCHAR(80)  NOT NULL,
    clave_hash     VARCHAR(255) NOT NULL,
    rol            ENUM('admin','empleado','dueno') NOT NULL DEFAULT 'empleado',
    activo         TINYINT(1)   DEFAULT 1,
    fecha_registro DATETIME     DEFAULT NOW(),
    CONSTRAINT uq_email UNIQUE (email)
);

#RQF-12 al RQF-16: Gestión de Productos
CREATE TABLE productos (
    id_producto       INT           AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(80)   NOT NULL,
    id_categoria      INT           NOT NULL,
    id_proveedor      INT           NOT NULL,
    precio_compra     DECIMAL(10,2) NOT NULL,
    precio_venta      DECIMAL(10,2) NOT NULL,
    stock_actual      INT           NOT NULL DEFAULT 0,
    stock_minimo      INT           NOT NULL DEFAULT 5,
    fecha_vencimiento DATE,
    unidad_medida     VARCHAR(20)   DEFAULT 'und',
    activo            TINYINT(1)    DEFAULT 1,
    fecha_registro    DATETIME      DEFAULT NOW(),
    CONSTRAINT fk_prod_cat  FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_prod_prov FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    CONSTRAINT chk_precios  CHECK (precio_venta >= precio_compra)
);

#RQF-17 al RQF-21: Gestión de Ventas
CREATE TABLE ventas (
    id_venta      INT           AUTO_INCREMENT PRIMARY KEY,
    id_usuario    INT           NOT NULL,
    fecha_venta   DATETIME      DEFAULT NOW(),
    total         DECIMAL(12,2) DEFAULT 0.00,
    estado        ENUM('completada','anulada') DEFAULT 'completada',
    observaciones VARCHAR(200),
    CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

#RQF-18/RQF-19/RQF-20: subtotal calculado automáticamente
CREATE TABLE detalle_venta (
    id_detalle      INT           AUTO_INCREMENT PRIMARY KEY,
    id_venta        INT           NOT NULL,
    id_producto     INT           NOT NULL,
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_dv_venta    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta),
    CONSTRAINT fk_dv_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    CONSTRAINT chk_cantidad   CHECK (cantidad > 0)
);

#RQF-24 al RQF-27: Gestión de Pedidos
CREATE TABLE pedidos (
    id_pedido      INT           AUTO_INCREMENT PRIMARY KEY,
    id_proveedor   INT           NOT NULL,
    id_usuario     INT           NOT NULL,
    fecha_pedido   DATETIME      DEFAULT NOW(),
    fecha_entrega  DATE,
    total          DECIMAL(12,2) DEFAULT 0.00,
    estado         ENUM('pendiente','recibido','cancelado') DEFAULT 'pendiente',
    observaciones  VARCHAR(200),
    CONSTRAINT fk_ped_prov    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    CONSTRAINT fk_ped_usuario FOREIGN KEY (id_usuario)   REFERENCES usuarios(id_usuario)
);

CREATE TABLE detalle_pedido (
    id_detalle      INT           AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT           NOT NULL,
    id_producto     INT           NOT NULL,
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_dp_pedido   FOREIGN KEY (id_pedido)   REFERENCES pedidos(id_pedido),
    CONSTRAINT fk_dp_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

#RQF-31: Historial de Precios
CREATE TABLE historial_precios (
    id_historial           INT           AUTO_INCREMENT PRIMARY KEY,
    id_producto            INT           NOT NULL,
    precio_compra_anterior DECIMAL(10,2),
    precio_venta_anterior  DECIMAL(10,2),
    precio_compra_nuevo    DECIMAL(10,2),
    precio_venta_nuevo     DECIMAL(10,2),
    fecha_cambio           DATETIME      DEFAULT NOW(),
    id_usuario             INT,
    CONSTRAINT fk_hp_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

#RQF-23: Auditoría de Movimientos
CREATE TABLE auditoria_movimientos (
    id_auditoria    INT          AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada  VARCHAR(50)  NOT NULL,
    id_registro     INT          NOT NULL,
    tipo_operacion  ENUM('insert','update','delete') NOT NULL,
    descripcion     VARCHAR(255),
    id_usuario      INT,
    fecha_operacion DATETIME     DEFAULT NOW()
);

#RQF-22: Devoluciones
CREATE TABLE devoluciones (
    id_devolucion    INT          AUTO_INCREMENT PRIMARY KEY,
    id_venta         INT          NOT NULL,
    id_producto      INT          NOT NULL,
    cantidad         INT          NOT NULL,
    motivo           VARCHAR(200),
    fecha_devolucion DATETIME     DEFAULT NOW(),
    id_usuario       INT          NOT NULL,
    CONSTRAINT fk_dev_venta    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta),
    CONSTRAINT fk_dev_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

#PROCEDIMIENTOS ALMACENADOS Y TRIGGERS
DELIMITER //

#RQF-17/RQF-18/RQF-19: sp_registrar_venta
CREATE PROCEDURE sp_registrar_venta(
    IN  p_id_usuario  INT,
    IN  p_id_producto INT,
    IN  p_cantidad    INT,
    OUT p_id_venta    INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_stock    INT;
    DECLARE v_precio   DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_venta = -1;
        SET p_mensaje  = 'Error: transaccion revertida por fallo interno.';
    END;

    SELECT stock_actual, precio_venta
    INTO   v_stock, v_precio
    FROM   productos
    WHERE  id_producto = p_id_producto AND activo = 1;

    IF v_stock IS NULL THEN
        SET p_id_venta = 0;
        SET p_mensaje  = 'Error: producto no encontrado o inactivo.';

    ELSEIF v_stock < p_cantidad THEN
        SET p_id_venta = 0;
        SET p_mensaje  = CONCAT('Error: stock insuficiente. Disponible: ', v_stock, ' unidades.');

    ELSE
        START TRANSACTION;

        INSERT INTO ventas (id_usuario, total) VALUES (p_id_usuario, 0);
        SET p_id_venta = LAST_INSERT_ID();

        -- Este INSERT activa trg_actualizar_total_venta (RQF-20)
        INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
        VALUES (p_id_venta, p_id_producto, p_cantidad, v_precio);

        -- Descontar stock (RQF-19), activa trg_auditoria_stock_bajo si baja del mínimo
        UPDATE productos
        SET stock_actual = stock_actual - p_cantidad
        WHERE id_producto = p_id_producto;

        COMMIT;
        SET p_mensaje = CONCAT('Venta #', p_id_venta, ' registrada correctamente.');
    END IF;
END //

#RQF-26: sp_recibir_pedido
CREATE PROCEDURE sp_recibir_pedido(
    IN  p_id_pedido INT,
    OUT p_mensaje   VARCHAR(200)
)
BEGIN
    DECLARE v_estado  VARCHAR(20);
    DECLARE done      INT DEFAULT 0;
    DECLARE v_id_prod INT;
    DECLARE v_cant    INT;

    DECLARE cur_detalle CURSOR FOR
        SELECT id_producto, cantidad
        FROM   detalle_pedido
        WHERE  id_pedido = p_id_pedido;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error: no se pudo procesar el pedido.';
    END;

    SELECT estado INTO v_estado FROM pedidos WHERE id_pedido = p_id_pedido;

    IF v_estado IS NULL THEN
        SET p_mensaje = 'Error: pedido no encontrado.';

    ELSEIF v_estado != 'pendiente' THEN
        SET p_mensaje = CONCAT('Error: el pedido ya esta en estado: ', v_estado);

    ELSE
        START TRANSACTION;

        UPDATE pedidos SET estado = 'recibido' WHERE id_pedido = p_id_pedido;

        OPEN cur_detalle;
        loop_detalle: LOOP
            FETCH cur_detalle INTO v_id_prod, v_cant;
            IF done THEN LEAVE loop_detalle; END IF;
            UPDATE productos
            SET stock_actual = stock_actual + v_cant
            WHERE id_producto = v_id_prod;
        END LOOP;
        CLOSE cur_detalle;

        COMMIT;
        SET p_mensaje = CONCAT('Pedido #', p_id_pedido, ' recibido. Inventario actualizado.');
    END IF;
END //

#RQF-40: sp_reporte_ventas
CREATE PROCEDURE sp_reporte_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE
)
BEGIN
    SELECT DATE(fecha_venta)    AS fecha,
           COUNT(id_venta)      AS num_ventas,
           SUM(total)           AS total_dia,
           ROUND(AVG(total), 2) AS ticket_promedio,
           MAX(total)           AS venta_maxima,
           MIN(total)           AS venta_minima
    FROM   ventas
    WHERE  DATE(fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND  estado = 'completada'
    GROUP  BY DATE(fecha_venta)
    ORDER  BY fecha;
END //

#RQF-31: trg_historial_precios
CREATE TRIGGER trg_historial_precios
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF OLD.precio_compra != NEW.precio_compra
    OR OLD.precio_venta  != NEW.precio_venta THEN
        INSERT INTO historial_precios (
            id_producto,
            precio_compra_anterior, precio_venta_anterior,
            precio_compra_nuevo,    precio_venta_nuevo
        ) VALUES (
            OLD.id_producto,
            OLD.precio_compra, OLD.precio_venta,
            NEW.precio_compra, NEW.precio_venta
        );
    END IF;
END //

#RQF-23: trg_auditoria_devoluciones
CREATE TRIGGER trg_auditoria_devoluciones
BEFORE DELETE ON devoluciones
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_movimientos (
        tabla_afectada, id_registro, tipo_operacion, descripcion
    ) VALUES (
        'devoluciones', OLD.id_devolucion, 'delete',
        CONCAT('Devolucion eliminada | Venta #', OLD.id_venta,
               ' | Producto #', OLD.id_producto,
               ' | Cantidad: ', OLD.cantidad,
               ' | Motivo: ', OLD.motivo)
    );
END //

#RQF-20: trg_actualizar_total_venta
CREATE TRIGGER trg_actualizar_total_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE ventas
    SET    total = (SELECT SUM(subtotal) FROM detalle_venta WHERE id_venta = NEW.id_venta)
    WHERE  id_venta = NEW.id_venta;
END //

#RQF-19/RQF-28: trg_auditoria_stock_bajo
CREATE TRIGGER trg_auditoria_stock_bajo
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock_actual <= NEW.stock_minimo
    AND OLD.stock_actual > OLD.stock_minimo THEN
        INSERT INTO auditoria_movimientos (
            tabla_afectada, id_registro, tipo_operacion, descripcion
        ) VALUES (
            'productos', NEW.id_producto, 'update',
            CONCAT('ALERTA STOCK BAJO: ', NEW.nombre,
                   ' | Stock actual: ', NEW.stock_actual,
                   ' | Stock minimo: ', NEW.stock_minimo)
        );
    END IF;
END //

DELIMITER ;

#VISTAS
#RQF-28/RQF-29/RQF-30: v_inventario_alertas
CREATE OR REPLACE VIEW v_inventario_alertas AS
SELECT
    p.id_producto,
    p.nombre                                        AS producto,
    c.nombre                                        AS categoria,
    pv.nombre                                       AS proveedor,
    p.stock_actual,
    p.stock_minimo,
    p.precio_compra,
    p.precio_venta,
    (p.precio_venta - p.precio_compra)              AS margen_unitario,
    (p.stock_actual * p.precio_compra)              AS valor_inventario,
    p.fecha_vencimiento,
    DATEDIFF(p.fecha_vencimiento, CURDATE())         AS dias_para_vencer,
    CASE WHEN p.stock_actual <= p.stock_minimo
         THEN 'STOCK BAJO' ELSE 'OK'
    END                                             AS alerta_stock,
    CASE
        WHEN p.fecha_vencimiento IS NOT NULL
             AND DATEDIFF(p.fecha_vencimiento, CURDATE()) <= 0   THEN 'VENCIDO'
        WHEN p.fecha_vencimiento IS NOT NULL
             AND DATEDIFF(p.fecha_vencimiento, CURDATE()) <= 30  THEN 'VENCE PRONTO'
        ELSE 'OK'
    END                                             AS alerta_vencimiento
FROM  productos   p
JOIN  categorias  c  ON p.id_categoria = c.id_categoria
JOIN  proveedores pv ON p.id_proveedor = pv.id_proveedor
WHERE p.activo = 1;

#RQF-34: v_ventas_por_producto
CREATE OR REPLACE VIEW v_ventas_por_producto AS
SELECT
    p.id_producto,
    p.nombre                     AS producto,
    c.nombre                     AS categoria,
    SUM(dv.cantidad)             AS total_unidades,
    SUM(dv.subtotal)             AS total_ingresos,
    ROUND(AVG(dv.precio_unitario), 2) AS precio_promedio,
    COUNT(DISTINCT dv.id_venta)  AS num_transacciones
FROM  detalle_venta dv
JOIN  productos  p ON dv.id_producto = p.id_producto
JOIN  categorias c ON p.id_categoria = c.id_categoria
JOIN  ventas     v ON dv.id_venta    = v.id_venta
WHERE v.estado = 'completada'
GROUP BY p.id_producto, p.nombre, c.nombre;

#RQF-35/RQF-36: v_rotacion_mensual
CREATE OR REPLACE VIEW v_rotacion_mensual AS
SELECT
    p.nombre                                                          AS producto,
    c.nombre                                                          AS categoria,
    YEAR(v.fecha_venta)                                               AS anio,
    MONTH(v.fecha_venta)                                              AS mes,
    SUM(dv.cantidad)                                                  AS unidades_vendidas,
    ROUND(SUM(dv.cantidad) / COUNT(DISTINCT DATE(v.fecha_venta)), 2)  AS promedio_diario
FROM  detalle_venta dv
JOIN  productos  p ON dv.id_producto = p.id_producto
JOIN  categorias c ON p.id_categoria = c.id_categoria
JOIN  ventas     v ON dv.id_venta    = v.id_venta
WHERE v.estado = 'completada'
GROUP BY p.id_producto, p.nombre, c.nombre, YEAR(v.fecha_venta), MONTH(v.fecha_venta);

#RQF-39: v_kpi_mensual
CREATE OR REPLACE VIEW v_kpi_mensual AS
SELECT
    YEAR(fecha_venta)    AS anio,
    MONTH(fecha_venta)   AS mes,
    COUNT(*)             AS total_ventas,
    SUM(total)           AS ingresos_totales,
    ROUND(AVG(total), 2) AS ticket_promedio,
    MAX(total)           AS venta_maxima,
    MIN(total)           AS venta_minima
FROM  ventas
WHERE estado = 'completada'
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta);

#INSERCIÓN DE DATOS
#Categorías 10 registros RQF-06
INSERT INTO categorias (nombre, descripcion) VALUES
('gaseosas',            'coca-cola, sprite, quatro, kola roman y schweppes'),
('aguas',               'agua brisa y agua manantial en todas sus presentaciones'),
('jugos',               'jugos del valle fresh y del valle frutal'),
('energeticas',         'monster energy en todas sus variedades'),
('te y bebidas',        'fuze tea en todas sus presentaciones'),
('hidratantes',         'powerade y flashlyte'),
('gaseosas sin azucar', 'linea zero: coca-cola zero, sprite zero, quatro zero'),
('packs y combos',      'presentaciones multiunidad y combos promocionales'),
('bebidas vegetales',   'ades de soya, almendra y derivados'),
('latas',               'presentaciones en lata: coca-cola lata, monster lata');

#Proveedores 1 registro RQF-08
INSERT INTO proveedores (nombre, contacto, telefono, email, ciudad) VALUES
('femsa coca-cola colombia', 'gerencia comercial', '3001000001', 'pedidos@coca-cola.com.co', 'bogota');

#Usuarios 10 registros RQF-01
INSERT INTO usuarios (nombre, email, clave_hash, rol) VALUES
('don pepe rodriguez', 'donpepe@tienda.com',  '$2b$10$hash_dueno_1', 'dueno'),
('carlos mendez',      'emp1@tienda.com',     '$2b$10$hash_emp_1',   'empleado'),
('lucia vargas',       'emp2@tienda.com',     '$2b$10$hash_emp_2',   'empleado'),
('admin sistema',      'admin@tienda.com',    '$2b$10$hash_admin',   'admin'),
('jorge pineda',       'emp3@tienda.com',     '$2b$10$hash_emp_3',   'empleado'),
('maria torres',       'emp4@tienda.com',     '$2b$10$hash_emp_4',   'empleado'),
('andres ruiz',        'emp5@tienda.com',     '$2b$10$hash_emp_5',   'empleado'),
('claudia herrera',    'emp6@tienda.com',     '$2b$10$hash_emp_6',   'empleado'),
('rafael gomez',       'emp7@tienda.com',     '$2b$10$hash_emp_7',   'empleado'),
('sofia castillo',     'emp8@tienda.com',     '$2b$10$hash_emp_8',   'empleado');

#Productos 50 registros RQF-12
INSERT INTO productos
    (nombre, id_categoria, id_proveedor, precio_compra, precio_venta,
     stock_actual, stock_minimo, fecha_vencimiento, unidad_medida)
VALUES
#Clase A gaseosas coca-cola (alta rotación)
('gas. coca cola x 1.5 lt',              1, 1, 4324, 5087, 120, 5, '2025-12-31', 'bot'),
('gas. coca cola x 400 ml',              1, 1, 2304, 2711,  80, 5, '2025-12-31', 'bot'),
('gas. coca cola original x 2.5 lt',     1, 1, 6136, 7219,  60, 5, '2025-12-31', 'bot'),
('gas. coca cola mini x 250 ml',         1, 1, 1693, 1992, 100, 5, '2025-12-31', 'bot'),
('gas. coca cola x 600 ml',              1, 1, 2854, 3358,  75, 5, '2025-12-31', 'bot'),
('gas. coca cola x 1 lt',                1, 1, 3271, 3849,  50, 5, '2025-12-31', 'bot'),
#Clase A gaseosas zero
('gas. coca cola s/azucar x 1.5 lts',    7, 1, 4160, 4894,  70, 5, '2025-12-31', 'bot'),
('gas. coca cola zero mini x 250 ml',    7, 1, 1153, 1356,  90, 5, '2025-12-31', 'bot'),
('gas. coca cola zero x 400 ml',         7, 1, 2344, 2758,  65, 5, '2025-12-31', 'bot'),
('gas. coca cola s/azucar x 2.5 lts',   7, 1, 6117, 7197,  40, 5, '2025-12-31', 'bot'),
#Clase A aguas
('agua brisa litro bot',                 2, 1, 1558, 1833, 200, 5, '2026-06-30', 'bot'),
('agua brisa bidon x 6 litros',          2, 1, 6298, 7409,  80, 5, '2026-06-30', 'und'),
('agua brisa bot x 600 ml',              2, 1, 1395, 1641, 150, 5, '2026-06-30', 'bot'),
('agua brisa manzana bot x 1.5 lt',      2, 1, 3205, 3770,  55, 5, '2026-06-30', 'bot'),
('agua brisa maracuya bot x 1.5 lt',     2, 1, 3358, 3951,  45, 5, '2026-06-30', 'bot'),
#Clase A gaseosas quatro, sprite, kola roman
('gas. quatro toron x 1.5 lt',           1, 1, 3564, 4193,  50, 5, '2025-12-31', 'bot'),
('gas. quatro toron x 400 ml',           1, 1, 2125, 2500,  60, 5, '2025-12-31', 'bot'),
('gas. sprite x 1.5 lt',                 1, 1, 3776, 4443,  50, 5, '2025-12-31', 'bot'),
('gas. kola roman x 400 ml',             1, 1, 2000, 2353,  55, 5, '2025-12-31', 'bot'),
#Clase A jugos del valle
('jg. del valle fresh naranja x 1.5 lt', 3, 1, 3403, 4004,  45, 5, '2025-10-31', 'bot'),
('jg. del valle fresh citrus x 400 ml',  3, 1, 1606, 1889,  60, 5, '2025-10-31', 'bot'),
('jg. del valle fresh fru/citri x 2.5',  3, 1, 4742, 5579,  35, 5, '2025-10-31', 'bot'),
#Clase B gaseosas variadas
('gas. sprite x 400 ml',                 1, 1, 2040, 2400,  55, 5, '2025-12-31', 'bot'),
('gas. schweppes ginger x 1.5 lt',       1, 1, 3826, 4501,  40, 5, '2025-12-31', 'bot'),
('gas. kola roman x 1.5 lts',            1, 1, 3139, 3693,  45, 5, '2025-12-31', 'bot'),
('gas. coca cola lata x 330 ml',        10, 1, 3272, 3850,  70, 5, '2025-12-31', 'und'),
('gas. quatro s/azucar x 1.5 lt',        7, 1, 3272, 3850,  35, 5, '2025-12-31', 'bot'),
('gas. schweppes soda 1.5 lt',           1, 1, 3442, 4050,  40, 5, '2025-12-31', 'bot'),
('gas. quatro toronj x 3 lts',           1, 1, 5969, 7023,  30, 5, '2025-12-31', 'bot'),
('gas. schweppes ginger ale x 400 ml',   1, 1, 2202, 2591,  45, 5, '2025-12-31', 'bot'),
#Clase B aguas
('agua manantial bot x 600 ml',          2, 1, 2295, 2700,  80, 5, '2026-06-30', 'bot'),
('agua brisa manzana x 600 ml',          2, 1, 2320, 2730,  60, 5, '2026-06-30', 'bot'),
('agua brisa x 600 ml con gas',          2, 1, 1360, 1599,  75, 5, '2026-06-30', 'bot'),
('agua brisa maracuya x 600 ml',         2, 1, 2185, 2571,  50, 5, '2026-06-30', 'bot'),
('agua brisa bot limon x 600 ml',        2, 1, 2340, 2753,  55, 5, '2026-06-30', 'bot'),
#Clase B jugos del valle mandarina
('jg. del valle mandarina x 1.5 lt',     3, 1, 3612, 4250,  40, 5, '2025-10-31', 'bot'),
('jg. del valle mandarina x 400 ml',     3, 1, 1615, 1900,  55, 5, '2025-10-31', 'bot'),
('jg. del valle mandarina x 2.5 lt',     3, 1, 4802, 5650,  30, 5, '2025-10-31', 'bot'),
#Clase B energéticas y gaseosas grandes
('beb. monster mango ltx 473 ml',        4, 1, 6715, 7900,  35, 5, '2025-12-31', 'und'),
('gas. sprite x 3 lts',                  1, 1, 6134, 7217,  25, 5, '2025-12-31', 'bot'),
#Clase C gaseosas zero lata y sin azúcar
('gas. coca cola zero lata 330 ml',     10, 1, 2775, 3265,  40, 5, '2025-12-31', 'und'),
('gas. sprite s/azucar x 1.5 lt',        7, 1, 3272, 3850,  30, 5, '2025-12-31', 'bot'),
('gas. kola roman s/azucar x 1.5 lt',    7, 1, 3187, 3750,  25, 5, '2025-12-31', 'bot'),
#Clase C aguas especiales
('agua brisa limon bot x 1.5 lt',        2, 1, 3400, 4000,  30, 5, '2026-06-30', 'bot'),
('agua manantial bot x 500 ml',          2, 1, 2465, 2900,  40, 5, '2026-06-30', 'bot'),
#Clase C energéticas monster
('beb. monster verde ltx 473 ml',        4, 1, 7055, 8300,  25, 5, '2025-12-31', 'und'),
('beb. monster ultra ltx 473 ml',        4, 1, 6715, 7900,  20, 5, '2025-12-31', 'und'),
#Clase C té, hidratantes
('beb. fuze tea negro durazno 400 ml',   5, 1, 2690, 3165,  35, 5, '2025-12-31', 'bot'),
('beb. fuze tea negro limon 400 ml',     5, 1, 2741, 3225,  30, 5, '2025-12-31', 'bot'),
('beb. powerade frut/trop x 500 ml',     6, 1, 3060, 3600,  30, 5, '2025-12-31', 'bot');

#Ventas 60 registros RQF-17
INSERT INTO ventas (id_usuario, fecha_venta, total, estado) VALUES
( 2, '2025-01-05 08:15:00',  45800, 'completada'), ( 2, '2025-01-05 10:30:00',  23400, 'completada'),
( 3, '2025-01-06 09:00:00',  67200, 'completada'), ( 2, '2025-01-07 11:20:00',  18700, 'completada'),
( 3, '2025-01-08 14:00:00',  89500, 'completada'), ( 2, '2025-01-09 08:45:00',  34200, 'completada'),
( 5, '2025-01-10 09:00:00', 112000, 'completada'), ( 3, '2025-01-11 10:30:00',  29400, 'completada'),
( 2, '2025-01-12 11:00:00',  58700, 'completada'), ( 5, '2025-01-13 14:30:00',  41200, 'completada'),
( 3, '2025-01-15 08:00:00',  95300, 'completada'), ( 2, '2025-01-16 09:15:00',  47600, 'completada'),
( 5, '2025-01-17 10:45:00',  33800, 'completada'), ( 2, '2025-01-18 11:30:00', 128000, 'completada'),
( 3, '2025-01-20 14:00:00',  72400, 'completada'), ( 2, '2025-01-22 08:30:00',  85900, 'completada'),
( 5, '2025-01-24 09:00:00',  26700, 'completada'), ( 3, '2025-01-25 10:15:00',  63200, 'completada'),
( 2, '2025-01-27 11:45:00',  44100, 'completada'), ( 3, '2025-01-29 14:00:00', 135000, 'completada'),
( 2, '2025-02-01 08:00:00',  39400, 'completada'), ( 5, '2025-02-02 09:30:00',  57800, 'completada'),
( 3, '2025-02-03 10:00:00',  91200, 'completada'), ( 2, '2025-02-05 11:15:00',  22300, 'completada'),
( 3, '2025-02-06 14:30:00', 114000, 'completada'), ( 5, '2025-02-07 08:45:00',  68500, 'completada'),
( 2, '2025-02-08 09:00:00',  37600, 'completada'), ( 3, '2025-02-10 10:30:00',  98700, 'completada'),
( 2, '2025-02-11 11:00:00',  31400, 'completada'), ( 5, '2025-02-12 14:00:00', 142000, 'completada'),
( 3, '2025-02-14 08:15:00', 107000, 'completada'), ( 2, '2025-02-15 09:45:00',  73200, 'completada'),
( 5, '2025-02-17 10:00:00',  49800, 'completada'), ( 3, '2025-02-18 11:30:00',  86300, 'completada'),
( 2, '2025-02-20 14:15:00',  61700, 'completada'), ( 5, '2025-02-22 08:00:00', 124000, 'completada'),
( 3, '2025-02-24 09:15:00',  38900, 'completada'), ( 2, '2025-02-25 10:45:00',  79400, 'completada'),
( 5, '2025-02-27 11:00:00',  55200, 'completada'), ( 3, '2025-02-28 14:30:00', 158000, 'completada'),
( 2, '2025-03-01 08:30:00',  47300, 'completada'), ( 3, '2025-03-03 09:00:00',  93600, 'completada'),
( 5, '2025-03-04 10:15:00',  71400, 'completada'), ( 2, '2025-03-05 11:45:00',  28900, 'completada'),
( 3, '2025-03-06 14:00:00', 118000, 'completada'), ( 5, '2025-03-07 08:00:00',  54700, 'completada'),
( 2, '2025-03-08 09:30:00', 102000, 'completada'), ( 3, '2025-03-10 10:00:00',  42500, 'completada'),
( 5, '2025-03-11 11:15:00', 136000, 'completada'), ( 2, '2025-03-12 14:45:00',  77800, 'completada'),
( 3, '2025-03-13 08:30:00',  63400, 'completada'), ( 5, '2025-03-14 09:00:00', 109000, 'completada'),
( 2, '2025-03-15 10:30:00',  48200, 'completada'), ( 3, '2025-03-17 11:00:00',  89700, 'completada'),
( 5, '2025-03-18 14:15:00',  61500, 'completada'), ( 2, '2025-03-20 08:45:00', 151000, 'completada'),
( 3, '2025-03-22 09:15:00',  34600, 'completada'), ( 5, '2025-03-24 10:45:00', 105000, 'completada'),
( 2, '2025-03-26 11:30:00',  78300, 'completada'), ( 3, '2025-03-28 14:00:00',  66900, 'completada');

#Pedidos 10 registros RQF-24 
INSERT INTO pedidos (id_proveedor, id_usuario, fecha_pedido, fecha_entrega, total, estado) VALUES
(1, 1, '2025-01-08', '2025-01-10',   980000, 'recibido'),
(1, 1, '2025-01-20', '2025-01-22',  1250000, 'recibido'),
(1, 4, '2025-02-03', '2025-02-05',   875000, 'recibido'),
(1, 1, '2025-02-15', '2025-02-17',  1540000, 'recibido'),
(1, 1, '2025-02-25', '2025-02-27',   760000, 'recibido'),
(1, 4, '2025-03-05', '2025-03-07',  1120000, 'recibido'),
(1, 1, '2025-03-15', '2025-03-17',   930000, 'recibido'),
(1, 4, '2025-03-22', '2025-03-24',  1380000, 'recibido'),
(1, 1, '2025-04-01', '2025-04-03',  1680000, 'pendiente'),
(1, 4, '2025-04-10', '2025-04-12',   820000, 'pendiente');

#Devoluciones 10 registros RQF-22
INSERT INTO devoluciones (id_venta, id_producto, cantidad, motivo, id_usuario) VALUES
( 3, 12, 1, 'bidon con fuga',                    2),
( 7, 26, 2, 'lata abollada',                     3),
(14,  1, 1, 'botella sin sello de seguridad',    5),
(20, 11, 2, 'producto vencido',                  2),
(25, 13, 1, 'botella golpeada',                  3),
(30, 12, 1, 'tapa defectuosa',                   5),
(35,  2, 3, 'producto con sedimento',            2),
(40, 18, 1, 'etiqueta desprendida',              3),
(45, 26, 2, 'lata oxidada',                      5),
(50, 11, 1, 'fecha de vencimiento ilegible',     2);

#Detalle de ventas 80 líneas RQF-18
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario) VALUES
( 1,  1,  4, 5087), ( 1, 11,  6, 1833), ( 1, 13,  3, 1641),
( 2,  2,  5, 2711), ( 2, 23,  3, 2400),
( 3,  1,  8, 5087), ( 3, 12,  2, 7409), ( 3, 20,  3, 4004),
( 4, 11,  6, 1833), ( 4, 13,  4, 1641),
( 5,  1, 10, 5087), ( 5, 26,  5, 3850), ( 5, 12,  3, 7409),
( 6,  2,  4, 2711), ( 6, 11,  8, 1833),
( 7,  1, 12, 5087), ( 7, 12,  4, 7409), ( 7,  2,  6, 2711),
( 8, 11,  5, 1833), ( 8, 13,  6, 1641), ( 8, 23,  4, 2400),
( 9,  1,  6, 5087), ( 9, 12,  3, 7409), ( 9, 11,  8, 1833),
(10, 13,  8, 1641), (10, 11,  6, 1833), (10, 20,  4, 4004),
(11,  1, 10, 5087), (11, 26,  6, 3850), (11, 12,  4, 7409),
(12, 11,  8, 1833), (12, 12,  3, 7409), (12,  2,  5, 2711),
(13, 13,  6, 1641), (13, 23,  5, 2400), (13, 20,  3, 4004),
(14,  1, 12, 5087), (14,  2,  8, 2711), (14, 26,  6, 3850), (14, 12, 4, 7409),
(15, 11,  6, 1833), (15, 13,  8, 1641), (15, 12,  3, 7409),
(16,  1,  8, 5087), (16, 11,  5, 1833), (16, 13,  6, 1641),
(17,  2,  4, 2711), (17, 26,  3, 3850),
(18,  1, 10, 5087), (18, 12,  3, 7409),
(19, 11,  7, 1833), (19, 13,  5, 1641), (19, 18,  4, 4443),
(20,  1,  6, 5087), (20, 26,  4, 3850), (20, 23,  3, 2400),
(21,  2,  5, 2711), (21, 11,  8, 1833),
(22,  1,  9, 5087), (22, 12,  2, 7409), (22, 20,  4, 4004),
(23, 13,  7, 1641), (23, 11,  6, 1833), (23,  2,  5, 2711),
(24,  1,  8, 5087), (24, 26,  5, 3850),
(25, 11,  9, 1833), (25, 13,  7, 1641), (25, 12,  2, 7409),
(26,  1, 11, 5087), (26, 11,  6, 1833), (26, 26,  4, 3850),
(27,  2,  6, 2711), (27, 13,  5, 1641),
(28,  1,  8, 5087), (28, 12,  3, 7409), (28, 20,  4, 4004),
(29, 11,  7, 1833), (29, 23,  5, 2400),
(30,  1, 10, 5087), (30, 26,  6, 3850), (30, 12,  3, 7409);

#Detalle de pedidos 50 líneas RQF-24
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) VALUES
( 1,  1, 120, 4324), ( 1, 11, 200, 1558), ( 1, 13, 150, 1395), ( 1,  2,  80, 2304), ( 1, 18,  60, 3776),
( 2,  1, 150, 4324), ( 2, 12,  60, 6298), ( 2,  2, 100, 2304), ( 2, 26,  70, 3272), ( 2, 23,  50, 2040),
( 3, 11, 180, 1558), ( 3, 12,  50, 6298), ( 3, 20,  60, 3403), ( 3, 13, 100, 1395), ( 3,  7,  40, 4160),
( 4,  1, 200, 4324), ( 4, 26,  80, 3272), ( 4, 23, 100, 2040), ( 4, 11, 120, 1558), ( 4, 12,  50, 6298),
( 5, 13, 200, 1395), ( 5, 11, 150, 1558), ( 5,  2,  80, 2304), ( 5,  1, 100, 4324), ( 5, 18,  60, 3776),
( 6,  1, 160, 4324), ( 6, 12,  70, 6298), ( 6, 23,  90, 2040), ( 6, 11, 130, 1558), ( 6, 20,  50, 3403),
( 7, 11, 200, 1558), ( 7, 13, 180, 1395), ( 7, 20,  50, 3403), ( 7,  1, 100, 4324), ( 7, 26,  60, 3272),
( 8,  1, 180, 4324), ( 8, 12,  80, 6298), ( 8, 26,  60, 3272), ( 8, 11, 150, 1558), ( 8,  2,  70, 2304),
( 9,  1, 240, 4324), ( 9, 11, 300, 1558), ( 9, 12,  90, 6298), ( 9, 13, 200, 1395), ( 9, 18,  80, 3776),
(10, 13, 200, 1395), (10,  2, 120, 2304), (10, 23,  80, 2040), (10, 11, 150, 1558), (10,  1, 100, 4324);

#CONSULTAS
#RQF-02: Consultar información de un usuario por ID
SELECT id_usuario, nombre, email, rol, activo, fecha_registro
FROM   usuarios
WHERE  id_usuario = 1;

#RQF-04: Listar usuarios activos filtrando por rol
SELECT nombre, email, rol, activo
FROM   usuarios
WHERE  activo = 1
ORDER  BY rol, nombre;

#RQF-07: Listar categorías con conteo de productos
SELECT c.id_categoria, c.nombre, c.descripcion,
       COUNT(p.id_producto) AS total_productos
FROM   categorias c
LEFT   JOIN productos p ON p.id_categoria = c.id_categoria AND p.activo = 1
GROUP  BY c.id_categoria, c.nombre, c.descripcion
ORDER  BY total_productos DESC;

#RQF-09: Consultar información de un proveedor
SELECT * FROM proveedores WHERE id_proveedor = 1;

#RQF-11: Productos por proveedor con valor total de inventario
SELECT pv.nombre                             AS proveedor,
       COUNT(p.id_producto)                  AS total_productos,
       SUM(p.stock_actual * p.precio_compra) AS valor_total_inventario
FROM   productos p
JOIN   proveedores pv ON p.id_proveedor = pv.id_proveedor
GROUP  BY pv.id_proveedor, pv.nombre
ORDER  BY valor_total_inventario DESC;

#RQF-13: Consultar información detallada de un producto
SELECT p.id_producto, p.nombre,
       c.nombre  AS categoria,
       pv.nombre AS proveedor,
       p.precio_compra, p.precio_venta,
       p.stock_actual, p.stock_minimo,
       p.fecha_vencimiento, p.unidad_medida, p.activo
FROM   productos   p
JOIN   categorias  c  ON p.id_categoria = c.id_categoria
JOIN   proveedores pv ON p.id_proveedor = pv.id_proveedor
WHERE  p.id_producto = 1;

#RQF-16: Filtrar productos activos por categoría
SELECT p.nombre, p.precio_venta, p.stock_actual, p.stock_minimo
FROM   productos  p
JOIN   categorias c ON p.id_categoria = c.id_categoria
WHERE  c.nombre = 'gaseosas' AND p.activo = 1
ORDER  BY p.precio_venta DESC;

#RQF-22: Consultar una venta con su empleado responsable
SELECT v.id_venta, v.fecha_venta, v.estado, v.total, u.nombre AS empleado
FROM   ventas   v
JOIN   usuarios u ON v.id_usuario = u.id_usuario
WHERE  v.id_venta = 1;

#RQF-25: Consultar pedidos pendientes de entrega
SELECT p.id_pedido, pv.nombre AS proveedor,
       p.fecha_pedido, p.fecha_entrega, p.total, p.estado
FROM   pedidos    p
JOIN   proveedores pv ON p.id_proveedor = pv.id_proveedor
WHERE  p.estado = 'pendiente'
ORDER  BY p.fecha_entrega ASC;

#RQF-27: Consultar pedidos por proveedor en rango de fechas
SELECT p.id_pedido, pv.nombre AS proveedor,
       p.fecha_pedido, p.fecha_entrega, p.total, p.estado
FROM   pedidos    p
JOIN   proveedores pv ON p.id_proveedor = pv.id_proveedor
WHERE  pv.id_proveedor = 1
  AND  DATE(p.fecha_pedido) BETWEEN '2025-01-01' AND '2025-03-31'
ORDER  BY p.fecha_pedido;

#RQF-28: Alertas de stock bajo
SELECT producto, categoria, stock_actual, stock_minimo,
       (stock_minimo - stock_actual) AS unidades_faltantes
FROM   v_inventario_alertas
WHERE  alerta_stock = 'STOCK BAJO'
ORDER  BY unidades_faltantes DESC;

# RQF-29: Productos próximos a vencer o ya vencidos
SELECT producto, fecha_vencimiento, dias_para_vencer,
       stock_actual, alerta_vencimiento
FROM   v_inventario_alertas
WHERE  alerta_vencimiento IN ('VENCIDO', 'VENCE PRONTO')
ORDER  BY dias_para_vencer ASC;

#RQF-30: Valorización del inventario actual
SELECT producto, categoria, stock_actual, precio_compra, valor_inventario
FROM   v_inventario_alertas
ORDER  BY valor_inventario DESC;

#RQF-32: Ventas completadas por rango de fechas
SELECT DATE(fecha_venta)     AS fecha,
       COUNT(*)               AS num_ventas,
       SUM(total)             AS total_dia,
       ROUND(AVG(total), 2)   AS ticket_promedio
FROM   ventas
WHERE  estado = 'completada'
  AND  DATE(fecha_venta) BETWEEN '2025-01-01' AND '2025-03-31'
GROUP  BY DATE(fecha_venta)
ORDER  BY fecha DESC;

#RQF-33: Reporte detallado de ventas consulta multitabla 5 tablas
SELECT v.id_venta,
       DATE(v.fecha_venta) AS fecha,
       u.nombre            AS empleado,
       p.nombre            AS producto,
       c.nombre            AS categoria,
       dv.cantidad,
       dv.precio_unitario,
       dv.subtotal
FROM   ventas        v
JOIN   usuarios      u  ON v.id_usuario   = u.id_usuario
JOIN   detalle_venta dv ON dv.id_venta    = v.id_venta
JOIN   productos     p  ON dv.id_producto = p.id_producto
JOIN   categorias    c  ON p.id_categoria = c.id_categoria
WHERE  v.estado = 'completada'
ORDER  BY v.fecha_venta DESC, v.id_venta
LIMIT  20;

#RQF-34: Top 10 productos más vendidos
SELECT producto, categoria, total_unidades, total_ingresos, num_transacciones
FROM   v_ventas_por_producto
ORDER  BY total_unidades DESC
LIMIT  10;

#RQF-35: Ventas mensuales comparativas — multitabla + agrupación
SELECT YEAR(v.fecha_venta)        AS anio,
       MONTH(v.fecha_venta)       AS mes,
       COUNT(v.id_venta)          AS num_ventas,
       SUM(v.total)               AS total_mensual,
       ROUND(AVG(v.total), 2)     AS ticket_promedio,
       MAX(v.total)               AS venta_maxima_mes
FROM   ventas   v
JOIN   usuarios u ON v.id_usuario = u.id_usuario
WHERE  v.estado = 'completada'
GROUP  BY YEAR(v.fecha_venta), MONTH(v.fecha_venta)
ORDER  BY anio, mes;

#RQF-36: Rotación mensual y promedio diario
SELECT producto, categoria, anio, mes, unidades_vendidas, promedio_diario
FROM   v_rotacion_mensual
ORDER  BY anio, mes, unidades_vendidas DESC
LIMIT  20;

#RQF-37: Margen de ganancia bruto y porcentual por producto
SELECT nombre, precio_compra, precio_venta,
       (precio_venta - precio_compra)                               AS margen_bruto,
       ROUND(((precio_venta - precio_compra) / precio_compra) * 100, 2) AS margen_pct
FROM   productos
WHERE  activo = 1
ORDER  BY margen_pct DESC;

#RQF-38: Clasificación ABC dinámica
SELECT nombre, precio_venta,
       CASE
           WHEN precio_venta >= (
               SELECT precio_venta FROM productos WHERE activo = 1
               ORDER BY precio_venta DESC
               LIMIT 1 OFFSET (SELECT FLOOR(COUNT(*) * 0.20) FROM productos WHERE activo = 1)
           ) THEN 'A - Alto valor'
           WHEN precio_venta >= (
               SELECT precio_venta FROM productos WHERE activo = 1
               ORDER BY precio_venta DESC
               LIMIT 1 OFFSET (SELECT FLOOR(COUNT(*) * 0.50) FROM productos WHERE activo = 1)
           ) THEN 'B - Valor medio'
           ELSE     'C - Bajo valor'
       END AS clasificacion_abc
FROM   productos
WHERE  activo = 1
ORDER  BY precio_venta DESC;

#RQF-39: KPIs mensuales para Power BI
SELECT * FROM v_kpi_mensual ORDER BY anio, mes;

#RQF-34 subconsulta: Productos con ventas superiores al promedio general
SELECT p.nombre, SUM(dv.cantidad) AS total_vendido
FROM   detalle_venta dv
JOIN   productos p ON dv.id_producto = p.id_producto
GROUP  BY p.id_producto, p.nombre
HAVING SUM(dv.cantidad) > (
    SELECT AVG(total_x_prod)
    FROM (SELECT SUM(cantidad) AS total_x_prod
          FROM   detalle_venta
          GROUP  BY id_producto) AS sub
)
ORDER  BY total_vendido DESC;

#RQF-39 subconsulta: Categorías cuyo ingreso supera el promedio
SELECT c.nombre AS categoria, SUM(dv.subtotal) AS ingresos
FROM   detalle_venta dv
JOIN   productos  p ON dv.id_producto = p.id_producto
JOIN   categorias c ON p.id_categoria = c.id_categoria
GROUP  BY c.id_categoria, c.nombre
HAVING SUM(dv.subtotal) > (
    SELECT AVG(ingreso_cat)
    FROM (SELECT SUM(dv2.subtotal) AS ingreso_cat
          FROM   detalle_venta dv2
          JOIN   productos p2 ON dv2.id_producto = p2.id_producto
          GROUP  BY p2.id_categoria) AS sub2
)
ORDER  BY ingresos DESC;

#RQF-19 prueba SP: registrar venta y verificar descuento de stock
CALL sp_registrar_venta(2, 1, 5, @id_venta_nuevo, @msg_venta);
SELECT @id_venta_nuevo AS venta_creada, @msg_venta AS resultado;

#RQF-40: Reporte consolidado enero–marzo 2025
CALL sp_reporte_ventas('2025-01-01', '2025-03-31');

#MODIFICACIONES Y ELIMINACIÓN
#RQF-14 MOD-1: Actualizar precio activa trg_historial_precios
UPDATE productos
SET    precio_venta = 7650
WHERE  nombre = 'agua brisa bidon x 6 litros';

#RQF-14 MOD-2: Aumentar stock_mínimo de producto de alta rotación
UPDATE productos
SET    stock_minimo = 10
WHERE  nombre = 'gas. coca cola x 1.5 lt';

#RQF-15 MOD-3: Inactivar producto descontinuado
UPDATE productos
SET    activo = 0
WHERE  nombre = 'agua brisa limon bot x 1.5 lt';

#RQF-10 MOD-4: Actualizar correo del proveedor
UPDATE proveedores
SET    email = 'nuevopedidos@coca-cola.com.co'
WHERE  nombre = 'femsa coca-cola colombia';

#RQF-21 MOD-5: Anular venta por error del sistema
UPDATE ventas
SET    estado = 'anulada',
       observaciones = 'Venta duplicada por error del sistema'
WHERE  id_venta = 5;

#RQF-04 MOD-6: Inactivar usuario que dejó de trabajar en la tienda
UPDATE usuarios
SET    activo = 0
WHERE  email = 'emp8@tienda.com';

#RQF-05 MOD-7: Actualizar contraseña cifrada de un usuario
UPDATE usuarios
SET    clave_hash = '$2b$10$nuevo_hash_seguro_2026'
WHERE  email = 'emp1@tienda.com';

#RQF-14 MOD-8: Corrección de precio por ajuste del proveedo
UPDATE productos
SET    precio_compra = 4500,
       precio_venta  = 5300
WHERE  nombre = 'gas. coca cola x 1.5 lt';

#RQF-23 ELI-1: Eliminar devolución por error 
DELETE FROM devoluciones WHERE id_devolucion = 5;

#RQF-26: Recibir pedido pendiente y verificar actualización de stock
SELECT nombre, stock_actual AS stock_antes FROM productos WHERE id_producto = 1;
CALL sp_recibir_pedido(9, @msg_pedido);
SELECT @msg_pedido AS resultado_pedido;
SELECT nombre, stock_actual AS stock_despues FROM productos WHERE id_producto = 1;

#RESUMEN FINAL DEL MODELO FÍSICO
SELECT
    (SELECT COUNT(*) FROM information_schema.TABLES
     WHERE  TABLE_SCHEMA = 'tienda_don_pepe'
       AND  TABLE_TYPE   = 'BASE TABLE')                                AS total_tablas,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE  TABLE_SCHEMA = 'tienda_don_pepe')                           AS total_campos,
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE  TABLE_SCHEMA    = 'tienda_don_pepe'
       AND  CONSTRAINT_TYPE = 'PRIMARY KEY')                            AS total_pk,
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE  TABLE_SCHEMA    = 'tienda_don_pepe'
       AND  CONSTRAINT_TYPE = 'FOREIGN KEY')                            AS total_fk,
    (SELECT COUNT(*) FROM information_schema.TRIGGERS
     WHERE  TRIGGER_SCHEMA  = 'tienda_don_pepe')                        AS total_triggers,
    (SELECT COUNT(*) FROM information_schema.ROUTINES
     WHERE  ROUTINE_SCHEMA  = 'tienda_don_pepe'
       AND  ROUTINE_TYPE    = 'PROCEDURE')                              AS total_sp,
    (SELECT COUNT(*) FROM information_schema.VIEWS
     WHERE  TABLE_SCHEMA    = 'tienda_don_pepe')                        AS total_vistas;

SELECT hp.id_historial,
       pr.nombre            AS producto,
       hp.precio_venta_anterior,
       hp.precio_venta_nuevo,
       hp.fecha_cambio
FROM   historial_precios hp
JOIN   productos pr ON hp.id_producto = pr.id_producto
ORDER  BY hp.fecha_cambio DESC;

SELECT tabla_afectada, tipo_operacion, descripcion, fecha_operacion
FROM   auditoria_movimientos
ORDER  BY fecha_operacion DESC;
