CREATE TABLE [dbo].[CHK_BOOKS]
(
[CHK_ID] [int] NOT NULL IDENTITY(1, 1),
[BRANCH_ID] [int] NOT NULL,
[ACCOUNT] [dbo].[TACCOUNT] NOT NULL,
[CHK_SERIE] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[CHK_NUM_FIRST] [int] NOT NULL,
[CHK_COUNT] [smallint] NOT NULL CONSTRAINT [DF_CHK_BOOKS_CHK_COUNT] DEFAULT ((25)),
[CHK_DATE] [smalldatetime] NOT NULL,
[CHK_DISABLED] [bit] NOT NULL CONSTRAINT [DF_CHK_BOOKS_CHK_DISABLED] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CHK_BOOKS_TRIGGER] ON [dbo].[CHK_BOOKS]
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_CHK_BOOKS'
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CHK_BOOKS_TRIGGER2] ON [dbo].[CHK_BOOKS] 
FOR INSERT, UPDATE AS
 
SET NOCOUNT ON
 
IF @@nestlevel <> 1 RETURN
 
DECLARE 
  @chk_serie varchar(4),
  @chk_id int,
  @chk_num_first int,
  @chk_count smallint,
  @chk_disabled bit
 

SELECT @chk_id = CHK_ID, @chk_serie = CHK_SERIE, @chk_num_first = CHK_NUM_FIRST, @chk_count = CHK_COUNT, @chk_disabled = CHK_DISABLED
FROM inserted
 
IF EXISTS (SELECT * FROM dbo.CHK_BOOKS A 
           WHERE A.CHK_SERIE = @chk_serie AND A.CHK_ID <> @chk_id AND 
  (
   (A.CHK_NUM_FIRST <= @chk_num_first AND A.CHK_NUM_FIRST+A.CHK_COUNT > @chk_num_first) OR 
   (@chk_num_first <= A.CHK_NUM_FIRST AND @chk_num_first+@chk_count > A.CHK_NUM_FIRST)
  ))
BEGIN
  RAISERROR ('ÀÓÄÈÉ ßÉÂÍÀÊÉ ÖÊÅÄ ÀÒÓÄÁÏÁÓ',16,1)
  ROLLBACK
  RETURN
END
 

DECLARE @I int
SET @I = 0
WHILE @I <  @chk_count
BEGIN
  IF NOT EXISTS(SELECT * FROM dbo.CHK_BOOK_DETAILS WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num_first + @I)
    INSERT INTO dbo.CHK_BOOK_DETAILS  (CHK_ID, CHK_NUM, CHK_STATE, CHK_USE_DATE) 
    VALUES (@chk_id, @chk_num_first + @I, 0, null)
  SET @I = @I + 1
END
 
IF @chk_disabled = 1
  UPDATE dbo.CHK_BOOK_DETAILS 
  SET CHK_STATE = 2
  WHERE CHK_ID = @chk_id AND CHK_STATE = 0
 
IF @chk_disabled = 0
  UPDATE dbo.CHK_BOOK_DETAILS 
  SET CHK_STATE = 0
  WHERE CHK_ID = @chk_id AND CHK_STATE = 2
GO
ALTER TABLE [dbo].[CHK_BOOKS] ADD CONSTRAINT [CK_CHK_BOOKS_COUNT] CHECK (([CHK_COUNT]>(0)))
GO
ALTER TABLE [dbo].[CHK_BOOKS] ADD CONSTRAINT [PK_CHK_BOOKS] PRIMARY KEY CLUSTERED  ([CHK_ID]) ON [PRIMARY]
GO
