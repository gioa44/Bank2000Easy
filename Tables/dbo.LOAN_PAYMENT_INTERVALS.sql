CREATE TABLE [dbo].[LOAN_PAYMENT_INTERVALS]
(
[TYPE_ID] [int] NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[INTERVAL] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_PAYMENT_INTERVALS] ADD CONSTRAINT [PK_LOAN_PAYMENT_INTERVALS] PRIMARY KEY CLUSTERED  ([TYPE_ID]) ON [PRIMARY]
GO
