SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[SW_VW_SWIFT_MODULE]
AS

SELECT S.OP_NUM, S.REC_ID, S.UID, S.DATE_ADD, S.DOC_DATE, S.DOC_DATE_IN_DOC, S.ISO, S.AMOUNT, S.AMOUNT_EQU,
    FIN_DATE, S.FIN_ACCOUNT_ID, AF.ACCOUNT AS FIN_ACCOUNT, AF.ACCOUNT, S.FIN_ACC_NAME, S.FIN_AMOUNT, S.FIN_ISO, S.FIN_DOC_REC_ID, S.DOC_NUM,
    OP_CODE, S.DEBIT_ID, AD.ACCOUNT AS DEBIT, S.CREDIT_ID, AC.ACCOUNT AS CREDIT, S.REC_STATE, S.BNK_CLI_ID, S.DESCRIP, S.PARENT_REC_ID, S.OWNER, S.DOC_TYPE,
    ACCOUNT_EXTRA, S.PROG_ID, S.FOREIGN_ID, S.CHANNEL_ID, S.DEPT_NO, S.IS_SUSPICIOUS, S.SENDER_BANK_CODE,
    SENDER_BANK_NAME, S.SENDER_ACC, S.SENDER_ACC_NAME, S.RECEIVER_BANK_CODE, S.RECEIVER_BANK_NAME, S.RECEIVER_ACC,
    RECEIVER_ACC_NAME, P.ADDRESS_LAT, S.INTERMED_BANK_CODE, S.INTERMED_BANK_NAME, S.EXTRA_INFO, 
    S.SENDER_TAX_CODE, S.RECEIVER_TAX_CODE, S.SWIFT_TEXT,
    REF_NUM, S.COR_BANK_CODE, S.COR_ACCOUNT, S.COR_BANK_NAME, S.SWIFT_REC_STATE, S.SWIFT_ADD_DATE, S.SWIFT_REC_ID,
    S.RECEIVER_INSTITUTION, S.RECEIVER_INSTITUTION_NAME, S.SWIFT_OP_CODE, S.DOC_DATE_STR, S.SENDER_ACC_SWIFT, S.SENDER_DESCRIP, S.DESCRIP_EXT,S.DET_OF_CHARG,S.EXTRA_INFO_DESCRIP,S.FLAGS
FROM dbo.SWIFT_DOCS_IN S
	INNER JOIN dbo.ACCOUNTS AD (NOLOCK) ON AD.ACC_ID = S.DEBIT_ID
	INNER JOIN dbo.ACCOUNTS AC (NOLOCK) ON AC.ACC_ID = S.CREDIT_ID
	LEFT OUTER JOIN dbo.ACCOUNTS AF (NOLOCK) ON AF.ACC_ID = S.FIN_ACCOUNT_ID
	LEFT OUTER JOIN dbo.DOC_DETAILS_PASSPORTS P (NOLOCK) ON P.DOC_REC_ID=S.REC_ID
GO
