CREATE TABLE [dbo].[Turns_tmp_report]
(
[Dt] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[DEBIT_ACCOUNT] [dbo].[TACCOUNT] NOT NULL,
[CREDIT_ACCOUNT] [dbo].[TACCOUNT] NOT NULL,
[DEBIT_DESCRIP] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[CREDIT_DESCRIP] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[AMOUNT] [money] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[AMOUNT_EQU] [money] NOT NULL,
[O_DESCRIP] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
