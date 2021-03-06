CREATE TABLE [dbo].[BONUSES]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[START_DATE] [smalldatetime] NOT NULL,
[END_DATE] [smalldatetime] NULL,
[COMMENTS] [text] COLLATE Latin1_General_BIN NULL,
[BONUS_PRODUCT_ID] [int] NOT NULL,
[SP_NAME] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BONUSES] ADD CONSTRAINT [PK_BONUSES] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BONUSES] ADD CONSTRAINT [FK_BONUSES_BONUS_PRODUCTS] FOREIGN KEY ([BONUS_PRODUCT_ID]) REFERENCES [dbo].[BONUS_PRODUCTS] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
