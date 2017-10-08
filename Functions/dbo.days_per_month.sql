SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[days_per_month](@date smalldatetime)
RETURNS int
BEGIN
    RETURN CASE WHEN MONTH(@date) IN (1, 3, 5, 7, 8, 10, 12) THEN 31
                WHEN MONTH(@date) IN (4, 6, 9, 11) THEN 30
                ELSE CASE WHEN (YEAR(@date) % 4 = 0 AND
                                YEAR(@date) % 100 != 0) OR
                               (YEAR(@date) % 400  = 0)
                          THEN 29
                          ELSE 28
                     END
           END

END
GO
