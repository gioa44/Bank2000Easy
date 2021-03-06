CREATE TABLE [dbo].[CLIENT_BANKING_PRODUCTS]
(
[CLIENT_NO] [int] NOT NULL,
[BANKING_PRODUCT_ID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_BANKING_PRODUCTS] ADD CONSTRAINT [PK_CLIENT_BANKING_PRODUCTS] PRIMARY KEY CLUSTERED  ([CLIENT_NO], [BANKING_PRODUCT_ID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_CLIENT_BANKING_PRODUCTS] ON [dbo].[CLIENT_BANKING_PRODUCTS] ([BANKING_PRODUCT_ID], [CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_BANKING_PRODUCTS] ADD CONSTRAINT [FK_CLIENT_BANKING_PRODUCTS_BANKING_PRODUCTS] FOREIGN KEY ([BANKING_PRODUCT_ID]) REFERENCES [dbo].[BANKING_PRODUCTS] ([PRODUCT_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CLIENT_BANKING_PRODUCTS] ADD CONSTRAINT [FK_CLIENT_BANKING_PRODUCTS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO
