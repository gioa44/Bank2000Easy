SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_depo_after_annulment_tax_amount]
(
	@depo_id int,
	@acc_id int,
	@annul_date smalldatetime
)
RETURNS money
AS
BEGIN
	DECLARE @result money
	
	SELECT @result = ISNULL(SUM(DF.AMOUNT), $0.00)
	FROM dbo.DOCS_FULL DF (NOLOCK)		
		INNER JOIN (SELECT DISTINCT DEPO_ACC_ID FROM dbo.DEPO_DEPOSITS_HISTORY WHERE DEPO_ID = @depo_id
						UNION
					SELECT DISTINCT DEPO_ACC_ID FROM dbo.DEPO_DEPOSITS WHERE DEPO_ID = @depo_id) D ON D.DEPO_ACC_ID=DF.ACCOUNT_EXTRA
	WHERE DF.ACCOUNT_EXTRA = @acc_id AND DF.DOC_DATE>=@annul_date AND ISNULL(DF.OP_CODE, '') = '*%TX*'

	RETURN @result
END
GO
