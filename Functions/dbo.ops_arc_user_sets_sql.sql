SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[ops_arc_user_sets_sql] (@user_id int, @right_name varchar(100) = 'ÍÀáÅÀ')
RETURNS TABLE
AS
RETURN
	SELECT DISTINCT S.SET_ID, S.JOIN_SQL, S.WHERE_SQL, S.IS_EXCEPTION
	FROM dbo.OPS_ARC_SETS S
		INNER JOIN dbo.OPS_ARC_SET_RIGHTS SR ON SR.SET_ID = S.SET_ID
		INNER JOIN dbo.GROUPS G ON G.GROUP_ID = SR.GROUP_ID
		INNER JOIN dbo.USERS U ON U.GROUP_ID = G.GROUP_ID
	WHERE U.[USER_ID] = @user_id AND (@right_name IS NULL OR SR.RIGHT_NAME = @right_name)
GO
