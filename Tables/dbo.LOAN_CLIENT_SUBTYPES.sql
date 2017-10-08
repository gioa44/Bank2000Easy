CREATE TABLE [dbo].[LOAN_CLIENT_SUBTYPES]
(
[TYPE_ID] [tinyint] NOT NULL,
[BIT_ORDER] [tinyint] NOT NULL,
[DESCRIP] [dbo].[TDESCRIP] NOT NULL,
[DESCRIP_LAT] [dbo].[TDESCRIP] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_CLIENT_SUBTYPES] ADD CONSTRAINT [PK_LOAN_CLIENT_SUBTYPES] PRIMARY KEY CLUSTERED  ([TYPE_ID]) ON [PRIMARY]
GO