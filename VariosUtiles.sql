-- Reducir LOG BDD
USE GRAPHICSOURCE2007
go
ALTER DATABASE GRAPHICSOURCE2007
SET RECOVERY SIMPLE;
GO
-- Shrink the truncated log file to 100 MB.
DBCC SHRINKFILE (LatiniumSQL_log, 100);
GO
-- Reset the database recovery model.
ALTER DATABASE GRAPHICSOURCE2007
SET RECOVERY FULL;
--SELECT * FROM SYS.database_files


--------------------------------------------------------------------------


--Buscar un campo en una todas las tablas:
    SELECT TABLE_NAME,*
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME LIKE '%NombreDeCampo%'

-- Buscar Data en todas las tablas
/*
OJO: Es un procedimiento almacenado.
EXEC SearchAllTables 'DATO A BUSCAR'
*/
CREATE PROC SearchAllTables (@SearchStr NVARCHAR(100))
AS
BEGIN
	CREATE TABLE #Results (ColumnName NVARCHAR(370),ColumnValue NVARCHAR(3630))
	SET NOCOUNT ON
	DECLARE @TableName NVARCHAR(256),@ColumnName NVARCHAR(128),@SearchStr2 NVARCHAR(110)
	SET @TableName = ''
	SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%', '''')
	WHILE @TableName IS NOT NULL
	BEGIN
		SET @ColumnName = ''
		SET @TableName = (
				SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
				FROM INFORMATION_SCHEMA.TABLES
				WHERE TABLE_TYPE = 'BASE TABLE'
					AND QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
					AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)), 'IsMSShipped') = 0
				)
		WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
		BEGIN
			SET @ColumnName = (
					SELECT MIN(QUOTENAME(COLUMN_NAME))
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_SCHEMA = PARSENAME(@TableName, 2)
						AND TABLE_NAME = PARSENAME(@TableName, 1)
						AND DATA_TYPE IN (
							'char'
							,'varchar'
							,'nchar'
							,'nvarchar'
							)
						AND QUOTENAME(COLUMN_NAME) > @ColumnName
					)
			IF @ColumnName IS NOT NULL
			BEGIN
				INSERT INTO #Results
				EXEC (
						'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630)
FROM ' + @TableName + ' (NOLOCK) ' + ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
						)
			END
		END
	END

	SELECT ColumnName
		,ColumnValue
	FROM #Results
END

	
	
--Buscar un Stored Procedure por algun fragmento del nombre:
    SELECT ROUTINE_NAME, ROUTINE_DEFINITION, *
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_DEFINITION LIKE '%palabraDelStored%'
    AND ROUTINE_TYPE='PROCEDURE'

--Buscar Stored Procedures por texto:
    SELECT distinct name SP_Name FROM [sysobjects] INNER JOIN [syscomments] ON [sysobjects].id = [syscomments].id where xtype = 'P' and text like '%textoabucar%'

-- HostName y Usuario logueados en la conexion actual
	SELECT HOST_NAME() AS HostName, SUSER_NAME() AS LoggedInUser

-- Reiniciar el contador interno del primary key de una tabla
	DBCC CHECKIDENT (<nombre_tabla>, RESEED,0)

-- Formatear fecha para concatenar en un Query dinámico:
	print ''''+'20'+convert(varchar(8),getdate(),12)+''''
	Select Replace(convert(varchar(20),getdate(),23),'-','')

-- 	Verificar si existe un sp o tabla en SQL Server.
	IF EXISTS (SELECT * FROM sysobjects WHERE name=’sp_Procedimiento‘) BEGIN
		print 'Existe'
	END

--  Reducir el log de una bdd:
	USE GRAPHICSOURCE2007
	go
	ALTER DATABASE GRAPHICSOURCE2007
	SET RECOVERY SIMPLE;
	GO
	-- Aquí el meollo del asunto.
	DBCC SHRINKFILE (LatiniumSQL_log, 100);
	GO
	-- Reset the database recovery model.
	ALTER DATABASE GRAPHICSOURCE2007
	SET RECOVERY FULL;
	
	
-- Obtener las sentencias mas ejecutadas.
	SELECT TOP 10 
	 [Execution count] = execution_count
	,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
			 (CASE WHEN qs.statement_end_offset = -1 
				THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
			  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
	,[Parent Query] = qt.text
	,DatabaseName = DB_NAME(qt.dbid)
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	ORDER BY [Execution count] DESC;

	
	
	
	
	
	
	