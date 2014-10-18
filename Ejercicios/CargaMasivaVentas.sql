set nocount on
go

-- Para el cursor
declare @vOrd int, @vFecha date, @vSERIE varchar(20), @vFACTURA varchar(10), @vNOMBRE varchar(10), @vRUC varchar(10), @vBase0 float, @vBase12 float, @vIva float, @vTotal float, @vRet_fuente float, @vRet_iva70 float, @vRet_iva100 float, @vNro_ret varchar(20), @vAutoriza_ret varchar(20), @vVenc_ret date

-- Otras
declare @xIdArticulo int
declare @xIdGrupoArticulo int
declare @xIdTipoGrupo int
declare @xIdCliente int
declare @xIdTipoRuc int

-- verifico si existe el articulo con el que trabaja este proceso. Trabajo con el artículo 'Articulo CMD'
set @xIdArticulo=-1
select @xIdArticulo=idarticulo from Articulo where Articulo='Articulo CMD'
if (@xIdArticulo=-1 or @xIdArticulo is null)
begin
	-- Verificar si existe creado el grupo de articulo
	set @xIdGrupoArticulo=-1
	select @xIdGrupoArticulo=idGrupoArticulo from ArticuloGrupo where Grupo='CMD Carga Masiva Datos'
	if (@xIdGrupoArticulo=-1 or @xIdGrupoArticulo is null)
	begin
		-- Crear el grupo.
		insert into ArticuloGrupo (idTipoGrupo,Grupo) values(3,'CMD Carga Masiva Datos')
	end
	-- Crear el articulo
	select @xIdTipoGrupo=idgrupoarticulo from ArticuloGrupo where Grupo='CMD Carga Masiva Datos'
	insert into Articulo (Articulo,idGrupoArticulo) values ('Articulo CMD',@xIdTipoGrupo)
end
 

-- inicio y declaracion del cursor
declare uno scroll cursor for
SELECT ORD, FECHA, SERIE, FACTURA, NOMBRE, RUC, BASE0, BASE12, IVA, TOTAL, ret_fuente, ret_iva70, ret_iva100, nro_ret, autoriza_ret, venc_ret FROM CARGARVENTAS$
open uno
	fetch next from uno into @vOrd , @vFecha , @vSERIE , @vFACTURA , @vNOMBRE , @vRUC , @vBase0 , @vBase12 , @vIva , @vTotal , @vRet_fuente , @vRet_iva70 , 
		@vRet_iva100 , @vNro_ret , @vAutoriza_ret , @vVenc_ret 
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN
			-- Factura anulada
			if (@vRuc is null)
			begin
				insert into Compra (idCliente,idProyecto,idSubProyecto,idTipoFactura,idComprobante,idCredTributario,idSucursal,Fecha,FechaVencimiento,Usuario,Numero,Total,iva,SubtotalIva,SubtotalExcento,SerieFactura,Nuevo) 
					values (null, 21,14,1,1,1,1,@vFecha,@vFecha,'SUBIDADATOS',@vFACTURA,@vTotal,@vIva,@vBase12,@vBase0,@vSERIE,1)
				if(@vNro_ret is not null)
					insert into Retencion ()
						values
				
			end
			
			-- Buscar Cliente
			if(LEN(@vRuc)=9 or LEN(@vRuc)=12)
				set @vRuc='0'+@vRuc
			set @xIdCliente=-1
			select @xIdCliente=idcliente from Cliente where Ruc=@vRUC  and idTipoRuc in (1,2) and Proveedor=0 or Ambos=1
			if (@xIdCliente=-1 or @xIdCliente is null)
			begin
				-- Crear Cliente
				-- Determinar el tipo de RUC 
				if (LEN(@vRuc)=13)
					set @xIdTipoRuc=1
				if (LEN(@vRuc)=10)
					set @xIdTipoRuc=2
				insert into Cliente (idTipoRuc,idSucursal,Nombre,Ruc,Observacion,Ambos,Proveedor,Nuevo) values (@xIdTipoRuc,1,@vNOMBRE,@vRUC,'Creado por CMD',0,0,1)
				select @xIdCliente=idcliente from Cliente where Ruc=@vRUC  and idTipoRuc in (1,2) and Proveedor=0 or Ambos=1
			end
			--
			
			
			
			insert into Compra (idcliente, idproyecto, idsubproyecto,idtipofactura, idcomprobante) values ()
		
			
		END
		fetch next from uno into @vOrd , @vFecha , @vSERIE , @vFACTURA , @vNOMBRE , @vRUC , @vBase0 , @vBase12 , @vIva , @vTotal , @vRet_fuente , @vRet_iva70 , 
			@vRet_iva100 , @vNro_ret , @vAutoriza_ret , @vVenc_ret 
	END
close uno
deallocate uno

