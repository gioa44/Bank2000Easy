CREATE TABLE [dbo].[PLASTIC_CARDS]
(
[CARD_ID] [varchar] (19) COLLATE Latin1_General_BIN NOT NULL,
[CLIENT_NO] [int] NOT NULL,
[BIN] [int] NOT NULL,
[CARD_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_PLASTIC_CARDS_CARD_TYPE] DEFAULT ((0)),
[CARD_NAME] [varchar] (24) COLLATE Latin1_General_BIN NOT NULL,
[CARD_EXPIRY] [smalldatetime] NOT NULL,
[CLIENT_ADDRESS] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BASE_SUPP] [bit] NOT NULL CONSTRAINT [DF_PLASTIC_CARDS_BASE_SUPP] DEFAULT ((0)),
[PASSWORD] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CONTRACT] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[ENROLLED] [smalldatetime] NOT NULL,
[DEPT_NO] [int] NOT NULL,
[CONDITION_SET] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CARD_ID_OLD] [varchar] (19) COLLATE Latin1_General_BIN NULL,
[CLIENT_CATEGORY] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[PROD_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_PLASTIC_CARDS_PROD_CODE] DEFAULT (''),
[AUTHORIZE_CODE] [tinyint] NOT NULL CONSTRAINT [DF_PLASTIC_CARDS_AUTHORIZE_CODE] DEFAULT ((0)),
[AGR_RISK_LEVEL] [varchar] (5) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PLASTIC_CARDS] ADD CONSTRAINT [PK_PLASTIC_CARDS_1] PRIMARY KEY CLUSTERED  ([CARD_ID]) ON [PRIMARY]
GO
