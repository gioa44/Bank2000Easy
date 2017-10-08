SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_RISKS]
	@date smalldatetime,
	@user_id int,
	@loan_id int = NULL
AS
SET NOCOUNT ON

DECLARE
	@r int

DECLARE
	@max_category_level int,
	@max_category_level_2 int,
	@cr_l_loan_id int,
	@cr_l_loan_type int,
	@cr_l_max_category_level int,
	@client_no int

IF @loan_id IS NOT NULL
	SELECT @client_no = CLIENT_NO
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id
ELSE
	SET @client_no = null

DECLARE cr_c CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY 
FOR SELECT CLIENT_NO
FROM dbo.LOANS
WHERE STATE <> dbo.loan_const_state_closed() AND (@client_no IS NULL OR CLIENT_NO = @client_no)
GROUP BY CLIENT_NO
HAVING COUNT(*) > 1

OPEN cr_c

FETCH NEXT FROM cr_c INTO @client_no

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @max_category_level = 0
	SET @max_category_level_2 = 0

	DECLARE cr_l CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY 
	FOR SELECT L.LOAN_ID, L.LOAN_TYPE, D.MAX_CATEGORY_LEVEL
	FROM dbo.LOANS L INNER JOIN
		dbo.LOAN_DETAILS D ON D.LOAN_ID = L.LOAN_ID
	WHERE L.CLIENT_NO = @client_no AND L.STATE <> dbo.loan_const_state_closed()
	
	OPEN cr_l

	FETCH NEXT FROM cr_l INTO @cr_l_loan_id, @cr_l_loan_type, @cr_l_max_category_level

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @max_category_level < @cr_l_max_category_level
			SET @max_category_level = @cr_l_max_category_level

		-- @cr_l_loan_type = 1 ÉÐÏÈÄÊÖÒÉ ÓÄÓáÉ
--		IF (@cr_l_loan_type = 1) AND @max_category_level_2 < @cr_l_max_category_level
--			SET @max_category_level_2 = @cr_l_max_category_level

		FETCH NEXT FROM cr_l INTO @cr_l_loan_id, @cr_l_loan_type, @cr_l_max_category_level
	END
	
	CLOSE cr_l
	DEALLOCATE cr_l

	UPDATE LOAN_DETAILS
		SET MAX_CATEGORY_LEVEL = @max_category_level,
		CATEGORY_1 = CASE WHEN @max_category_level = 1 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_2 = CASE WHEN @max_category_level = 2 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_3 = CASE WHEN @max_category_level = 3 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_4 = CASE WHEN @max_category_level = 4 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_5 = CASE WHEN @max_category_level = 5 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END
	FROM dbo.LOANS L
		INNER JOIN dbo.LOAN_DETAILS D ON D.LOAN_ID = L.LOAN_ID
		LEFT OUTER JOIN	dbo.LOAN_OPS O ON O.LOAN_ID = L.LOAN_ID AND O.OP_TYPE = dbo.loan_const_op_restructure_risks()
	WHERE L.CLIENT_NO = @client_no AND L.STATE <> dbo.loan_const_state_closed() /*AND L.LOAN_TYPE = 1*/ AND D.MAX_CATEGORY_LEVEL <> @max_category_level_2 AND O.OP_ID IS NULL

/*	IF @max_category_level < @max_category_level_2
		SET @max_category_level = @max_category_level_2

	UPDATE LOAN_DETAILS
		SET MAX_CATEGORY_LEVEL = @max_category_level,
		CATEGORY_1 = CASE WHEN @max_category_level = 1 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_2 = CASE WHEN @max_category_level = 2 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_3 = CASE WHEN @max_category_level = 3 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_4 = CASE WHEN @max_category_level = 4 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END,
		CATEGORY_5 = CASE WHEN @max_category_level = 5 THEN ISNULL(D.CATEGORY_1, $0.00) + ISNULL(D.CATEGORY_2, $0.00) + ISNULL(D.CATEGORY_3, $0.00) + ISNULL(D.CATEGORY_4, $0.00) + ISNULL(D.CATEGORY_5, $0.00) ELSE NULL END
	FROM dbo.LOANS L
		INNER JOIN dbo.LOAN_DETAILS D ON D.LOAN_ID = L.LOAN_ID
		LEFT OUTER JOIN	dbo.LOAN_OPS O ON O.LOAN_ID = L.LOAN_ID AND O.OP_TYPE = dbo.loan_const_op_restructure_risks()
	WHERE L.CLIENT_NO = @client_no AND L.STATE <> dbo.loan_const_state_closed() AND L.LOAN_TYPE <> 1 AND MAX_CATEGORY_LEVEL <> @max_category_level AND O.OP_ID IS NULL
*/
	FETCH NEXT FROM cr_c INTO @client_no
END

CLOSE cr_c
DEALLOCATE cr_c

RETURN 0

_ret_error:
	CLOSE cr_l
	DEALLOCATE cr_l

	CLOSE cr_c
	DEALLOCATE cr_c
	
	RETURN (1)
GO
