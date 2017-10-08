SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[call_center_get_tariff_info] (@client_no int, @acc_id int, @tariff_id int)
AS

SET NOCOUNT ON;

SELECT 
	CONVERT(varchar(50), 'ÚÅÄËÀ') AS OP_TYPE,
	CONVERT(varchar(50), null) AS OP_SUBTYPE,
	CONVERT(varchar(250), 'ÌÏÍÀÝÄÌÄÁÉ ÀÒ ÀÒÉÓ') AS FORMULA
GO
