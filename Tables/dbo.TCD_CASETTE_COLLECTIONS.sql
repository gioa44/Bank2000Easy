CREATE TABLE [dbo].[TCD_CASETTE_COLLECTIONS]
(
[COLLECTION_ID] [int] NOT NULL IDENTITY(1, 1),
[BRANCH_ID] [int] NOT NULL,
[TCD_SERIAL_ID] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[STATE] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TCD_CASETTE_COLLECTIONS] ADD CONSTRAINT [PK_TCD_CASETTE_COLLECTIONS] PRIMARY KEY CLUSTERED  ([COLLECTION_ID]) ON [PRIMARY]
GO
