CREATE TABLE [dbo].[LOAN_COLLATERAL_TYPES]
(
[TYPE_ID] [int] NOT NULL,
[CODE] [dbo].[TCODE] NOT NULL,
[CODE_LAT] [dbo].[TCODE] NULL,
[DESCRIP] [dbo].[TDESCRIP] NOT NULL,
[DESCRIP_LAT] [dbo].[TDESCRIP] NULL,
[CREDIT_LINE] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_COLLATERAL_TYPES] ADD CONSTRAINT [PK_LOAN_COLLATERAL_TYPES] PRIMARY KEY CLUSTERED  ([TYPE_ID]) ON [PRIMARY]
GO