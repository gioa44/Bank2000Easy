SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[loan_get_loan_prolongation_data](@loan_id int, @first_date smalldatetime, @last_date smalldatetime)
RETURNS
	@loan_prolongation_data TABLE (
	LOAN_ID int NOT NULL,
	PROLONGATION int NOT NULL,
	PROLONGATION_DATE_1 smalldatetime NULL,
	PROLONGATION_DATE_2 smalldatetime NULL
)
     
AS
BEGIN
	DECLARE @op_id int
	DECLARE @prolongated int
	DECLARE @prolongation_date smalldatetime
	DECLARE @i int

	SET @prolongated = 0

------ ÓÄÓáÆÄ ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄÌÏßÌÄÁÀ
	SELECT @prolongated = COUNT(*)
	FROM dbo.LOAN_OPS (NOLOCK)
	WHERE LOAN_ID = @loan_id AND 
		  OP_DATE BETWEEN @first_date AND @last_date AND
		  OP_TYPE = dbo.loan_const_op_prolongation()

----ÈÖ ÀÒÓÄÁÏÁÓ ÓÄÓáÆÄ ÐÒÏËÏÍÂÀÝÉÀ, ÌÀÛÉÍ...
	IF @prolongated >0
	BEGIN
		INSERT INTO @loan_prolongation_data
			(LOAN_ID, PROLONGATION)
		VALUES(@loan_id, @prolongated)

		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT OP_DATE
		FROM dbo.LOAN_OPS
		WHERE LOAN_ID = @loan_id AND 
			OP_DATE BETWEEN @first_date AND @last_date AND
			OP_TYPE = dbo.loan_const_op_prolongation()

		SET @i = 1
		OPEN cc
		FETCH NEXT FROM cc INTO @prolongation_date
		
		WHILE @@FETCH_STATUS = 0
		BEGIN

			IF @i = 1 
			BEGIN
				UPDATE @loan_prolongation_data
				SET	PROLONGATION_DATE_1 = @prolongation_date
				WHERE LOAN_ID = @loan_id					
			
				SET @i = 2	
			END
			ELSE
				IF @i = 2
				BEGIN
					UPDATE @loan_prolongation_data
					SET	PROLONGATION_DATE_2 = @prolongation_date
					WHERE LOAN_ID = @loan_id
				
					SET @i = 3
				END

			FETCH NEXT FROM cc INTO @prolongation_date
		END

		CLOSE cc
		DEALLOCATE cc
	END
	ELSE
		INSERT INTO @loan_prolongation_data
			(LOAN_ID, PROLONGATION, PROLONGATION_DATE_1, PROLONGATION_DATE_2)
		VALUES(@loan_id, 0, NULL, NULL)
	
RETURN
END
GO
