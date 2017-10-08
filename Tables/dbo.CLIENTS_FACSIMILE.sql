CREATE TABLE [dbo].[CLIENTS_FACSIMILE]
(
[CLIENT_NO] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[FACS_TYPE] [int] NULL,
[IS_AUTHORIZED] [bit] NOT NULL CONSTRAINT [DF_CLIENTS_FACSIMILE_2] DEFAULT ((0)),
[IS_ACTIVE] [bit] NOT NULL CONSTRAINT [DF_CLIENTS_FACSIMILE_3] DEFAULT ((1)),
[START_DATE] [smalldatetime] NULL,
[END_DATE] [smalldatetime] NULL,
[BLOB_DATA] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENTS_FACSIMILE] ADD CONSTRAINT [PK_CLIENTS_FACSIMILE] PRIMARY KEY CLUSTERED  ([CLIENT_NO], [REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENTS_FACSIMILE] ADD CONSTRAINT [FK_CLIENTS_FACSIMILE_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CLIENTS_FACSIMILE] ADD CONSTRAINT [FK_CLIENTS_FACSIMILE_FACSIMILE_TYPES] FOREIGN KEY ([FACS_TYPE]) REFERENCES [dbo].[FACSIMILE_TYPES] ([TYPE_ID])
GO