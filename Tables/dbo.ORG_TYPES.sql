CREATE TABLE [dbo].[ORG_TYPES]
(
[ORG_TYPE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[TAX9] [bit] NOT NULL CONSTRAINT [DF_ORG_TYPES_TAX9] DEFAULT ((0)),
[TAX11] [bit] NOT NULL CONSTRAINT [DF_ORG_TYPES_TAX11] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ORG_TYPES] ADD CONSTRAINT [PK_ORG_TYPES] PRIMARY KEY CLUSTERED  ([ORG_TYPE]) ON [PRIMARY]
GO
