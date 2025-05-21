CREATE DATABASE TiendaDeTemporada;

-- \c TiendaDeTemporada

﻿-- Usar master para poder eliminar la BD si existe


-- Crear la base de datos
CREATE DATABASE TiendaDeTemporada;


-- Usar la nueva base de datos


-- Crear esquemas
CREATE SCHEMA ClientesInfo;
go
CREATE SCHEMA ComprasInfo;
go
CREATE SCHEMA ProductoInfo;
go
CREATE SCHEMA VentasInfo;



-- Tablas ClienteInfo
CREATE TABLE ClientesInfo.Cliente(
    id_cliente BIGSERIAL NOT NULL,
    nombre_cliente VARCHAR(200) NOT NULL,
    direccion_cliente VARCHAR(300) NOT NULL,
    telefono_cliente VARCHAR(20),
    correo_cliente VARCHAR(100),
    CONSTRAINT PKCliente PRIMARY KEY(id_cliente)
);

CREATE TABLE ClientesInfo.Tarjeta_Cliente(
    id_tarjeta_cliente BIGSERIAL NOT NULL UNIQUE,
    id_cliente BIGINT NOT NULL,
    numero_tarjeta VARCHAR(20) UNIQUE NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    banco VARCHAR(50) NOT NULL,
    codigo_seguridad VARCHAR(10) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    CONSTRAINT PKTarjetaCliente PRIMARY KEY (id_tarjeta_cliente),
    CONSTRAINT FKTarjeta_Cliente FOREIGN KEY(id_cliente) 
        REFERENCES ClientesInfo.Cliente(id_cliente)
);

-- Tablas ProductoInfo
CREATE TABLE ProductoInfo.Producto (
    id_producto BIGSERIAL,
    nombre_producto VARCHAR(200) UNIQUE NOT NULL,
    precio_producto DECIMAL(10,2) NOT NULL,
    existencias INT NOT NULL DEFAULT 0,
    CONSTRAINT PKProducto PRIMARY KEY (id_producto)
);

-- Tablas ComprasInfo
CREATE TABLE ComprasInfo.Proveedor (
    id_proveedor BIGSERIAL,
    nombre_proveedor VARCHAR(200) NOT NULL,
    direccion_proveedor VARCHAR(300) NOT NULL,
    telefono_proveedor VARCHAR(20) UNIQUE,
    correo_proveedor VARCHAR(100) UNIQUE,
    CONSTRAINT PKProvedor PRIMARY KEY (id_proveedor)
);

CREATE TABLE ProductoInfo.Temporada (
    id_temporada BIGSERIAL,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
	CONSTRAINT PKTemporada PRIMARY KEY (id_temporada)
);

CREATE TABLE ProductoInfo.Producto_Temporada (
    id_producto_temporada BIGSERIAL,
    id_producto BIGINT NOT NULL,
    id_temporada BIGINT NOT NULL,
	CONSTRAINT PKProductoTemporada PRIMARY KEY (id_producto_temporada),
    CONSTRAINT FKProductoTemporada_Producto FOREIGN KEY (id_producto) REFERENCES ProductoInfo.Producto(id_producto),
    CONSTRAINT FKProductoTemporada_Temporada FOREIGN KEY (id_temporada) REFERENCES ProductoInfo.Temporada(id_temporada),
	CONSTRAINT UQ_Producto_Temporada UNIQUE (id_producto, id_temporada)
);


CREATE TABLE ComprasInfo.Compra (
    id_compra BIGSERIAL,
    id_proveedor BIGINT NOT NULL,
    fecha_compra DATE NOT NULL,
    total_compra DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT PKCompra PRIMARY KEY (id_compra),
    CONSTRAINT FKProvedorCompras FOREIGN KEY (id_proveedor) REFERENCES ComprasInfo.Proveedor(id_proveedor)
);

CREATE TABLE ComprasInfo.Detalle_Compra (
    id_compra BIGINT NOT NULL,
    id_producto_temporada BIGINT NOT NULL,
    cantidad INT NOT NULL,
    subtotal_compra DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT PKDetalleCompra PRIMARY KEY (id_compra, id_producto_temporada),
    CONSTRAINT FKDetalleCompra_Compra FOREIGN KEY (id_compra) REFERENCES ComprasInfo.Compra(id_compra),
    CONSTRAINT FKDetalleCompra_Producto FOREIGN KEY (id_producto_temporada) REFERENCES ProductoInfo.Producto_Temporada(id_producto_temporada)
);



-- Tablas VentasInfo
CREATE TABLE VentasInfo.Venta (
    id_venta BIGSERIAL NOT NULL,
    id_tarjeta_cliente BIGINT NOT NULL,
    fecha_venta DATE NOT NULL,
    total_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT PKVenta PRIMARY KEY (id_venta),
    CONSTRAINT FKVenta_Tarjeta FOREIGN KEY (id_tarjeta_cliente) REFERENCES ClientesInfo.Tarjeta_Cliente(id_tarjeta_cliente)
);

CREATE TABLE VentasInfo.Detalle_Venta (
    id_venta BIGINT NOT NULL,
    id_producto_temporada BIGINT NOT NULL,
    cantidad INT NOT NULL,
    subtotal_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    --CONSTRAINT PKDetalleVenta PRIMARY KEY (id_venta, id_producto_temporada),
    CONSTRAINT FKDetalleVenta_Venta FOREIGN KEY (id_venta) REFERENCES VentasInfo.Venta(id_venta),
    CONSTRAINT FKDetalleVenta_Producto FOREIGN KEY (id_producto_temporada) REFERENCES ProductoInfo.Producto_Temporada(id_producto_temporada)
);


--Utiliza disparador
CREATE TABLE VentasInfo.Apartado (
    id_apartado BIGSERIAL NOT NULL,
    id_tarjeta_cliente BIGINT NOT NULL,
    total_apartado DECIMAL(10,2) NOT NULL,
    fecha_creacion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    saldo_pendiente DECIMAL(10,2), --Ponerle default el total_apartado inicial, Cambia con disparador de abonos (saldo_pendoiente -= abono.cantidad)
    estado VARCHAR(50) NOT NULL, --Se actualiza a liquidado cuando saldo_pendiente sea 0, ver debajo mas instrucciones
	CONSTRAINT PKApartado PRIMARY KEY (id_apartado),
    CONSTRAINT FKApartado_tarjeta FOREIGN KEY (id_tarjeta_cliente) REFERENCES ClientesInfo.Tarjeta_Cliente(id_tarjeta_cliente)
);
--Cuando sea un estado liquitado, se generara una tupla en venta y los respectivos detalles venta

CREATE TABLE VentasInfo.Producto_Apartado (
    id_producto BIGINT NOT NULL,
    id_apartado BIGINT NOT NULL,
    cantidad INT NOT NULL,
    subtotal_apartado DECIMAL(10,2), --Con disparador (cantidad * producto.precio) 
    CONSTRAINT PKProductoApartado PRIMARY KEY (id_producto, id_apartado),
    CONSTRAINT PKProductoApartado_Producto FOREIGN KEY (id_producto) REFERENCES ProductoInfo.Producto(id_producto),
    CONSTRAINT PKProductoApartado_Apartado FOREIGN KEY (id_apartado) REFERENCES VentasInfo.Apartado(id_apartado)
);
ALTER TABLE VentasInfo.Producto_Apartado
ADD CONSTRAINT CHK_Cantidad_Positive CHECK (cantidad > 0);
-- 1. Elimina solo la FK que apunta a Apartado
ALTER TABLE VentasInfo.Producto_Apartado
DROP CONSTRAINT PKProductoApartado_Apartado;
-- 2. Vuelve a crearla con ON DELETE CASCADE
ALTER TABLE VentasInfo.Producto_Apartado
ADD CONSTRAINT FK_ProductoApartado_Apartado
FOREIGN KEY (id_apartado)
REFERENCES VentasInfo.Apartado(id_apartado)
ON DELETE CASCADE;

CREATE TABLE VentasInfo.Abono (
    id_abono BIGSERIAL ,
    id_apartado BIGINT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    fecha_abono DATE NOT NULL,
	CONSTRAINT PKAbono PRIMARY KEY(id_abono),
    CONSTRAINT PKAbono_apartado FOREIGN KEY (id_apartado) REFERENCES VentasInfo.Apartado(id_apartado)
);
-- Elimina la FK actual
ALTER TABLE VentasInfo.Abono
DROP CONSTRAINT PKAbono_apartado;
-- Agrega de nuevo con cascada
ALTER TABLE VentasInfo.Abono
ADD CONSTRAINT FK_Abono_Apartado
FOREIGN KEY (id_apartado)
REFERENCES VentasInfo.Apartado(id_apartado)
ON DELETE CASCADE;
Go
--
-- LISTO HASTA AQUI
-- LISTO HASTA AQUI
-- LISTO HASTA AQUI
--

-- Triggers del MIKE
-- 1. Comprobar que la cantidad del abono no sea mayor al saldo pendiente
-- Primero crea la función que será llamada por el trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_validar_abono()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar que el abono no exceda el saldo pendiente
    PERFORM 1
    FROM VentasInfo.Apartado a
    WHERE a.id_apartado = NEW.id_apartado
      AND NEW.cantidad > a.saldo_pendiente;

    IF FOUND THEN
        RAISE EXCEPTION 'No se puede abonar más de lo que se debe.';
    END IF;

    -- Si pasa la validación, dejar que el insert continúe
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ahora crea el trigger que llama a esa función
CREATE TRIGGER trg_validar_abono
BEFORE INSERT ON VentasInfo.Abono
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_validar_abono();


--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
-- Función del trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_after_insert_producto_apartado()
RETURNS TRIGGER AS $$
BEGIN
    -- 1️⃣ Restar existencias
    UPDATE ProductoInfo.Producto
    SET existencias = existencias - NEW.cantidad
    WHERE id_producto = NEW.id_producto;

    -- 2️⃣ Aumentar total_apartado y saldo_pendiente
    UPDATE VentasInfo.Apartado
    SET total_apartado = total_apartado + (NEW.cantidad * p.precio_producto),
        saldo_pendiente = saldo_pendiente + (NEW.cantidad * p.precio_producto)
    FROM ProductoInfo.Producto p
    WHERE VentasInfo.Apartado.id_apartado = NEW.id_apartado
      AND p.id_producto = NEW.id_producto;

    RETURN NULL; -- AFTER triggers retornan NULL
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_after_insert_producto_apartado
AFTER INSERT ON VentasInfo.Producto_Apartado
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_after_insert_producto_apartado();



--DELETE
-- Función del trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_after_delete_producto_apartado()
RETURNS TRIGGER AS $$
BEGIN
    -- 1️⃣ Devolver existencias al producto
    UPDATE ProductoInfo.Producto
    SET existencias = existencias + OLD.cantidad
    WHERE id_producto = OLD.id_producto;

    -- 2️⃣ Restar al total_apartado y saldo_pendiente
    UPDATE VentasInfo.Apartado
    SET total_apartado = total_apartado - OLD.subtotal_apartado,
        saldo_pendiente = saldo_pendiente - OLD.subtotal_apartado
    WHERE id_apartado = OLD.id_apartado;

    RETURN NULL; -- AFTER triggers retornan NULL
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_after_delete_producto_apartado
AFTER DELETE ON VentasInfo.Producto_Apartado
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_after_delete_producto_apartado();



--UPDATE
-- Función del trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_after_update_producto_apartado()
RETURNS TRIGGER AS $$
BEGIN
    -- 1️⃣ Si cambió el producto: reponer existencias al viejo y descontar al nuevo
    IF OLD.id_producto <> NEW.id_producto THEN
        -- Reponer al anterior
        UPDATE ProductoInfo.Producto
        SET existencias = existencias + OLD.cantidad
        WHERE id_producto = OLD.id_producto;

        -- Descontar al nuevo
        UPDATE ProductoInfo.Producto
        SET existencias = existencias - NEW.cantidad
        WHERE id_producto = NEW.id_producto;
    ELSIF OLD.cantidad <> NEW.cantidad THEN
        -- 2️⃣ Si solo cambió la cantidad (mismo producto), ajustar diferencia
        UPDATE ProductoInfo.Producto
        SET existencias = existencias + OLD.cantidad - NEW.cantidad
        WHERE id_producto = NEW.id_producto;
    END IF;

    -- 3️⃣ Recalcular total_apartado y saldo_pendiente
    UPDATE VentasInfo.Apartado
    SET total_apartado = total_apartado - OLD.subtotal_apartado + (NEW.cantidad * p.precio_producto),
        saldo_pendiente = saldo_pendiente - OLD.subtotal_apartado + (NEW.cantidad * p.precio_producto)
    FROM ProductoInfo.Producto p
    WHERE VentasInfo.Apartado.id_apartado = NEW.id_apartado
      AND p.id_producto = NEW.id_producto;

    RETURN NULL; -- AFTER triggers retornan NULL
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_after_update_producto_apartado
AFTER UPDATE ON VentasInfo.Producto_Apartado
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_after_update_producto_apartado();



--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
--Triggers de Apartado y Producto_Apartado
-- 2. Actualizar saldo pendiente tras un abono
-- Función del trigger
-- DROP TRIGGER IF EXISTS trg_after_insert_abono ON VentasInfo.Abono;

CREATE OR REPLACE FUNCTION VentasInfo.trg_after_insert_abono()
RETURNS TRIGGER AS $$
BEGIN
    -- 1️⃣ Descontar el abono del saldo pendiente
    UPDATE VentasInfo.Apartado v
    SET saldo_pendiente = v.saldo_pendiente - NEW.cantidad
    WHERE v.id_apartado = NEW.id_apartado;

    -- 2️⃣ Marcar como "Liquidado" si ya no se debe nada
    UPDATE VentasInfo.Apartado v
    SET estado = 'Liquidado'
    WHERE v.id_apartado = NEW.id_apartado AND v.saldo_pendiente = 0;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_after_insert_abono
AFTER INSERT ON VentasInfo.Abono
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_after_insert_abono();


-- Función del trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_validar_update_abono()
RETURNS TRIGGER AS $$
DECLARE
    saldo_actual DECIMAL(10,2);
BEGIN
    -- Obtener el saldo pendiente actual del apartado
    SELECT saldo_pendiente INTO saldo_actual
    FROM VentasInfo.Apartado
    WHERE id_apartado = NEW.id_apartado;

    -- Validar que el nuevo abono no exceda el saldo permitido (saldo + lo que ya tenía)
    IF NEW.cantidad > (saldo_actual + OLD.cantidad) THEN
        RAISE EXCEPTION 'No puedes actualizar el abono a una cantidad mayor al saldo pendiente.';
    END IF;

    -- Actualizar el saldo del apartado
    UPDATE VentasInfo.Apartado
    SET saldo_pendiente = saldo_pendiente - (NEW.cantidad - OLD.cantidad),
        estado = CASE 
                    WHEN saldo_pendiente - (NEW.cantidad - OLD.cantidad) = 0 
                    THEN 'Liquidado' 
                    ELSE estado 
                 END
    WHERE id_apartado = NEW.id_apartado;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_validar_update_abono
BEFORE UPDATE ON VentasInfo.Abono
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_validar_update_abono();



-- Trigger para inicializar saldo_pendiente con total_apartado
-- Función del trigger
CREATE OR REPLACE FUNCTION VentasInfo.trg_set_saldo_pendiente()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE VentasInfo.Apartado
    SET saldo_pendiente = NEW.total_apartado
    WHERE id_apartado = NEW.id_apartado;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_set_saldo_pendiente
AFTER INSERT ON VentasInfo.Apartado
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_set_saldo_pendiente();




-- 5. Convertir Apartado en Venta cuando sea liquidado
--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO
--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO
--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO
--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO
--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO--LISTO

-- Creamos la función corregida
DROP TRIGGER IF EXISTS trg_update_apartado_to_liquidado ON VentasInfo.Apartado;

CREATE OR REPLACE FUNCTION VentasInfo.trg_update_apartado_to_liquidado()
RETURNS TRIGGER AS $$
DECLARE
    v_id_apartado BIGINT;
    v_id_tarjeta_cliente BIGINT;
    v_total_apartado NUMERIC(10, 2);
    v_id_venta BIGINT;
BEGIN
    -- Verificar si el estado cambió a 'Liquidado'
    IF NEW.estado = 'Liquidado' AND OLD.estado <> 'Liquidado' THEN
        v_id_apartado := NEW.id_apartado;
        v_id_tarjeta_cliente := NEW.id_tarjeta_cliente;
        v_total_apartado := NEW.total_apartado;

        -- Reponer existencias
        UPDATE ProductoInfo.Producto p
        SET existencias = p.existencias + pa.cantidad
        FROM VentasInfo.Producto_Apartado pa
        WHERE p.id_producto = pa.id_producto
          AND pa.id_apartado = v_id_apartado;

        -- Insertar en Venta
        INSERT INTO VentasInfo.Venta (id_tarjeta_cliente, fecha_venta, total_venta)
        VALUES (v_id_tarjeta_cliente, CURRENT_DATE, 0)
        RETURNING id_venta INTO v_id_venta;

        -- Insertar en Detalle_Venta
        INSERT INTO VentasInfo.Detalle_Venta (id_venta, id_producto_temporada, cantidad, subtotal_venta)
        SELECT v_id_venta, pt.id_producto_temporada, pa.cantidad, pa.subtotal_apartado
        FROM VentasInfo.Producto_Apartado pa
        JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto = pa.id_producto
        WHERE pa.id_apartado = v_id_apartado;

        -- Actualizar total_venta
        UPDATE VentasInfo.Venta
        SET total_venta = (
            SELECT SUM(subtotal_venta)
            FROM VentasInfo.Detalle_Venta
            WHERE id_venta = v_id_venta
        )
        WHERE id_venta = v_id_venta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_apartado_to_liquidado
AFTER UPDATE ON VentasInfo.Apartado
FOR EACH ROW
EXECUTE FUNCTION VentasInfo.trg_update_apartado_to_liquidado();



/*
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
VENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTASVENTAS
*/

CREATE TRIGGER [ComprasInfo].[trg_AfterDeleteDetalleCompra]
ON [ComprasInfo].[Detalle_Compra]
AFTER DELETE
AS
DECLARE @total as DECIMAL(10,2);
BEGIN
	UPDATE ProductoInfo.Producto
    SET existencias = existencias - d.cantidad
    FROM ProductoInfo.Producto p
	INNER JOIN ProductoInfo.Producto_Temporada pt ON p.id_producto = pt.id_producto
	INNER JOIN deleted d ON pt.id_producto_temporada = d.id_producto_temporada;

	SET @total = ISNULL((
		SELECT SUM(dc.subtotal_compra)
		FROM ComprasInfo.Detalle_Compra dc
		INNER JOIN ComprasInfo.Compra c ON dc.id_compra = c.id_compra
		INNER JOIN deleted d ON c.id_compra = d.id_compra
		WHERE dc.id_compra = d.id_compra
		), 0);

    UPDATE ComprasInfo.Compra
    SET total_compra = @total
    FROM ComprasInfo.Compra c
    INNER JOIN deleted d ON c.id_compra = d.id_compra
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = d.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;
END;


CREATE TRIGGER [ComprasInfo].[trg_AfterInsertDetalleCompra]
ON [ComprasInfo].[Detalle_Compra]
AFTER INSERT
AS
BEGIN
	UPDATE dc
	SET subtotal_compra  = i.cantidad * p.precio_producto
	FROM ComprasInfo.Detalle_Compra dc
	INNER JOIN inserted i ON (dc.id_compra = i.id_compra AND dc.id_producto_temporada = i.id_producto_temporada AND dc.cantidad = i.cantidad)
    INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
	INNER JOIN ProductoInfo.Temporada t ON pt.id_temporada = t.id_temporada
	WHERE dc.id_compra = i.id_compra;

	UPDATE p
    SET p.existencias = p.existencias + i.cantidad
    FROM ProductoInfo.Producto p
	INNER JOIN ProductoInfo.Producto_Temporada pt ON p.id_producto = pt.id_producto
	INNER JOIN inserted i ON pt.id_producto_temporada = i.id_producto_temporada;
END;


CREATE TRIGGER [ComprasInfo].[trg_AfterUpdateDetalleCompra]
ON [ComprasInfo].[Detalle_Compra]
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

    -- Ajustar existencias en base a la diferencia de cantidad
    UPDATE p
    SET p.existencias = 
        CASE 
            WHEN i.cantidad > d.cantidad THEN p.existencias + (i.cantidad - d.cantidad)
            WHEN i.cantidad < d.cantidad THEN p.existencias - (d.cantidad - i.cantidad)
            ELSE p.existencias
        END
    FROM inserted i
    INNER JOIN deleted d ON i.id_compra = d.id_compra AND i.id_producto_temporada = d.id_producto_temporada
    INNER JOIN ProductoInfo.Producto_Temporada pt ON i.id_producto_temporada = pt.id_producto_temporada
    INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;

	UPDATE dc
	SET subtotal_compra  = i.cantidad * p.precio_producto
	FROM ComprasInfo.Detalle_Compra dc
	INNER JOIN inserted i ON (dc.id_compra = i.id_compra AND dc.id_producto_temporada = i.id_producto_temporada)
    INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
	INNER JOIN ProductoInfo.Temporada t ON pt.id_temporada = t.id_temporada;
END;


CREATE TRIGGER [ComprasInfo].[trg_CalcularTotalCompra]
ON [ComprasInfo].[Detalle_Compra]
AFTER INSERT, UPDATE
AS
DECLARE @total as DECIMAL(10,2);
BEGIN
	SET @total = ISNULL((
		SELECT SUM(dc.subtotal_compra)
		FROM ComprasInfo.Detalle_Compra dc
		INNER JOIN ComprasInfo.Compra c ON dc.id_compra = c.id_compra
		INNER JOIN inserted i ON c.id_compra = i.id_compra
		WHERE dc.id_compra = i.id_compra
		), 0);

    UPDATE ComprasInfo.Compra
    SET total_compra = @total
    FROM ComprasInfo.Compra c
    INNER JOIN inserted i ON c.id_compra = i.id_compra
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;
END;



CREATE TRIGGER [VentasInfo].[trg_AfterDeleteDetalleVenta]
ON [VentasInfo].[Detalle_Venta]
AFTER DELETE
AS
DECLARE @total as DECIMAL(10,2);
BEGIN
	UPDATE p
    SET p.existencias = p.existencias + d.cantidad
    FROM ProductoInfo.Producto p
	INNER JOIN ProductoInfo.Producto_Temporada pt ON p.id_producto = pt.id_producto
    INNER JOIN deleted d ON d.id_producto_temporada = pt.id_producto_temporada;

	SET @total = ISNULL((
		SELECT SUM(dv.subtotal_venta)
		FROM VentasInfo.Detalle_Venta dv
		INNER JOIN VentasInfo.Venta v ON dv.id_venta = v.id_venta
		INNER JOIN deleted d ON v.id_venta = d.id_venta
		WHERE dv.id_venta = d.id_venta
		), 0);

    UPDATE VentasInfo.Venta
    SET total_venta = @total
    FROM VentasInfo.Venta v
    INNER JOIN deleted d ON v.id_venta = d.id_venta
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = d.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;
END;


CREATE TRIGGER [VentasInfo].[trg_AfterInsertDetalleVenta]
ON [VentasInfo].[Detalle_Venta]
AFTER INSERT
AS
BEGIN

	UPDATE dv
    SET dv.subtotal_venta = i.cantidad * p.precio_producto
    FROM VentasInfo.Detalle_Venta dv
    INNER JOIN inserted i ON (dv.id_venta = i.id_venta AND dv.id_producto_temporada = i.id_producto_temporada AND dv.cantidad = i.cantidad)
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
	INNER JOIN ProductoInfo.Temporada t ON pt.id_temporada = t.id_temporada;

	UPDATE p
    SET p.existencias = p.existencias - i.cantidad
    FROM ProductoInfo.Producto p
    INNER JOIN ProductoInfo.Producto_Temporada pt ON p.id_producto = pt.id_producto
    INNER JOIN inserted i ON i.id_producto_temporada = pt.id_producto_temporada;
END;


CREATE TRIGGER [VentasInfo].[trg_AfterUpdateDetalleVenta]
ON [VentasInfo].[Detalle_Venta]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Ajustar existencias en base a la diferencia de cantidad
    UPDATE p
    SET p.existencias = 
        CASE 
            WHEN i.cantidad > d.cantidad THEN p.existencias - (i.cantidad - d.cantidad)
            WHEN i.cantidad < d.cantidad THEN p.existencias + (d.cantidad - i.cantidad)
            ELSE p.existencias
        END
    FROM inserted i
    INNER JOIN deleted d ON i.id_venta = d.id_venta AND i.id_producto_temporada = d.id_producto_temporada
    INNER JOIN ProductoInfo.Producto_Temporada pt ON i.id_producto_temporada = pt.id_producto_temporada
    INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;

	UPDATE dv
    SET dv.subtotal_venta = i.cantidad * p.precio_producto
    FROM VentasInfo.Detalle_Venta dv
    INNER JOIN inserted i ON (dv.id_venta = i.id_venta AND dv.id_producto_temporada = i.id_producto_temporada AND dv.cantidad = i.cantidad)
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
	INNER JOIN ProductoInfo.Temporada t ON pt.id_temporada = t.id_temporada;
END;


CREATE TRIGGER [VentasInfo].[trg_CalcularTotalVenta]
ON [VentasInfo].[Detalle_Venta]
AFTER INSERT, UPDATE, DELETE
AS
DECLARE @total as DECIMAL(10,2);
BEGIN
	SET @total = ISNULL((
		SELECT SUM(dv.subtotal_venta)
		FROM VentasInfo.Detalle_Venta dv
		INNER JOIN VentasInfo.Venta v ON dv.id_venta = v.id_venta
		INNER JOIN inserted i ON v.id_venta = i.id_venta
		WHERE dv.id_venta = i.id_venta
		), 0);

    UPDATE VentasInfo.Venta
    SET total_venta = @total
    FROM VentasInfo.Venta v
    INNER JOIN inserted i ON v.id_venta = i.id_venta
	INNER JOIN ProductoInfo.Producto_Temporada pt ON pt.id_producto_temporada = i.id_producto_temporada
	INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;
END;


CREATE TRIGGER [VentasInfo].[trg_VerificarStock]
ON [VentasInfo].[Detalle_Venta]
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN ProductoInfo.Producto_Temporada pt ON i.id_producto_temporada = pt.id_producto_temporada
		INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
        WHERE i.cantidad > p.existencias
    )
    BEGIN
        RAISERROR ('No hay suficiente stock disponible', 16, 1);
		RETURN;
	END

	INSERT INTO VentasInfo.Detalle_Venta (id_venta, id_producto_temporada, cantidad, subtotal_venta)
    SELECT 
        i.id_venta, 
        i.id_producto_temporada, 
        i.cantidad, 
        (i.cantidad * p.precio_producto) AS subtotal_venta
    FROM inserted i
    INNER JOIN ProductoInfo.Producto_Temporada pt ON i.id_producto_temporada = pt.id_producto_temporada
    INNER JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto;
END;






--Regla tipos de estados
CREATE RULE Rule_EstadoApartado
	AS @valor IN ('En proceso', 'Liquidado');


sp_bindrule 'Rule_EstadoApartado', 'VentasInfo.Apartado.estado';


-- RULE PARA CANTIDADES MAYOR A 0
CREATE RULE Rule_CantidadPositiva
	as @valor > 0;


sp_bindrule 'Rule_CantidadPositiva', 'VentasInfo.Producto_Apartado.cantidad';


sp_bindrule 'Rule_CantidadPositiva', 'VentasInfo.Detalle_Venta.cantidad';







INSERT INTO ClientesInfo.Cliente (nombre_cliente, direccion_cliente, telefono_cliente, correo_cliente)
VALUES 
('Ana Torres', 'Av. Reforma 123, CDMX', '5512345678', 'ana.torres@email.com'),
('Luis Gómez', 'Calle Luna 456, GDL', '3311122233', 'l.gomez@email.com'),
('María Pérez', 'Blvd. del Sol 789, MTY', NULL, NULL);

INSERT INTO ClientesInfo.Cliente (nombre_cliente, direccion_cliente, telefono_cliente, correo_cliente)
VALUES 
('Marcela Rios', 'Carranza 1000, CDMX', '4441585858', 'mrios@gmail.com')

INSERT INTO ClientesInfo.Tarjeta_Cliente (id_cliente, numero_tarjeta, tipo, banco, codigo_seguridad, fecha_vencimiento)
VALUES 
(4, '7070707070707070', 'Crédito', 'Banamex', '002', '2028-05-30')

INSERT INTO ClientesInfo.Tarjeta_Cliente (id_cliente, numero_tarjeta, tipo, banco, codigo_seguridad, fecha_vencimiento)
VALUES 
(1, '4111111111111111', 'Crédito', 'BBVA', '123', '2026-08-01'),
(2, '5500000000000004', 'Débito', 'Banorte', '456', '2027-03-15'),
(1, '340000000000009', 'Crédito', 'Santander', '789', '2025-12-31');

INSERT INTO ProductoInfo.Producto (nombre_producto, precio_producto, existencias)
VALUES 
('Café Orgánico', 120.50, 50),
('Té Verde Matcha', 95.00, 80),
('Pan Artesanal', 45.75, 30);

INSERT INTO ProductoInfo.Temporada (nombre, fecha_inicio, fecha_fin)
VALUES 
('Verano 2025', '2025-06-01', '2025-08-31'),
('Navidad 2025', '2025-12-01', '2025-12-31');

INSERT INTO ProductoInfo.Producto_Temporada (id_producto, id_temporada)
VALUES 
(1, 1), -- Café Orgánico en Verano
(2, 2), -- Té Verde Matcha en Navidad
(3, 2); -- Pan Artesanal en Navidad


SELECT p.id_producto, 
       CONCAT(p.id_producto, ' - ', p.nombre_producto, ' (', t.nombre, ')') AS texto
FROM ProductoInfo.Producto_Temporada pt
JOIN ProductoInfo.Producto p ON pt.id_producto = p.id_producto
JOIN ProductoInfo.Temporada t ON pt.id_temporada = t.id_temporada;

select * from VentasInfo.Venta

select * from VentasInfo.Detalle_Venta


