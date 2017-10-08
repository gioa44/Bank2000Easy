CREATE TABLE [dbo].[ACC_PRODUCTS_FILTER]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[PRODUCT_NO] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[ACC_PRODUCTS_FILTER_TRIGGER] ON [dbo].[ACC_PRODUCTS_FILTER]
FOR INSERT, UPDATE, DELETE 
AS

EXEC _UPDATE_VERSION 'VER_ACC_PRODUCTS_F'
GO
ALTER TABLE [dbo].[ACC_PRODUCTS_FILTER] ADD CONSTRAINT [PK_ACC_PRODUCTS_FILTER] PRIMARY KEY CLUSTERED  ([BAL_ACC], [PRODUCT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_PRODUCTS_FILTER] ADD CONSTRAINT [FK_ACC_PRODUCTS_FILTER_ACC_PRODUCTS] FOREIGN KEY ([PRODUCT_NO]) REFERENCES [dbo].[ACC_PRODUCTS] ([PRODUCT_NO]) ON DELETE CASCADE
GO