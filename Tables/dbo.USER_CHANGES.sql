CREATE TABLE [dbo].[USER_CHANGES]
(
[USER_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[USER_ID2] [int] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TIME_OF_CHANGE] [smalldatetime] NULL CONSTRAINT [DF_USER_CHANGES_TIME_OF_CH] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[USER_CHANGES] ADD CONSTRAINT [PK_USER_CHANGES] PRIMARY KEY CLUSTERED  ([USER_ID], [REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[USER_CHANGES] ADD CONSTRAINT [FK_USER_CHANGES_1] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
ALTER TABLE [dbo].[USER_CHANGES] ADD CONSTRAINT [FK_USER_CHANGES_2] FOREIGN KEY ([USER_ID2]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
