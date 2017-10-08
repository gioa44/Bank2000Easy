SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[sys_get_arc_table_name] (@prefix sysname, @year int)
RETURNS sysname
AS
BEGIN
  RETURN @prefix + '_' + dbo.sys_get_arc_table_suffix (@year)
END
GO
