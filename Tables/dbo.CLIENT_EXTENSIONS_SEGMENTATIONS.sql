CREATE TABLE [dbo].[CLIENT_EXTENSIONS_SEGMENTATIONS]
(
[SEGMENTATION_NUM] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[SEGMENTATION_TYPE] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS_SEGMENTATIONS] ADD CONSTRAINT [PK_CLIENT_EXTENSIONS_SEGMENTATIONS] PRIMARY KEY CLUSTERED  ([SEGMENTATION_NUM]) ON [PRIMARY]
GO