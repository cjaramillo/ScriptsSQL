/*
Esta consulta desglosa por grupo de artículo en dólares de cada factura.

select * from ArticuloGrupo where grupo like '%PRESSTEK%'
1=EQUIPOS - EQ
2=PELICULAS - PE
3=PLACAS - PL
4=QUIMICO - QI
11=PAPEL - PA
41=TINTAS - TN
2288=PRODUCTOS HP
3749=PRODUCTOS PRESSTEK
685=VARIOS INSUMOS - IN
*/


SELECT        top(1000) compra.Numero, compra.SubtotalExcento+compra.SubtotalIva as TotalFact, sum (DetCompra.Cantidad*DetCompra.Precio) AS SumaDetalle,
isnull(sum(case when articulo.idGrupoArticulo=1 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Equipos,
isnull(sum(case when articulo.idGrupoArticulo=2 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Peliculas,
isnull(sum(case when articulo.idGrupoArticulo=3 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Placas,
isnull(sum(case when articulo.idGrupoArticulo=4 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Quimicos,
isnull(sum(case when articulo.idGrupoArticulo=11 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Papel,
isnull(sum(case when articulo.idGrupoArticulo=41 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Tintas,
isnull(sum(case when articulo.idGrupoArticulo=685 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Varios_Insumos,
isnull(sum(case when articulo.idGrupoArticulo=2288 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Productos_HP,
isnull(sum(case when articulo.idGrupoArticulo=3749 and detcompra.idarticulo=articulo.idarticulo and compra.idcompra=detcompra.idcompra then detcompra.Cantidad*DetCompra.Precio end),0) as Presstek
FROM            Articulo LEFT OUTER JOIN
                         ArticuloSubGrupo ON Articulo.idSubGrupo = ArticuloSubGrupo.idSubGrupo RIGHT OUTER JOIN
                         DetCompra ON Articulo.idArticulo = DetCompra.idArticulo LEFT OUTER JOIN
                         Compra ON DetCompra.idCompra = Compra.idCompra
where idTipoFactura=1 and compra.Borrar=0
group by compra.Numero, compra.SubtotalExcento+compra.SubtotalIva
order by compra.numero desc




