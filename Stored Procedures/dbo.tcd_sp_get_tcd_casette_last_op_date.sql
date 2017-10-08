SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_get_tcd_casette_last_op_date]
(
	@collection_id int
)
AS
BEGIN
	DECLARE @date smalldatetime
 
	SELECT @date = MAX(AUTH_DATE) FROM dbo.TCD_CASETTE_OPS
	WHERE  COLLECTION_ID = @collection_id

	SET @date = convert(smalldatetime,floor(convert(real, @date)))
	SELECT @date
END
GO
