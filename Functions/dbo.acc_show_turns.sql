SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[acc_show_turns] (
  @acc_id int,
  @start_date smalldatetime,
  @end_date smalldatetime,
  @equ bit = 0,
  @shadow_level smallint = -1
)

RETURNS @tbl TABLE (DOC_TYPE smallint, DT smalldatetime NOT NULL, DBO money, CRO money, SALDO money, PRIMARY KEY CLUSTERED (DOC_TYPE,DT))
AS
BEGIN

	INSERT INTO @tbl
	SELECT CASE DOC_TYPE WHEN -200 THEN -100 WHEN -100 THEN 20000 ELSE 0 END, 
		DT, 
		CASE @equ WHEN 1 THEN DBO_EQU ELSE DBO END,
		CASE @equ WHEN 1 THEN CRO_EQU ELSE CRO END,
		CASE @equ WHEN 1 THEN SALDO_EQU ELSE SALDO END
	FROM dbo.acc_show_statement ( @acc_id, @equ, @start_date, @end_date, @shadow_level, 1, 0)
	WHERE DOC_TYPE IN (-100,-150,-200)
	
	RETURN
END
GO
