SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[DEPO_VW_CLIENT_LIST]
AS
	SELECT C.CLIENT_NO, C.BRANCH_ID, C.DESCRIP, C.IS_EMPLOYEE, C.IS_RESIDENT, C.IS_INSIDER, C.CLIENT_TYPE, C.CLIENT_SUBTYPE, T.DESCRIP AS CLIENT_TYPE_DESCRIP, T2.DESCRIP AS CLIENT_SUBTYPE_DESCRIP, C.BIRTH_DATE, C.REC_STATE,
		CONVERT(bit, CASE WHEN ISNULL(dbo.cli_get_cli_attribute(C.CLIENT_NO, '$TAXABLE'), '') = 1 THEN 1 ELSE 0 END) AS TAXABLE, CASE WHEN ISNULL(dbo.cli_get_cli_attribute(C.CLIENT_NO, '$TAXABLE'), '') = 1 THEN $7.5 ELSE $0.00 END AS TAX_RATE
	FROM dbo.CLIENTS C (NOLOCK)
		INNER JOIN dbo.CLIENT_TYPES T (NOLOCK) ON T.CLIENT_TYPE = C.CLIENT_TYPE
		LEFT OUTER JOIN dbo.CLIENT_SUBTYPES T2 (NOLOCK) ON T2.CLIENT_TYPE = C.CLIENT_TYPE AND T2.CLIENT_SUBTYPE = C.CLIENT_SUBTYPE
		LEFT OUTER JOIN dbo.CLIENT_ATTRIBUTES AT (NOLOCK) ON AT.CLIENT_NO = C.CLIENT_NO AND AT.ATTRIB_CODE = '$TAXABLE'
GO
