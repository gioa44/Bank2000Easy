SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[call_center_loans2007]
	@client_no int,
	@user_id int
AS
DECLARE
	@where_sql1 varchar(1000)

SET @where_sql1 = '(L.CLIENT_NO=' + convert(varchar(20), @client_no) + ')'

SET @where_sql1 = @where_sql1 + ' AND (L.STATE NOT IN (dbo.loan_const_state_application(), dbo.loan_const_state_auth_level1(), dbo.loan_const_state_auth_level2(), dbo.loan_const_state_approved(), dbo.loan_const_state_closed() ))'
	
EXEC dbo.loan_show_loans
	@user_id = @user_id,
	@right_name = 'ÍÀáÅÀ',
	@field_list = NULL,
	@view_name = 'dbo.LOAN_VW_LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = NULL,
	@where_sql3 = NULL,
	@join_sql   = NULL
GO
