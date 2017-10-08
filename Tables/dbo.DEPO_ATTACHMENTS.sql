CREATE TABLE [dbo].[DEPO_ATTACHMENTS]
(
[DEPO_ID] [int] NOT NULL,
[FILE_NAME] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[IS_FOLDER] [bit] NOT NULL CONSTRAINT [DF_DEPO_ATTACHMENTS_IS_FOLDER] DEFAULT ((0)),
[FILE_DATA] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_ATTACHMENTS] ADD CONSTRAINT [PK_DEPO_ATTACHMENTS] PRIMARY KEY CLUSTERED  ([DEPO_ID], [FILE_NAME]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_ATTACHMENTS] ADD CONSTRAINT [FK_DEPO_ATTACHMENTS_DEPO_DEPOSITS] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPO_DEPOSITS] ([DEPO_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
