
-- Mayor de cuentas.
declare @vHasta varchar(12)='20140301'
SELECT    Cuenta.idCuenta, Cuenta.Codigo, Cuenta.Descripcion,SUM(AsientoDetalle.debe) as SumaDebe,SUM(AsientoDetalle.haber) as SumaHaber,
	ROUND(SUM(AsientoDetalle.Debe - AsientoDetalle.Haber), 2) AS Saldo
FROM  AsientoDetalle INNER JOIN
                  Asiento ON AsientoDetalle.idAsiento = Asiento.idAsiento INNER JOIN
                  Cuenta ON AsientoDetalle.idCuenta = Cuenta.idCuenta
WHERE     (Asiento.Fecha < @vHasta)
and cuenta.CodRapido in('11102004','11102005','11103001','11103002','11103003')
GROUP BY Cuenta.idCuenta,Cuenta.Codigo, Cuenta.Descripcion

