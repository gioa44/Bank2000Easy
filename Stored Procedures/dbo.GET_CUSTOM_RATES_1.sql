SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_CUSTOM_RATES_1] (@client_no int, @rate_type tinyint = 0)
AS

SET NOCOUNT ON

DECLARE 
  @rate_politics_id int

SET @rate_politics_id = NULL

IF @client_no IS NOT NULL
BEGIN
  SELECT @rate_politics_id = RATE_POLITICS_ID
  FROM dbo.CLIENTS (NOLOCK)
  WHERE CLIENT_NO = @client_no
END

EXEC dbo.GET_CUSTOM_RATES @rate_politics_id, @rate_type
GO
