CREATE TABLE [dbo].[WBC_BANK_MSGS]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[BC_LOGIN_ID] [int] NULL,
[MSG_TEXT] [text] COLLATE Latin1_General_BIN NOT NULL,
[DT_TM] [smalldatetime] NOT NULL CONSTRAINT [DF_WBC_BANK_MSGS_DT_TM] DEFAULT (getdate()),
[USER_ID] [int] NULL,
[READ] [bit] NOT NULL CONSTRAINT [DF_WBC_BANK_MSGS_READ] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[TR_WBC_BANK_MSGS] ON [dbo].[WBC_BANK_MSGS] 
FOR INSERT AS

SET NOCOUNT ON

DECLARE 
  @bc_login_id int,
  @rec_id int

SELECT @bc_login_id = BC_LOGIN_ID, @rec_id = REC_ID
FROM INSERTED

IF @bc_login_id IS NULL
BEGIN
  INSERT INTO WBC_BANK_MSGS(BC_LOGIN_ID, MSG_TEXT)
  SELECT A.BC_LOGIN_ID, B.MSG_TEXT
  FROM BC_LOGINS A, WBC_BANK_MSGS B
  WHERE B.REC_ID = @rec_id AND A.FLAGS & 2 <> 0  /* internet enabled */

  DELETE FROM WBC_BANK_MSGS
  WHERE REC_ID = @rec_id
END

GO
ALTER TABLE [dbo].[WBC_BANK_MSGS] ADD CONSTRAINT [PK_WBC_BANK_MSGS] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_WBC_BANK_MSGS_DT] ON [dbo].[WBC_BANK_MSGS] ([DT_TM]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WBC_BANK_MSGS] WITH NOCHECK ADD CONSTRAINT [FK_WBC_BANK_MSGS_BC_LOGINS] FOREIGN KEY ([BC_LOGIN_ID]) REFERENCES [dbo].[BC_LOGINS] ([BC_LOGIN_ID])
GO
ALTER TABLE [dbo].[WBC_BANK_MSGS] ADD CONSTRAINT [FK_WBC_BANK_MSGS_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID]) ON DELETE CASCADE
GO