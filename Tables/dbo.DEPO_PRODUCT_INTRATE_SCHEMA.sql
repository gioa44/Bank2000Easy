CREATE TABLE [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA]
(
[SCHEMA_ID] [int] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DATE_TYPE] [tinyint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA] ADD CONSTRAINT [PK_DEPO_PRODUCT_INTRATE_SCHEMA] PRIMARY KEY CLUSTERED  ([SCHEMA_ID]) ON [PRIMARY]
GO
