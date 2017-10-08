SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_CLIENT_NAME_AND_CODES]
  @client_no int OUTPUT,
  @client_name varchar(100) OUTPUT,
  @city varchar(50) OUTPUT,
  @pid_code varchar(50) OUTPUT,
  @tax_code varchar(20) OUTPUT,
  @is_jur bit OUTPUT,
  @pass_end_date smalldatetime OUTPUT,
  @lat bit = 0
AS

SET NOCOUNT ON

SELECT @client_name = CASE WHEN @lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END,
       @city = TAX_INSP_CITY,
       @pid_code      = CASE WHEN IS_JURIDICAL = 0 THEN ISNULL(PERSONAL_ID, '') + ' / ' + ISNULL(PASSPORT, '') ELSE NULL END,
       @tax_code      = TAX_INSP_CODE,
       @is_jur        = IS_JURIDICAL,
       @pass_end_date = ISNULL(PASSPORT_END_DATE, 0)
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no
GO
