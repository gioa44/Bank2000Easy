CREATE TABLE [dbo].[TERRORISTS]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TERR_ORG] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[NAMES] [nvarchar] (1000) COLLATE Latin1_General_BIN NULL,
[NICKS] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL,
[PASSPORT_ENTRY] [nvarchar] (1000) COLLATE Latin1_General_BIN NULL,
[POSSIBLE_RESIDENCE] [nvarchar] (1500) COLLATE Latin1_General_BIN NULL,
[REGISTRATION_DATE] [smalldatetime] NULL,
[OTHER_INFO] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TERRORISTS] ADD CONSTRAINT [PK_TERORISTS_ID] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO