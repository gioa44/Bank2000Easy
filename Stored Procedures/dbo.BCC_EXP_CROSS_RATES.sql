SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_CROSS_RATES]
  @bc_client_id int
AS

SET NOCOUNT ON

DECLARE 
  @rate_politics_id int,
  @main_client_id int

SET @main_client_id    = NULL
SET @rate_politics_id  = NULL

SELECT @main_client_id = MAIN_CLIENT_ID
FROM dbo.BC_CLIENTS (NOLOCK)
WHERE BC_CLIENT_ID = @bc_client_id 

IF @main_client_id IS NOT NULL
  SELECT @rate_politics_id = RATE_POLITICS_ID
  FROM dbo.CLIENTS (NOLOCK)
  WHERE CLIENT_NO = @main_client_id

EXEC dbo.GET_CUSTOM_RATES @rate_politics_id, 2 -- Bank-Client
GO
