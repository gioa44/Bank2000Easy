SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[itrs_show_docs2] (@acc_id int, @start_date smalldatetime, @end_date smalldatetime, @type tinyint = 15)
AS

SELECT 
	REC_ID,
	CASE WHEN ITRS_CODE$ IS NOT NULL THEN ITRS_CODE$ ELSE dbo.itrs_def_code (REC_TYPE, IS_JURIDICAL, IS_RESIDENT2, AMOUNT_USD, DOC_TYPE) END AS ITRS_CODE,
	ITRS_COUNTRY$,
	ITRS_PARTNER$,
	ITRS_SEGMENT$,
	ITRS_COMMENT$,
	ORIG_AMOUNT,
	ORIG_ISO,
	ORIG_DOC_DATE,
	ORIG_DOC_TYPE,
	ORIG_DOC_REC_ID,
	ORIG_ACC_ID,
	CONVERT(varchar(37), DEBIT) AS DEBIT
FROM dbo.itrs_show_docs_internal (@start_date, @end_date, @type, @acc_id)
GO
