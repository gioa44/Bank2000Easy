CREATE TABLE [dbo].[CHK_BOOK_DETAILS]
(
[CHK_ID] [int] NOT NULL,
[CHK_NUM] [int] NOT NULL,
[CHK_STATE] [smallint] NOT NULL,
[CHK_USE_DATE] [smalldatetime] NULL CONSTRAINT [DF_CHK_BOOK_DETAILS_CHK_USE_DATE] DEFAULT (getdate()),
[USER_ID] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CHK_BOOK_DETAILS_TRIGGER] ON [dbo].[CHK_BOOK_DETAILS]
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_CHK_BOOK_DET'
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CHK_BOOK_DETAILS_TRIGGER2] ON [dbo].[CHK_BOOK_DETAILS]
FOR UPDATE
AS

SET NOCOUNT ON

IF @@nestlevel <> 1 RETURN

DECLARE 
  @chk_id int,
  @chk_num int


SELECT @chk_id = CHK_ID, @chk_num = CHK_NUM
FROM deleted

IF EXISTS(SELECT * FROM dbo.CHK_BOOK_DETAILS WHERE CHK_ID = @chk_id AND CHK_STATE = 0)
  UPDATE dbo.CHK_BOOKS
  SET CHK_DISABLED = 0
  WHERE CHK_ID = @chk_id

SELECT @chk_id = CHK_ID, @chk_num = CHK_NUM
FROM inserted

IF NOT EXISTS(SELECT * FROM dbo.CHK_BOOK_DETAILS WHERE CHK_ID = @chk_id AND CHK_STATE = 0)
  UPDATE dbo.CHK_BOOKS
  SET CHK_DISABLED = 1
  WHERE CHK_ID = @chk_id
GO
ALTER TABLE [dbo].[CHK_BOOK_DETAILS] WITH NOCHECK ADD CONSTRAINT [CK_CHK_BOOK_DETAILS_1] CHECK (([CHK_STATE]=(2) OR [CHK_STATE]=(1) OR [CHK_STATE]=(0)))
GO
ALTER TABLE [dbo].[CHK_BOOK_DETAILS] ADD CONSTRAINT [PK_CHK_BOOK_DETAILS] PRIMARY KEY CLUSTERED  ([CHK_ID], [CHK_NUM]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CHK_BOOK_DETAILS] ADD CONSTRAINT [FK_CHK_BOOK_DETAILS_CHK_BOOKS] FOREIGN KEY ([CHK_ID]) REFERENCES [dbo].[CHK_BOOKS] ([CHK_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
