SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CHANGE_BAL_OR_DEPT_NO] (@acc_id int, @new_bal_acc TBAL_ACC, @new_dept_no int)
AS

SET NOCOUNT ON;

DECLARE
  @old_bal_acc TBAL_ACC, 
  @old_dept_no int,
  @act_pas tinyint
  
SELECT @old_bal_acc = BAL_ACC_ALT, @old_dept_no = DEPT_NO, @act_pas = ACT_PAS
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @old_bal_acc IS NULL OR @old_dept_no IS NULL OR @act_pas IS NULL
BEGIN
  RAISERROR ('Account not found or invalid', 16, 1)
  RETURN (1)
END

IF EXISTS (SELECT * FROM dbo.SALDOS (NOLOCK) WHERE ACC_ID = @acc_id)
BEGIN
  RAISERROR ('ÀÌ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÁÒÖÍÅÄÁÉ ÃÀáÖÒÖË ÃÙÄÛÉ. ÝÅËÉËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ', 16, 1)
  RETURN (1)
END

UPDATE dbo.ACCOUNTS
SET BAL_ACC_ALT = @new_bal_acc, DEPT_NO = @new_dept_no, BRANCH_ID = dbo.dept_branch_id(@new_dept_no)
WHERE ACC_ID = @acc_id
GO
