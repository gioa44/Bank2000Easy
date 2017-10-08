CREATE TABLE [dbo].[BC_PLAT_TEMPLATES]
(
[BC_LOGIN_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[TEMPLATE_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[AMOUNT] [dbo].[TAMOUNT] NULL,
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SENDER_ACC] [dbo].[TACCOUNT] NOT NULL,
[RECEIVER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[RECEIVER_BANK_CODE] [dbo].[TINTBANKCODE] NOT NULL,
[RECEIVER_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_ACC] [dbo].[TINTACCOUNT] NOT NULL,
[RECEIVER_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[INTERMED_BANK_CODE] [dbo].[TINTBANKCODE] NULL,
[INTERMED_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[RECEIVER_INFO] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SAXAZKOD] [char] (4) COLLATE Latin1_General_BIN NULL,
[CREATE_DATE] [smalldatetime] NOT NULL CONSTRAINT [DF_BC_PLAT_TEMPLATES_CREATE_DATE] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_PLAT_TEMPLATES] ADD CONSTRAINT [PK_BC_PLAT_TEMPLATES] PRIMARY KEY CLUSTERED  ([BC_LOGIN_ID], [REC_ID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_BC_PLAT_TEMPLATES] ON [dbo].[BC_PLAT_TEMPLATES] ([BC_LOGIN_ID], [TEMPLATE_NAME]) ON [PRIMARY]
GO
