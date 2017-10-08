SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_REPORT_OPER_PLAT]
  @start_date smalldatetime,
  @end_date smalldatetime,
  @user_id int,
  @shadow_level smallint = 1
AS

SET NOCOUNT ON

DECLARE 
	@rec_state tinyint

IF @shadow_level >= 0
	SET @rec_state = @shadow_level * 10

SELECT D.DOC_DATE, D.DOC_NUM, D.AMOUNT, D.ISO, A.ACCOUNT AS DEBIT, B.ACCOUNT AS CREDIT,
       P.SENDER_BANK_CODE AS BANK_A, P.SENDER_ACC AS ACC_A,
       P.RECEIVER_BANK_CODE AS BANK_B, P.RECEIVER_ACC AS ACC_B,
       P.SENDER_BANK_NAME, P.RECEIVER_BANK_NAME, D.DESCRIP, D.REC_ID, 1 AS IS_ARC, D.OP_CODE
FROM dbo.OPS_ARC D (NOLOCK)
	INNER JOIN ACCOUNTS B (NOLOCK) ON B.ACC_ID = D.CREDIT_ID

UNION ALL

SELECT D.DOC_DATE, D.DOC_NUM, D.AMOUNT, D.ISO, A.ACCOUNT AS DEBIT, B.ACCOUNT AS CREDIT,
       P.SENDER_BANK_CODE AS BANK_A, P.SENDER_ACC AS ACC_A,
       P.RECEIVER_BANK_CODE AS BANK_B, P.RECEIVER_ACC AS ACC_B,
       P.SENDER_BANK_NAME, P.RECEIVER_BANK_NAME, D.DESCRIP, D.REC_ID, 0 AS IS_ARC, D.OP_CODE
FROM dbo.OPS_0000 D (NOLOCK)
	INNER JOIN ACCOUNTS B (NOLOCK) ON B.ACC_ID = D.CREDIT_ID
	(@shadow_level >=0 ) AND (D.REC_STATE >= @rec_state)
GO