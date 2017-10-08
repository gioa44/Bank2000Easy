SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [impexp].[get_ref_num](@rec_id int, @doc_date smalldatetime, @op_code char(5), @account_extra decimal(15, 0))
RETURNS varchar(32)
AS
BEGIN
	DECLARE
		@ref_num varchar(32)

	SET @ref_num = 'POBR' + REPLACE(STR(YEAR(@doc_date) % 100,2) + STR(MONTH(@doc_date),2) + STR(DAY(@doc_date),2), ' ', '0') + UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(@rec_id), 5, 10))
--	SET @ref_num = ISNULL(RTRIM(@op_code), '') + ISNULL(convert(varchar(20), convert(int, @account_extra)), '')

	RETURN @ref_num
END
GO
