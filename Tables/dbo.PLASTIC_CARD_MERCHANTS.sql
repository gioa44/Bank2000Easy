CREATE TABLE [dbo].[PLASTIC_CARD_MERCHANTS]
(
[MERCHANT_ID] [int] NOT NULL,
[MERCHANT_TYPE] [tinyint] NOT NULL,
[RECV_BANK_CODE] [dbo].[TGEOBANKCODE] NOT NULL,
[RECV_ACC_N] [dbo].[TACCOUNT] NOT NULL,
[RECV_ACC_V] [dbo].[TACCOUNT] NOT NULL,
[RECV_ACC_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[OP_CODE] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[FEE_ACC_N] [dbo].[TACCOUNT] NOT NULL,
[FEE_ACC_V] [dbo].[TACCOUNT] NOT NULL,
[FEE_MIN_AMOUNT] [dbo].[TAMOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_FEE_MIN_AMOUNT] DEFAULT ((0)),
[FEE_PERCENT] [dbo].[TAMOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_FEE_PERCENT] DEFAULT ((0)),
[CONV_ACC_N] [dbo].[TACCOUNT] NULL,
[CONV_ACC_V] [dbo].[TACCOUNT] NULL,
[SENDER_ACC_N] [dbo].[TACCOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_SENDER_ACC_N] DEFAULT ((0)),
[SENDER_ACC_V] [dbo].[TACCOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_SENDER_ACC_V] DEFAULT ((0)),
[SENDER_ACC_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[SENDER_ACC_N_2] [dbo].[TACCOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_SENDER_ACC_N_2] DEFAULT ((0)),
[SENDER_ACC_V_2] [dbo].[TACCOUNT] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_MERCHANTS_SENDER_ACC_V_2] DEFAULT ((0)),
[SENDER_ACC_NAME_2] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FEE_BANK_CODE] [dbo].[TGEOBANKCODE] NULL,
[CONV_BANK_CODE] [dbo].[TGEOBANKCODE] NULL,
[SENDER_BANK_CODE] [dbo].[TGEOBANKCODE] NULL,
[SENDER_BANK_CODE_2] [dbo].[TGEOBANKCODE] NULL,
[IS_OUR_MERCHANT] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PLASTIC_CARD_MERCHANTS] ADD CONSTRAINT [PK_PLASTIC_CARD_MERCHANTS] PRIMARY KEY CLUSTERED  ([MERCHANT_ID]) ON [PRIMARY]
GO
