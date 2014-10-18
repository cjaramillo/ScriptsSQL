set nocount on
go
declare uno scroll cursor for
select ord, fecha, seriefact, nrofactura, ruc, nota, cuenta, fcaduc, autorizacion,base0,base12,iva, total from CARGARCOMP$
open uno
	declare @vOrd int, @vFecha date, @vseriefact varchar(20),@vnrofactura int , @vruc varchar(15) 
	declare @vnota varchar(100), @vcuenta varchar(100), @vfcaduc date, @vautorizacion varchar(20)
	declare @vbase0 float , @vbase12 float ,@viva float , @vtotal float, @vidCliente int, @vIdGrupoArticulo int
	declare @auxCuenta int, @vIdArticulo int, @vIdCompraAux int
	fetch next from uno into @vOrd, @vFecha, @vseriefact,@vnrofactura, @vruc, @vnota, @vcuenta, @vfcaduc, @vautorizacion, @vbase0,@vbase12,@viva, @vtotal 
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN
			-- saber si el cliente existe
			set @vidCliente=-1
			select @vidCliente=idCliente from Cliente where Ruc=@vruc and (Proveedor=1 or Ambos=1)
			if (@vidCliente=-1)
			begin
				print 'Registro nro. '+cast (@vord as varchar(20))+' cliente con ruc '+@vruc+' NO EXISTE'
			end
			else
			begin
				select @auxCuenta=max(idcuenta) from Cuenta where Descripcion=@vcuenta
				if (@auxCuenta is null)
				begin
					print 'Registro nro. '+cast (@vord as varchar(20))+' OMITIDO, cuenta '+@vcuenta+' no encontrada'
				end
				else
				begin
					select @vIdGrupoArticulo=max(idGrupoArticulo) from ArticuloGrupo where idCuentas2=@auxCuenta
					if(@vIdGrupoArticulo is null)
					begin 
						print 'Registro nro. '+cast (@vord as varchar(20))+' OMITIDO, grupo articulo ligado a cuenta '+@vcuenta+' no encontrado'
					end
					else
					begin
						select  @vIdArticulo=max(idArticulo) from Articulo 
							where idGrupoArticulo=@vIdGrupoArticulo and (Articulo is not null or ltrim(Articulo) <>'')
						if (@vIdArticulo is null)
						begin
							print 'Registro nro. '+cast (@vord as varchar(20))+' OMITIDO, No se encuentra un articulo adecuado para realizar asignación'
						end
						else
						begin
							insert into Compra (idCliente, idTipoFactura,idcomprobante,idCredTributario,Numero,idsucursal, Fecha, Notas,Total, Iva,SubtotalIva,								SubtotalExcento,AutFactura,SerieFactura,Nuevo,FechaCaducidad,idproyecto,idSubProyecto) 
								values (@vidCliente,4,1,1,@vnrofactura,1,@vFecha,@vnota, @vtotal ,@viva,@vbase12,@vbase0,@vautorizacion ,@vseriefact,1, @vfcaduc,21,14)
							
							select @vIdCompraAux=idcompra from Compra where idCliente=@vidCliente and idTipoFactura=4 and Numero=@vnrofactura and Total=@vtotal
							if(@vbase12>0)
								insert into DetCompra (idCompra, idArticulo,idSucursal,Cantidad, Precio,Impuesto,Signo,FechaIngreso,idproyecto,idSubProyecto,										Unidades)
								values (@vIdCompraAux,@vIdArticulo,1,1,@vbase12,12,1,@vFecha,21,14,1)
							else
							insert into DetCompra (idCompra, idArticulo,idSucursal,Cantidad, Precio,Signo,FechaIngreso,idproyecto,idSubProyecto,Unidades)
								values (@vIdCompraAux,@vIdArticulo,1,1,@vtotal,1,@vFecha,21,14,1)
							print 'Registro nro. '+cast (@vord as varchar(20))+' INGRESADO'
						end
					end
					
				end
			end
		END
		fetch next from uno into @vOrd, @vFecha, @vseriefact,@vnrofactura, @vruc, @vnota, @vcuenta, @vfcaduc, @vautorizacion, @vbase0,@vbase12,@viva, @vtotal
	END
close uno
deallocate uno