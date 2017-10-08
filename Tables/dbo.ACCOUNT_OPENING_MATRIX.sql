CREATE TABLE [dbo].[ACCOUNT_OPENING_MATRIX]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[CLIENT_TYPE] [tinyint] NOT NULL,
[CLIENT_SUBTYPE] [tinyint] NULL,
[IS_RESIDENT] [bit] NULL,
[IS_GEL] [bit] NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ACC_TYPE] [int] NOT NULL,
[ACC_SUBTYPE] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNT_OPENING_MATRIX] ADD CONSTRAINT [PK_ACCOUNT_OPENING_MATRIX] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ACCOUNT_OPENING_MATRIX_CLIENT_TYPE_SUBTYPE] ON [dbo].[ACCOUNT_OPENING_MATRIX] ([CLIENT_TYPE], [CLIENT_SUBTYPE], [IS_RESIDENT], [IS_GEL], [DESCRIP]) ON [PRIMARY]
GO