SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ON_USER_AFTER_DELETE_DOC]
	@rec_id int,			-- საბუთის შიდა №
	@uid int,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int,			-- ვინ შლის საბუთს

	@check_saldo bit,		-- შეამოწმოს თუ არა მინ. ნაშთი
	@info bit,				-- რეალურად გატარდეს OUTPUT, თუ მხოლოდ ინფორმაციაა
	@lat bit,				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
	
	@extra_params xml		-- დამატებითი პარამეტრები, რომელიც დააბრუნა ON_USER_BEFORE_DELETE_DOC პროცედურამ
AS

SET NOCOUNT ON;

RETURN 0
GO
