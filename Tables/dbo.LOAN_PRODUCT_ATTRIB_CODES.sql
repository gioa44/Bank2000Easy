CREATE TABLE [dbo].[LOAN_PRODUCT_ATTRIB_CODES]
(
[CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[PRODUCT_ID] [int] NOT NULL,
[IS_REQUIRED] [tinyint] NOT NULL CONSTRAINT [DF_LOAN_PRODUCT_ATTRIB_CODES_IS_REQUIRED] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIB_CODES] ADD CONSTRAINT [PK_LOAN_PRODUCT_ATTRIB_CODES] PRIMARY KEY CLUSTERED  ([CODE], [PRODUCT_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIB_CODES] ADD CONSTRAINT [FK_LOAN_PRODUCT_ATTRIB_CODES_LOAN_ATTRIB_CODES] FOREIGN KEY ([CODE]) REFERENCES [dbo].[LOAN_ATTRIB_CODES] ([CODE])
GO
ALTER TABLE [dbo].[LOAN_PRODUCT_ATTRIB_CODES] ADD CONSTRAINT [FK_LOAN_PRODUCT_ATTRIB_CODES_LOAN_PRODUCTS] FOREIGN KEY ([PRODUCT_ID]) REFERENCES [dbo].[LOAN_PRODUCTS] ([PRODUCT_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO