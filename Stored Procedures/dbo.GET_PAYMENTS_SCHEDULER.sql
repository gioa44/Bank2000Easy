SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_PAYMENTS_SCHEDULER]
	@pay_date smalldatetime
AS

DECLARE
	@day tinyint

SELECT	*, 0 AS ACCOUNT, ISNULL(dbo.get_provider_service_online_can_get_debt (PROVIDER_ID, SERVICE_ALIAS), 0) AS ONLINE_CAN_GET_DEBT
FROM	dbo.PAYMENTS_SCHEDULER
WHERE	LAST_PAY_DATE < @pay_date AND REC_STATE = 2 AND START_DATE <= @pay_date AND 
		(END_DATE IS NULL OR END_DATE > @pay_date) AND
		dbo.payment_scheduler_test(PAY_DAY, @pay_date, LAST_PAY_DATE) = 1
ORDER BY PRIORITY_ORDER

RETURN 0
GO
