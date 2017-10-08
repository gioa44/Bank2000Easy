SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[bonus_procedures] AS

SELECT p.[name]
FROM sys.procedures p
WHERE p.[name] like 'bonus_check_%' 
	AND (SELECT b.[name] FROM sys.parameters b WHERE b.[object_id] = p.[object_id] and parameter_id = 1) = '@product_id'
	AND (SELECT b.[name] FROM sys.parameters b WHERE b.[object_id] = p.[object_id] and parameter_id = 2) = '@id'
	AND (SELECT b.[name] FROM sys.parameters b WHERE b.[object_id] = p.[object_id] and parameter_id = 3) = '@date'
	AND (SELECT b.[name] FROM sys.parameters b WHERE b.[object_id] = p.[object_id] and parameter_id = 4) = '@client_no'
	AND (SELECT b.[name] FROM sys.parameters b WHERE b.[object_id] = p.[object_id] and parameter_id = 5) = '@is_valid'
GO
