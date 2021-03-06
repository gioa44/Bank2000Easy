CREATE TABLE [dbo].[INCASSO_ISSUER]
(
[REC_ID] [smallint] NOT NULL IDENTITY(1, 1),
[PRIORITY_ORDER] [tinyint] NOT NULL CONSTRAINT [DF_INCASSO_ISSUER_PRIORITY_ORDER] DEFAULT ((0)),
[REC_STATE] [smallint] NOT NULL CONSTRAINT [DF_INCASSO_ISSUER_REC_STATE] DEFAULT ((0)),
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[INCASSO_ISSUER] ADD CONSTRAINT [PK_INCASSO_ISSUER] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
