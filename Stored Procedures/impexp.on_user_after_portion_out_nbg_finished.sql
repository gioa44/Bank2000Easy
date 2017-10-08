SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[on_user_after_portion_out_nbg_finished] (@date smalldatetime, @por int)
AS

SET NOCOUNT ON;
GO
