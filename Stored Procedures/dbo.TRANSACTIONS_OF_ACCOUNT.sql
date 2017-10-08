SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[TRANSACTIONS_OF_ACCOUNT] 
  @acc_id int,
  @equ bit = 0,
  @start_date smalldatetime,
  @end_date smalldatetime,
  @shadow_level smallint = -1,
  @user_id int = null,
  @show_subsums bit = 0
AS 
 
SET NOCOUNT ON
 
IF @user_id IS NOT NULL
BEGIN
	INSERT INTO dbo.B2000_LOG ([USER_ID],ACTION_CODE,DESCRIP,APP_SRV_ID) 
	VALUES (@user_id, 7, 'ÀÌÏÍÀßÄÒÉÓ ÂÄÍÄÒÀÝÉÀ. ÀÍÂ# ' + dbo.acc_get_branch_account_ccy(@acc_id), 1)
END
 
SELECT * 
FROM dbo.acc_show_statement(@acc_id, @equ, @start_date, @end_date, @shadow_level, @show_subsums, 1)
ORDER BY DT,REC_ID
GO
