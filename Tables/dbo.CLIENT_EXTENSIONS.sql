CREATE TABLE [dbo].[CLIENT_EXTENSIONS]
(
[CLIENT_NO] [int] NOT NULL,
[DAI_NUMBER] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[RAITING] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[SEGMENTATION_NUM] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ACTIVITY_CODE] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[CLIENT_TYPE] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[NATIONALITY] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[COUNTRY_OF_RESIDENCE] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[MONITORING_SECTOR] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[MARKET_TRANSACTION] [bit] NOT NULL CONSTRAINT [DF_CLIENT_EXTENSIONS_MARKET_TRANSACTION] DEFAULT ((0)),
[CLIENT_SPM_ID] [char] (7) COLLATE Latin1_General_BIN NULL,
[GROUP_NAME] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[GROUP_SPM_ID] [char] (8) COLLATE Latin1_General_BIN NULL,
[CLIENT_STATUS] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BORROWER_DAI_NUMBER] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[BORROWER_NAME] [varchar] (200) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS] ADD CONSTRAINT [PK_CLIENT_EXTENSIONS] PRIMARY KEY CLUSTERED  ([CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS] ADD CONSTRAINT [FK_CLIENT_EXTENSIONS_CLIENT_EXTENSIONS_RATINGS] FOREIGN KEY ([RAITING]) REFERENCES [dbo].[CLIENT_EXTENSIONS_RATINGS] ([RATING])
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS] ADD CONSTRAINT [FK_CLIENT_EXTENSIONS_CLIENT_EXTENSIONS_SEGMENTATIONS] FOREIGN KEY ([SEGMENTATION_NUM]) REFERENCES [dbo].[CLIENT_EXTENSIONS_SEGMENTATIONS] ([SEGMENTATION_NUM])
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS] ADD CONSTRAINT [FK_CLIENT_EXTENSIONS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE
GO
