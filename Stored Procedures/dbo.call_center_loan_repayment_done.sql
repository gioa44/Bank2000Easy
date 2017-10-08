SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[call_center_loan_repayment_done] (@rec_id int, @repayment_type int) AS

SET NOCOUNT ON;
GO
