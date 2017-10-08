CREATE TABLE [dbo].[CCARD_TYPES]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RISK_LEVEL] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_CCARD_TYPES_RISK_LEVEL] DEFAULT ('A'),
[BIN] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
[MIN_AMOUNT] [dbo].[TAMOUNT] NULL CONSTRAINT [DF_CCARD_TYPES_MIN_AMOUNT] DEFAULT ((0)),
[DEPOSIT_AMOUNT] [dbo].[TAMOUNT] NULL CONSTRAINT [DF_CCARD_TYPES_DEPOSIT_AMOUNT] DEFAULT ((0)),
[CARD_EXPIRY_YEAR] [tinyint] NOT NULL CONSTRAINT [DF_CCARD_TYPES_CARD_EXPIRY_YEART] DEFAULT ((1)),
[CARD_COUNT] [int] NULL CONSTRAINT [DF_CCARD_TYPES_CARD_COUNT] DEFAULT ((1)),
[REC_STATE] [bit] NOT NULL CONSTRAINT [DF_CCARD_TYPES_REC_STATE] DEFAULT ((0)),
[AUTHORIZE_CODE] [tinyint] NOT NULL CONSTRAINT [DF_CCARD_TYPES_AUTHORIZE_CODE] DEFAULT ((0)),
[AGR_RISK_LEVEL] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[CARD_CHIP] [int] NULL,
[DESIGN_ID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CCARD_TYPES] ADD CONSTRAINT [PK_CCARD_TYPES] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO