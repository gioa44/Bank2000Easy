SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DP_VW_AGR_EXTRA]
AS
SELECT convert(tinyint, 0) AS DEPT_NO, convert(bit, 0) AS IS_LAT, convert(tinyint, 1) AS CODE, convert(varchar(128), 'ÈÀÌÖÍÀ ÂÏËÏÅÊÏ') AS BANK_REPRESENTATIVE, convert(varchar(255), 'ÈÀÌÖÍÀ ÂÏËÏÅÊÏ ÌÏØÌÄÃÄÁÓ ÁËÀ ÁËÀ ÁËÀ') AS VALUE
GO
