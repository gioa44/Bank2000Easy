SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------4.08
CREATE PROCEDURE [dbo].[GET_CUSTOM_RATES_2] 
	@acc_id int,
	@rate_type tinyint = 0
AS

SET NOCOUNT ON

DECLARE 
  @client_no int,
  @rate_politics_id int

SET @client_no = NULL

SELECT @client_no = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

EXEC dbo.GET_CUSTOM_RATES_1 @client_no, @rate_type
GO
