-- =====================================================
-- DDL: CREACION DE BASE DE DATOS Y TABLAS
-- =====================================================
DROP DATABASE IF EXISTS tienda_tech;
CREATE DATABASE tienda_tech CHARACTER SET utf8mb4;
USE tienda_tech;

CREATE TABLE clientes (
    cliente_id      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    ciudad          VARCHAR(60),
    fecha_registro  DATE DEFAULT (CURRENT_DATE)
);

CREATE TABLE productos (
    producto_id  INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    categoria    VARCHAR(60),
    precio       DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    stock        INT DEFAULT 0
);

CREATE TABLE pedidos (
    pedido_id    INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id   INT NOT NULL,
    producto_id  INT NOT NULL,
    cantidad     INT NOT NULL CHECK (cantidad > 0),
    fecha_pedido DATE DEFAULT (CURRENT_DATE),
    estado       VARCHAR(20) DEFAULT "pendiente"
        CHECK (estado IN ("pendiente","entregado","cancelado")),
    FOREIGN KEY (cliente_id)  REFERENCES clientes(cliente_id),
    FOREIGN KEY (producto_id) REFERENCES productos(producto_id)
);

-- =====================================================
-- DML: DATOS DE PRUEBA
-- =====================================================
INSERT INTO clientes VALUES
(1,1,1,1,"2024-01-10","entregado"),(2,1,2,2,"2024-01-15","entregado"),
 (3,2,3,1,"2024-02-05","entregado"),(4,2,5,1,"2024-02-20","cancelado"),
 (5,3,4,1,"2024-03-01","entregado"),(6,3,7,2,"2024-03-15","pendiente"),
 (7,4,2,3,"2024-04-02","entregado"),(8,4,6,1,"2024-04-10","pendiente"),
 (9,5,8,1,"2024-04-18","entregado"),(10,6,1,2,"2024-05-05","entregado"),
 (11,6,3,1,"2024-05-12","pendiente"),(12,7,5,2,"2024-05-20","entregado"),
 (13,1,7,1,"2024-06-01","entregado"),(14,8,4,1,"2024-06-10","cancelado"),
 (15,5,2,4,"2024-06-15","entregado"),(16,3,1,1,"2024-07-01","pendiente");

#PUNTO 16

CREATE OR REPLACE VIEW vista_clientes_vip AS
    SELECT
        c.cliente_id,
        c.nombre,
        c.ciudad,
        COUNT(p.pedido_id) AS total_pedidos_entregados
    FROM clientes c
    INNER JOIN pedidos p ON c.cliente_id = p.cliente_id
    WHERE p.estado = 'entregado'
    GROUP BY
        c.cliente_id,
        c.nombre,
        c.ciudad
    HAVING COUNT(p.pedido_id) > (
        SELECT AVG(conteo)
        FROM (
            SELECT COUNT(pedido_id) AS conteo
            FROM pedidos
            WHERE estado = 'entregado'
            GROUP BY cliente_id
        ) AS sub
    );

-- Verificacion de la vista
SELECT * FROM vista_clientes_vip;

SELECT
    detalle.nombre_cliente,
    detalle.nombre_producto,
    detalle.fecha_pedido
FROM (
    SELECT
        vip.nombre       AS nombre_cliente,
        pr.nombre        AS nombre_producto,
        pe.fecha_pedido,
        ROW_NUMBER() OVER (
            PARTITION BY vip.cliente_id
            ORDER BY pe.fecha_pedido DESC
        ) AS rn
    FROM vista_clientes_vip vip
    INNER JOIN pedidos   pe ON vip.cliente_id  = pe.cliente_id
    INNER JOIN productos pr ON pe.producto_id  = pr.producto_id
) AS detalle
WHERE detalle.rn <= 2
ORDER BY detalle.nombre_cliente, detalle.fecha_pedido DESC;