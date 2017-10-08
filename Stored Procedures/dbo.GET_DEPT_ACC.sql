SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_DEPT_ACC]
  @dept_id int,
  @param_name varchar(60),
  @acc TACCOUNT OUTPUT 
AS

SET NOCOUNT ON

DECLARE @sql nvarchar(100)
SET @sql = N'SELECT @acc=' + @param_name + ' FROM dbo.DEPTS(NOLOCK) WHERE DEPT_NO=@dept_id'
EXEC sp_executesql @sql, N'@acc TACCOUNT output, @dept_id int', @acc OUTPUT, @dept_id

RETURN (0)
GO
