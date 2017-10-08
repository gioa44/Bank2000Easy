CREATE TABLE [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS]
(
[SCHEMA_ID] [int] NOT NULL,
[ITEMS] [int] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[INTRATE] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS] ADD CONSTRAINT [PK_DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS] PRIMARY KEY CLUSTERED  ([SCHEMA_ID], [ITEMS], [ISO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS] ADD CONSTRAINT [FK_DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS_DEPO_PRODUCT_INTRATE_SCHEMA] FOREIGN KEY ([SCHEMA_ID]) REFERENCES [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA] ([SCHEMA_ID]) ON DELETE CASCADE
GO
