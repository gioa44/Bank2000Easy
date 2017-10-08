CREATE TABLE [dbo].[TODO]
(
[USER_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DATE_AND_TIME] [smalldatetime] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ORIGINATOR] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TODO] ADD CONSTRAINT [PK_TODO] PRIMARY KEY CLUSTERED  ([USER_ID], [REC_ID]) ON [PRIMARY]
GO