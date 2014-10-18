/*
Autor: César Jaramillo
Release: 20141017 14h43
Descripción:
	Este script se ejecuta como consulta en el fichero: ArticulosCreados.rpt de alertas semanales.
	Almacena toda la data en la tabla: tmpArticulosCreados. Si no existe la crea
	Este reporte muestra los artículos que cumplan las siguientes condiciones:
		Artículos usados por primera vez en compra.idtipofactura in (2,14,9) con desde un mes atrás con respecto a la fecha actual.
		O
		Artículos creados durante el último mes con respecto a la fecha actual.
*/

-- Primer criterio:
if exists (select * from sys.tables where name='tmpArticulosCreados') drop table tmpArticulosCreados
declare @vIdArticulo int, @vContador int, @vInsert nvarchar(4000), @vSelect nvarchar(4000), @vInto nvarchar(4000), @vFrom nvarchar(4000), @vFiltro nvarchar(4000)
set @vInsert=' insert into tmpArticulosCreados (Grupo, SubGrupo, Codigo, Articulo, Marca, Transaccion, NumeroDoc,Precio2,Fecha) '
set @vSelect=' select top(1) ArticuloGrupo.Grupo, ArticuloSubGrupo.SubGrupo, Articulo.Codigo, Articulo.Articulo, ArticuloMarca.Marca, 
						CompraNumero.Nombre as Transaccion,Compra.Numero as NumeroDoc, Articulo.Precio2, Compra.Fecha '
set @vFrom=' FROM    CompraNumero RIGHT OUTER JOIN 
					   Compra ON CompraNumero.idTipoFactura = Compra.idTipoFactura RIGHT OUTER JOIN
					   Articulo LEFT OUTER JOIN
					   ArticuloGrupo ON Articulo.idGrupoArticulo = ArticuloGrupo.idGrupoArticulo LEFT OUTER JOIN
					   ArticuloMarca ON Articulo.idMarca = ArticuloMarca.idMarca LEFT OUTER JOIN
					   ArticuloSubGrupo ON Articulo.idSubGrupo = ArticuloSubGrupo.idSubGrupo RIGHT OUTER JOIN
					   DetCompra ON Articulo.idArticulo = DetCompra.idArticulo ON Compra.idCompra = DetCompra.idCompra '
set @vFiltro = ' AND Compra.idTipoFactura in (2,14,9) 
		and detcompra.idArticulo<>0 AND Compra.Fecha >= cast (DATEADD(MONTH, - 1, GETDATE()) as date) 
			AND DetCompra.idArticulo NOT IN
				(
					-- Conjunto de artículos que aparecen en documentos (2,14,9) cuya fecha es mas antigua que la fecha actual menos un mes.
					SELECT DISTINCT DetCompra.idArticulo
					FROM  Articulo AS Articulo RIGHT OUTER JOIN
						DetCompra AS DetCompra ON Articulo.idArticulo = DetCompra.idArticulo LEFT OUTER JOIN
						Compra AS Compra ON DetCompra.idCompra = Compra.idCompra
					WHERE Compra.idTipoFactura in (2,14,9) AND Articulo.idTipoGrupo=1
						AND Compra.Fecha < cast (DATEADD(MONTH, - 1, GETDATE()) as date)
				)
ORDER BY COMPRA.Fecha ASC '
set @vContador=0
DECLARE CURSOR1 SCROLL CURSOR FOR
	SELECT DISTINCT DetCompra.idArticulo
	FROM         Compra RIGHT OUTER JOIN
						  DetCompra ON Compra.idCompra = DetCompra.idCompra
	WHERE   Compra.idTipoFactura in (2,14,9)
				AND Compra.Fecha >= cast (DATEADD(MONTH, - 1, GETDATE()) as date) and detcompra.idArticulo<>0
				AND DetCompra.idArticulo NOT IN
					(
						-- Conjunto de artículos que aparecen en documentos (2,14,9) cuya fecha es mas antigua que la fecha actual menos un mes.
						SELECT DISTINCT DetCompra.idArticulo
						FROM  Articulo AS Articulo RIGHT OUTER JOIN
							DetCompra AS DetCompra ON Articulo.idArticulo = DetCompra.idArticulo LEFT OUTER JOIN
							Compra AS Compra ON DetCompra.idCompra = Compra.idCompra
						WHERE Compra.idTipoFactura in (2,14,9) AND Articulo.idTipoGrupo=1
							AND Compra.Fecha < cast (DATEADD(MONTH, - 1, GETDATE()) as date)
					)
	ORDER BY detcompra.idArticulo ASC
OPEN CURSOR1
	FETCH NEXT FROM CURSOR1 INTO @vIdArticulo
	while (@@FETCH_STATUS<>-1)
	begin
		if (@@FETCH_STATUS<>-2)
		begin
			if (@vContador=0)
			begin
				exec (@vSelect+' into tmpArticulosCreados '+@vFrom+' WHERE detcompra.idArticulo='+@vIdArticulo +' '+@vFiltro)
			end
			else
			begin
				exec (@vInsert+@vSelect+@vFrom+' WHERE detcompra.idArticulo='+@vIdArticulo +' '+@vFiltro)
			end
			set @vContador+=1
		end
		FETCH NEXT FROM CURSOR1 INTO @vIdArticulo
	end
CLOSE CURSOR1
DEALLOCATE CURSOR1

-- Segundo Criterio:
insert into tmpArticulosCreados (Grupo, SubGrupo, Codigo, Articulo, Marca, Transaccion, NumeroDoc,Precio2,Fecha)
SELECT  ArticuloGrupo.Grupo, ArticuloSubGrupo.SubGrupo, Articulo.Codigo, Articulo.Articulo, ArticuloMarca.Marca,'Nuevo Artículo' as Transaccion,'' as 'NumeroDoc', 
		Articulo.Precio2, Articulo.FechaIngreso as 'Fecha'
FROM    Articulo LEFT OUTER JOIN
			ArticuloGrupo ON Articulo.idGrupoArticulo = ArticuloGrupo.idGrupoArticulo LEFT OUTER JOIN
            ArticuloMarca ON Articulo.idMarca = ArticuloMarca.idMarca LEFT OUTER JOIN
            ArticuloSubGrupo ON Articulo.idSubGrupo = ArticuloSubGrupo.idSubGrupo
WHERE   (Articulo.FechaIngreso >= DATEADD(month, - 1, GETDATE())) AND (Articulo.idTipoGrupo = 1)

SELECT * FROM tmpArticulosCreados order by Codigo asc

/*
select * from tmpArticulosCreados
delete from tmpArticulosCreados
drop table tmpArticulosCreados

select * from tmpArticulosCreados
drop table tmpArticulosCreados
*/




