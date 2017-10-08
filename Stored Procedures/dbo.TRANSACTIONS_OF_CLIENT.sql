SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[TRANSACTIONS_OF_CLIENT]
  @client_id	int,
  @start_date	smalldatetime,
  @end_date	smalldatetime,
  @shadow_level smallint,
  @user_id int = null
AS 

SET NOCOUNT ON

IF @user_id IS NOT NULL
  INSERT INTO dbo.B2000_LOG ([USER_ID],ACTION_CODE,DESCRIP,APP_SRV_ID) 
  VALUES (@user_id, 7, 'ÀÌÏÍÀßÄÒÉÓ ÂÄÍÄÒÀÝÉÀ. ÊËÉÄÍÔÉ# ' + CONVERT(varchar(20), @client_id), 1)

SELECT * FROM dbo.client_show_statement (@client_id, @start_date, @end_date, @shadow_level)
GO
