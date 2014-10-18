
-- GENERAR INVENTARIO DE BODEGAS COMERCIALES A LA FECHA
SELECT ArticuloGrupo.Grupo, Articulo.Codigo, Articulo.Articulo, SUM(cantidad*signo) as Existencias
FROM         ArticuloGrupo RIGHT OUTER JOIN
                      Articulo ON ArticuloGrupo.idGrupoArticulo = Articulo.idGrupoArticulo RIGHT OUTER JOIN
                      Compra RIGHT OUTER JOIN
                      DetCompra ON Compra.idCompra = DetCompra.idCompra ON Articulo.idArticulo = DetCompra.idArticulo
WHERE ArticuloGrupo.idGrupoArticulo in (1,2,3,4,11,41,685,740,2288,2853,3749) and DetCompra.Bodega in (1,13,14,37,44,56) and compra.Borrar=0
GROUP BY ArticuloGrupo.Grupo, Articulo.Codigo, Articulo.Articulo
order by Grupo


