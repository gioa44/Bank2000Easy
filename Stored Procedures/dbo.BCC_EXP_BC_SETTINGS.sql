SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[BCC_EXP_BC_SETTINGS]
	@branch_id int
AS

SET NOCOUNT ON

DECLARE
  @bank_code TGEOBANKCODE,
  @bank_name varchar(100),
  @bank_code_int TINTBANKCODE,
  @bank_name_int varchar(100)
  
SELECT @bank_code = CODE9, @bank_name = DESCRIP, @bank_code_int = BIC, @bank_name_int = DESCRIP_LAT
FROM dbo.DEPTS (NOLOCK)
WHERE DEPT_NO = @branch_id

SELECT A.*, @bank_code AS OUR_BANK_CODE, @bank_name AS OUR_BANK_NAME, @bank_code_int AS OUR_BANK_CODE_INT, @bank_name_int AS OUR_BANK_NAME_LAT, CONVERT(int,0) AS BC_FLAGS
FROM dbo.BC_SETTINGS A
WHERE BRANCH_ID = @branch_id
GO
