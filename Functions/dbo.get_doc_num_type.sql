SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[get_doc_num_type] (@doc_type smallint)
RETURNS tinyint AS
BEGIN
 DECLARE @doc_num_type tinyint
 SET @doc_num_type = 0
 
 IF @doc_type BETWEEN 10 AND 99
  SET @doc_num_type = 1
 ELSE
 IF @doc_type BETWEEN 100 AND 109
  SET @doc_num_type = 2
 ELSE
 IF @doc_type BETWEEN 110 AND 119
  SET @doc_num_type = 3
 ELSE
 IF @doc_type BETWEEN 120 AND 159
  SET @doc_num_type = 4
 ELSE
 IF @doc_type BETWEEN 200 AND 249
  SET @doc_num_type = 99
 
 RETURN @doc_num_type
END
GO
