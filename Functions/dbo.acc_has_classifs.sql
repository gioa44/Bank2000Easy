SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_has_classifs](@acc_id int, @classif_ids varchar(500))
RETURNS bit
AS
BEGIN
	DECLARE @ret bit
  
	DECLARE @T TABLE ([ID] varchar(20) PRIMARY KEY CLUSTERED)

	INSERT INTO @T ([ID])
	SELECT [ID] FROM dbo.fn_split_list_classif(@classif_ids, default) 

	DECLARE @T1 TABLE ([ID] varchar(20) PRIMARY KEY CLUSTERED)  
	
	INSERT INTO @T1 ([ID])
	SELECT [ID] 
	FROM dbo.ACCOUNTS_CLASSIF (NOLOCK)
	WHERE ACC_ID = @acc_id

	SET @ret = CASE
		WHEN NOT EXISTS(SELECT T.[ID] AS ID1, T1.[ID] AS ID2 FROM	@T T LEFT OUTER JOIN 	@T1 T1 ON T1.[ID] LIKE T.[ID]+'%' WHERE T1.[ID] IS NULL)
	THEN 1 
	ELSE 0
	END   

	RETURN @ret
END
GO