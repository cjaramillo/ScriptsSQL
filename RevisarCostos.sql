declare @vDesde nvarchar(8), @vHasta nvarchar(8)
set @vDesde='20140901'
set @vHasta='20141001'

--> Actualizar todos los egresos e ingresos de Bodega del periodo deben tener Compra.idComprobante=25 (No aplica)
update Compra set idComprobante=25 where compra.Borrar=0 and compra.idTipoFactura in (8,9) and compra.fecha>=@vDesde

--> Actualizar todos los egresos e ingresos de Bodega del periodo cuyo numero like 'TR%' or 'DG%' deben tener en Compra.idSubproyecto=2 (Transferencias)
update Compra 
set Compra.idSubproyecto=2 
where compra.Borrar=0 and compra.idTipoFactura in (8,9) and compra.fecha>=@vDesde and  Compra.Fecha<@vHasta and (Numero like 'TR%' or numero like 'DG%')

--> Actualizar todos los egresos e ingresos de Bodega del periodo cuyo numero like 'NE%' deben tener en Compra.idSubproyecto=4 (NOTAS DE ENTREGA)
update Compra 
set Compra.idSubproyecto=4 
where compra.Borrar=0 and compra.idTipoFactura in (8,9) and compra.fecha>=@vDesde and  Compra.Fecha<@vHasta and Numero like 'NE%'

--> Actualizar todos los ingresos de Bodega del periodo cuyo numero like 'IBG%' deben tener en Compra.idSubProyecto=1 (INGRESO A BODEGA)
update compra 
set compra.idSubProyecto=1 
where Compra.Borrar=0 and compra.idTipoFactura=9 and compra.fecha>=@vDesde and  Compra.Fecha<@vHasta and Numero like 'IBG%'

-- Actualizar tipos de comprobante en facturas de venta cuando sean diferentes a “Documentos autorizados en ventas excepto N/C N/D ”
update compra set idComprobante=15 where idCompra in 
(
	select compra.idCompra from Compra 
		left outer join CompraComprobante on compra.idComprobante=CompraComprobante.Codigo
	where idTipoFactura=1 and compra.idComprobante<>15 and compra.Fecha>=@vDesde and  Compra.Fecha<@vHasta
)

-- Actualizar todas las ventas a crédito.
update compra set contadoCredito=2 where idtipofactura=1 and contadoCredito<>2 and compra.fecha>=@vDesde and compra.borrar=0 

-- Actualizar crédito tributario en facturas de venta
update compra set idcredtributario=1 where idtipofactura=1 and fecha>=@vDesde

-- VERIFICAR REGISTROS DETCOMPRA EN 0/NULL
SELECT     Compra.Numero,CompraNumero.Nombre as 'Transacción', Compra.Fecha, 'Revisar Lineas del Detalle en Blanco' AS Novedad
FROM         DetCompra LEFT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra LEFT OUTER JOIN
                      CompraNumero ON Compra.idTipoFactura = CompraNumero.idTipoFactura
WHERE     (Compra.idTipoFactura IN (1, 5, 8, 9)) AND (Compra.Fecha >= @vDesde) AND (Compra.Fecha < @vHasta) AND (DetCompra.idArticulo = 0 OR
                      DetCompra.idArticulo IS NULL)


-- Mostrar documentos no anulados que no tengan líneas en el detalle, o cuya suma de la cantidad* precio de las líneas del detalle sea 0
SELECT     Compra.Numero, CompraNumero.Nombre AS Transaccion, Compra.Fecha, 'Posiblemente tenga que anularse (detalle y valor 0)' AS Aviso
FROM         Compra LEFT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra LEFT OUTER JOIN
                      CompraNumero ON Compra.idTipoFactura = CompraNumero.idTipoFactura
WHERE     (Compra.Borrar = 0) AND (Compra.Total = 0) AND (Compra.idTipoFactura IN (1, 5, 8, 9)) AND (Compra.Fecha >= @vDesde) AND (Compra.Fecha < @vHasta)
GROUP BY Compra.Numero, Compra.Fecha, CompraNumero.Nombre
HAVING      (COUNT(DetCompra.idDetCompra) = 0) or  SUM(detcompra.cantidad*detcompra.precio)=0



-- Documentos Anulados con líneas en el detalle:
SELECT     compra.Numero,CompraNumero.Nombre as 'Transacción', case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		   COUNT(detcompra.iddetcompra) AS 'Nro Lineas Detalle', Compra.Usuario
FROM       DetCompra LEFT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra LEFT OUTER JOIN
                      CompraNumero on compra.idTipoFactura=CompraNumero.idTipoFactura
                      
WHERE     (Compra.idTipoFactura IN (1, 5, 8, 9)) AND (Compra.Borrar = 1) and compra.fecha>=@vDesde and compra.Fecha<@vHasta
group by compra.Numero, compra.Borrar, CompraNumero.Nombre, Compra.Usuario
having COUNT (detcompra.iddetcompra)>0

-- Verificar huérfanos en transferencias (egresos sin ingreso y viceversa - Incluye Anulados.)  
select Egreso.Numero as 'Egreso',case when Egreso.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado Egreso', Egreso.Bodega as 'Bod Origen', 
	Egreso.Pedido as 'Bod Destino', Ingreso.Numero as 'Ingreso',case when Ingreso.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado Ingreso', Ingreso.Bodega as 'Bod Ingreso'
from 
	(
		select Numero, Bodega, Pedido, Borrar
		from Compra 
		where idTipoFactura=8 and idSubProyecto=2 and Numero like 'TR%' and compra.fecha>=@vDesde 
			and compra.Fecha<@vHasta and Pedido is not null 
	) Egreso
	left outer join 
	(
		select Numero,Bodega, Pedido, Borrar
		from Compra 
		where idTipoFactura=9 and idSubProyecto=2 and Numero like 'TR%' and compra.fecha>=@vDesde and compra.Fecha<@vHasta
	) Ingreso
on Egreso.Numero=Ingreso.Numero
group by Egreso.Pedido,Ingreso.Bodega, Egreso.Numero, Egreso.Bodega, Egreso.Pedido, Ingreso.Numero, Ingreso.Bodega, Egreso.Borrar, Ingreso.Borrar
having Egreso.Pedido<>Ingreso.Bodega or Egreso.Borrar<>Ingreso.Borrar



-- Revisar Proyectos y Subproyectos:
-- Documentos que tengan mal puesto el comprobante de documento y el subproyecto
-- Ventas
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=1 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante<>15 or compra.idSubProyecto not in (14,15,16,18) or compra.idCliente is null or Compra.Bodega is null or compra.Bodega=0)
-- Compras.
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where compra.idTipoFactura=4 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and (Compra.idComprobante not in (1,3,14,25))
-- Dev. Ventas (NC)
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=5 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante<>4 or compra.idSubProyecto not in (14,15,16,18) or compra.idCliente is null)

-- Dev. Compras
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=6 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante not in (4,25) or compra.idCliente is null or compra.idCliente is null)
-- Egresos Bodega
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=8 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante not in (25) or compra.idSubProyecto not in (2,4) or compra.idCliente is null or Compra.Bodega is null or compra.Bodega=0)

-- Ingresos Bodega
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=9 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante not in (25) or compra.idSubProyecto not in (1,2,6) or compra.idCliente is null or Compra.Bodega is null or compra.Bodega=0)

-- Nota Débito Venta
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura=27 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante not in (25) or compra.idCliente is null or compra.idCliente is null or compra.idProyecto is null or compra.idSubProyecto not in (14,15,16,18))

/*
-- Ordenes de Compra, pedidos proveedor y Reserva Proveedores
union
select  Compra.Numero,CompraNumero.Nombre as 'Transacción',Cliente.Nombre, case when Compra.Borrar=1 then 'Anulada' else 'Activa' end as 'Estado', 
		CompraComprobante.Comprobante, Proyecto.Nombre as 'Centro Costos',SubProyecto.Nombre as 'Proyecto', Compra.Bodega
from Compra 
	left outer join CompraComprobante on compra.idComprobante=CompraComprobante.idComprobante
	left outer join CompraNumero on Compra.idTipoFactura=CompraNumero.idTipoFactura
	left outer join SubProyecto on compra.idSubProyecto=Subproyecto.idSubProyecto
	left outer join Cliente on compra.idcliente=cliente.idCliente
	left outer join Proyecto on compra.idProyecto=Proyecto.idProyecto
where	compra.idTipoFactura in (2,14,26) and compra.fecha>=@vDesde and compra.Fecha<@vHasta and compra.Borrar=0 and 
		(Compra.idComprobante not in (25,33) or compra.idSubProyecto is not null or compra.idProyecto is not null or compra.idCliente is null or Compra.Bodega is null or compra.Bodega=0)
*/





/*
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
---------------------------------VERIFICAR COSTOS DIFERENTES DENTRO DE UN MISMO PERIODO-------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
*/


-- EN PRIMER LUGAR HAY QUE VER donde es la diferencia. Si es en el contable o en el inventario.
/*
Si es en el inventario es mayor que el contable entonces hay que ver alguna cosa que no esté costeada.
Si el inventario es menor que el contable entonces cri cri cri
*/


-- Verificar precios diferentes:
-- Solo en IBG aplican PRECIOS. Se debe evaluar diferencias en precio del mismo producto en el mismo ibg
SELECT     Compra.Numero, Compra.Fecha, Articulo.Codigo, Articulo.Articulo, DetCompra.Precio
FROM         Articulo RIGHT OUTER JOIN
                      DetCompra ON Articulo.idArticulo = DetCompra.idArticulo LEFT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra
WHERE     (Compra.Borrar = 0) AND (Compra.idTipoFactura IN (8, 9)) AND (Compra.Fecha >= '20131201') AND (Compra.Fecha <= '20131231') AND (Articulo.Codigo LIKE 'PL%') and COMPRA.NUMERO LIKE 'IBG%'
ORDER BY articulo.Codigo

-- Verificar COSTOS DIFERENTES
SELECT     Compra.Numero, Compra.Fecha, Articulo.Codigo, Articulo.Articulo, DetCompra.CostoPromedio
FROM         Articulo RIGHT OUTER JOIN
                      DetCompra ON Articulo.idArticulo = DetCompra.idArticulo LEFT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra
WHERE     (Compra.Borrar = 0) AND (Compra.idTipoFactura IN (1, 5, 8, 9)) AND (Compra.Fecha >= '20131201') AND (Compra.Fecha <= '20131231') AND (Articulo.Codigo LIKE 'PL%') 
ORDER BY articulo.Codigo


-- Verificar que documentos que no aplican  (cotizaciones principalmente) no tengan costo




-- En compras no debe haber articulos designados para venta.
SELECT     compra.Numero
FROM       Compra RIGHT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra LEFT OUTER JOIN
                      Articulo ON DetCompra.idArticulo = Articulo.idArticulo
where idTipoFactura=4 and compra.Borrar=0 and compra.Fecha>='20131201' and compra.Fecha<='20131231'
and articulo.Codigo like 'PL%'


-- articulo, nro de ibg's en las cuales está presente
SELECT articulo.idArticulo,Articulo.Articulo,Articulo.CostoPromedio, COUNT (compra.idcompra)
FROM         ArticuloGrupo RIGHT OUTER JOIN
                      Articulo ON ArticuloGrupo.idGrupoArticulo = Articulo.idGrupoArticulo LEFT OUTER JOIN
                      Compra RIGHT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra ON Articulo.idArticulo = DetCompra.idArticulo
where Compra.idTipoFactura=9 and compra.Numero like 'IBG%' 
and Articulo.idGrupoArticulo in (1,2,3,4,11,41,685,2288,2851,2853,3123,3749) 
and Compra.Fecha>='20131101' and compra.Fecha<='20131130'
group by articulo.idArticulo,Articulo.Articulo, Articulo.CostoPromedio
having COUNT (compra.idcompra)>1
order by COUNT (compra.idcompra) desc


SELECT     Compra.Fecha, Compra.Numero, DetCompra.idArticulo, Articulo.Articulo, Articulo.Codigo, DetCompra.CostoPromedio
FROM         DetCompra RIGHT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra LEFT OUTER JOIN
                      Articulo ON DetCompra.idArticulo = Articulo.idArticulo
WHERE     (DetCompra.idArticulo = 3458) 
AND (Compra.idTipoFactura = 9) AND (Compra.Numero LIKE 'IBG%') AND (Compra.Fecha >= '20131101') 
AND (Compra.Fecha <= '20131130')



-- articulo, nro de IG's en las cuales está presente 
SELECT articulo.idArticulo,Articulo.Articulo,Articulo.CostoPromedio, COUNT (compra.idcompra)
FROM         ArticuloGrupo RIGHT OUTER JOIN
                      Articulo ON ArticuloGrupo.idGrupoArticulo = Articulo.idGrupoArticulo LEFT OUTER JOIN
                      Compra RIGHT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra ON Articulo.idArticulo = DetCompra.idArticulo
where Compra.idTipoFactura=2 and compra.Numero like 'IG%' 
and Articulo.idGrupoArticulo in (1,2,3,4,11,41,685,2288,2851,2853,3123,3749) 
and Compra.Fecha>='20131101' and compra.Fecha<='20131130'
group by articulo.idArticulo,Articulo.Articulo, Articulo.CostoPromedio
having COUNT (compra.idcompra)>1
order by COUNT (compra.idcompra) desc



SELECT     Compra.Fecha, Compra.Numero, DetCompra.idArticulo, Articulo.Articulo, Articulo.Codigo, DetCompra.CostoPromedio
FROM         DetCompra RIGHT OUTER JOIN
                      Compra ON DetCompra.idCompra = Compra.idCompra LEFT OUTER JOIN
                      Articulo ON DetCompra.idArticulo = Articulo.idArticulo
WHERE     (DetCompra.idArticulo = 7342) 
AND (Compra.idTipoFactura = 2) AND (Compra.Numero LIKE 'IG%') AND (Compra.Fecha >= '20131101') 
AND (Compra.Fecha <= '20131130')

SELECT * FROM Articulo WHERE idArticulo=7342

/*
select * from ArticuloGrupo where Grupo like '%PRESSTEK%'

1	EQUIPOS - EQ
2	PELICULAS - PE
3	PLACAS - PL
4	QUIMICO - QI
11	PAPEL - PA
41	TINTAS - TN
685 VARIOS INSUMOS - IN
2288 PRODUCTOS HP
2851 TERCEROS ZI
2853 REPUESTOS RP
3123 DISTRIBUCION DE COSTOS
3749 PRODUCTOS PRESSTEK
*/


select * from Compra where Numero like 'IG%' and compra.Fecha>='20131101' and compra.Fecha<='20131130'





-- NINGUNO DE LOS ARTICULOS PARA COSTOS DEBEN ESTAR EN COMPRAS.
SELECT articulo.idArticulo,Articulo.Articulo,Articulo.CostoPromedio, COUNT (compra.idcompra)
FROM         ArticuloGrupo RIGHT OUTER JOIN
                      Articulo ON ArticuloGrupo.idGrupoArticulo = Articulo.idGrupoArticulo LEFT OUTER JOIN
                      Compra RIGHT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra ON Articulo.idArticulo = DetCompra.idArticulo
where Compra.idTipoFactura=4 --and compra.Numero like 'IBG%' 
and Articulo.idGrupoArticulo in (1,2,3,4,11,41,685,2288,2851,2853,3123,3749) 
and Compra.Fecha>='20131101' and compra.Fecha<='20131130'
group by articulo.idArticulo,Articulo.Articulo, Articulo.CostoPromedio
having COUNT (compra.idcompra)>1
order by COUNT (compra.idcompra) desc

------------------------------------------------------------------------------------------------------------------------------------------------------


declare @vDesde nvarchar(8), @vHasta nvarchar(8)
set @vDesde='20140901'
set @vHasta='20141001'

select Compra.idTipoFactura, Compra.Numero, Cliente.Nombre, Detcompra.Cantidad, Articulo.Codigo, Articulo.Articulo, Detcompra.Precio
from detcompra 
	left outer join compra on detcompra.idcompra=Compra.idCompra
	left outer join cliente on compra.idcliente=cliente.idCliente
	left outer join compraNumero on compra.idtipofactura=compraNumero.idTipoFactura
	left outer join articulo on detcompra.idArticulo=Articulo.idArticulo
	left outer join articuloTipo on Articulo.idTipoGrupo=articuloTipo.idTipoGrupo
where compra.idtipofactura in (1,5,8,9) and compra.idSubProyecto<>1
-- compra.idtipofactura=9 and compra.numero like 'IBG-%'
		and compra.borrar=0 and compra.fecha>=@vDesde and compra.Fecha<@vHasta and Articulo.idTipoGrupo=1
order by articulo.idarticulo desc






/*
select * from articuloTipo
select * from articulo
select * from Proyecto
select * from CompraComprobante
select * from SubProyecto 
select * from CompraNumero
*/





