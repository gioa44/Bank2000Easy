CREATE TABLE [dbo].[DEPO_PRODUCT_ATTRIBUTES]
(
[PROD_ID] [int] NOT NULL,
[ATTRIB_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ATTRIB_VALUE] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [PK_DEPO_PRODUCT_ATTRIBUTES] PRIMARY KEY CLUSTERED  ([PROD_ID], [ATTRIB_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [FK_DEPO_PRODUCT_ATTRIBUTES_DEPO_PRODUCT] FOREIGN KEY ([PROD_ID]) REFERENCES [dbo].[DEPO_PRODUCT] ([PROD_ID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [FK_DEPO_PRODUCT_ATTRIBUTES_DEPO_PRODUCT_ATTRIB_CODES] FOREIGN KEY ([ATTRIB_CODE]) REFERENCES [dbo].[DEPO_PRODUCT_ATTRIB_CODES] ([CODE])
GO