/*
Juan David Sanchez Angaria
*/

CREATE DATABASE companiaseguros;
USE companiaseguros;

CREATE TABLE compania(
    idcompania VARCHAR(50) PRIMARY KEY,
    nit VARCHAR(20) UNIQUE NOT NULL,
    nombreCompania VARCHAR(50) NOT NULL,
    fechafundacion DATE NULL,
    representantelegal VARCHAR(50) NOT NULL
);

CREATE TABLE automovil (
    idauto VARCHAR(50) PRIMARY KEY,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    anofabricacion INT NOT NULL,
    serialchasis VARCHAR(50) NOT NULL,
    pasajeros INT NOT NULL,
    cilindraje DOUBLE NOT NULL
);

CREATE TABLE accidente(
    idaccidente VARCHAR(50) PRIMARY KEY,
    fechaaccidente DATE NOT NULL,
    lugar VARCHAR(50) NOT NULL,
    heridos INT NULL,
    fatalidades INT NULL,
    automotores INT NOT NULL
);

CREATE TABLE seguros(
    idseguro VARCHAR(50) PRIMARY KEY,
    estado VARCHAR(20) NOT NULL,
    costo DOUBLE NOT NULL,
    fechainicio DATE NOT NULL,
    fechaexpiracion DATE NOT NULL,
    valorasegurado DOUBLE NOT NULL,
    idcompaniaFK VARCHAR(50) NOT NULL,
    idautomovilFK VARCHAR(50) NOT NULL
);

CREATE TABLE detallesaccidente(
    iddetalle INT PRIMARY KEY,
    idaccidenteFK VARCHAR(50) NOT NULL,
    idautoFK VARCHAR(50) NOT NULL
);

ALTER TABLE seguros
ADD CONSTRAINT FKCompaniaSeguros
FOREIGN KEY (idcompaniaFK)
REFERENCES compania(idcompania);

ALTER TABLE seguros
ADD CONSTRAINT FKSegurosAutomovil
FOREIGN KEY (idautomovilFK)
REFERENCES automovil(idauto);

ALTER TABLE detallesaccidente
ADD CONSTRAINT FKDetalleAccidente
FOREIGN KEY (idaccidenteFK)
REFERENCES accidente(idaccidente);

ALTER TABLE detallesaccidente
ADD CONSTRAINT FKDetalleAutomovil
FOREIGN KEY (idautoFK)
REFERENCES automovil(idauto);

ALTER TABLE compania
ADD direccionCompania VARCHAR(50) NOT NULL;

RENAME TABLE automovil TO carros;

ALTER TABLE seguros
DROP COLUMN valorasegurado;

ALTER TABLE seguros
DROP FOREIGN KEY FKSegurosAutomovil;