SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[cleanup_out_nbg] (@date smalldatetime)  AS
BEGIN
	BEGIN TRAN

	DELETE FROM impexp.PORTIONS_OUT_NBG
	WHERE PORTION_DATE <= @date AND ([COUNT] = 0 AND AMOUNT = $0)
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END
	
	DECLARE @tbl2 TABLE (DOC_REC_ID int NOT NULL PRIMARY KEY)

	INSERT INTO impexp.PORTIONS_OUT_NBG_ARC
	SELECT *
	FROM impexp.PORTIONS_OUT_NBG
	WHERE PORTION_DATE <= @date
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	INSERT INTO impexp.DOCS_OUT_NBG_ARC
	OUTPUT inserted.DOC_REC_ID into @tbl2
	SELECT *
	FROM impexp.DOCS_OUT_NBG
	WHERE PORTION_DATE <= @date
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	INSERT INTO impexp.DOCS_OUT_NBG_ARC_CHANGES
	SELECT A.*
	FROM impexp.DOCS_OUT_NBG_CHANGES A
		INNER JOIN @tbl2 B ON B.DOC_REC_ID = A.DOC_REC_ID
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	DELETE A
	FROM impexp.DOCS_OUT_NBG_CHANGES A
		INNER JOIN @tbl2 B ON B.DOC_REC_ID = A.DOC_REC_ID
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	DELETE A
	FROM impexp.DOCS_OUT_NBG A
		INNER JOIN @tbl2 B ON B.DOC_REC_ID = A.DOC_REC_ID
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	DELETE 
	FROM impexp.PORTIONS_OUT_NBG
	WHERE PORTION_DATE <= @date
	IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

	COMMIT

	RETURN @@ERROR
END
GO
