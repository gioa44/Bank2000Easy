CREATE TABLE [dbo].[B2000_LOG_ARC]
(
[USER_ID] [int] NOT NULL,
[ACTION_CODE] [tinyint] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[APP_SRV_ID] [smallint] NOT NULL,
[DATE_AND_TIME] [smalldatetime] NOT NULL,
[REC_ID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[B2000_LOG_ARC] ADD CONSTRAINT [PK_B2000_LOG_ARC] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
