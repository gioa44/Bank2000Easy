CREATE TABLE [dbo].[LOAN_PRODUCT_ATTRIBUTES]
(
[PRODUCT_ID] [int] NOT NULL,
[ATTRIB_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ATTRIB_VALUE] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [PK_LOAN_PRODUCT_ATTRIBUTES] PRIMARY KEY CLUSTERED  ([PRODUCT_ID], [ATTRIB_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [FK_LOAN_PRODUCT_ATTRIBUTES_LOAN_PRODUCTS] FOREIGN KEY ([PRODUCT_ID]) REFERENCES [dbo].[LOAN_PRODUCTS] ([PRODUCT_ID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIBUTES] ADD CONSTRAINT [FK_LOAN_PRODUCT_ATTRIBUTES_LOAN_PRODUCTS_ATTRIB_CODES] FOREIGN KEY ([ATTRIB_CODE]) REFERENCES [dbo].[LOAN_PRODUCTS_ATTRIB_CODES] ([CODE])
GO