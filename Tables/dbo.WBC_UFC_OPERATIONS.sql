CREATE TABLE [dbo].[WBC_UFC_OPERATIONS]
(
[REF_ID] [int] NOT NULL IDENTITY(1, 1),
[OP_TYPE] [tinyint] NOT NULL,
[REC_STATE] [tinyint] NOT NULL CONSTRAINT [DF_WBC_CCARD_TRANSFERS_REC_STATE] DEFAULT ((0)),
[DT_TM] [smalldatetime] NOT NULL CONSTRAINT [DF_WBC_UFC_OPERATIONS_DT_TM] DEFAULT (getdate()),
[CARD_ID] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[AMOUNT] [dbo].[TAMOUNT] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL CONSTRAINT [DF_WBC_UFC_OPERATIONS_ISO] DEFAULT ('GEL'),
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[RECEIVER_ACC] [dbo].[TACCOUNT] NULL,
[CHARGER_ID] [int] NULL,
[CHARGE_ID] [int] NULL,
[PHONE_CARD_TYPE] [tinyint] NULL,
[PHONE_CARD_ID] [int] NULL,
[RESP_CARD_ID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RESP_RESPONSE] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RESP_APPR_CODE] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RESP_TR_AMOUNT] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RESP_REF_NUM] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WBC_UFC_OPERATIONS] ADD CONSTRAINT [PK_WBC_UFC_OPERATIONS] PRIMARY KEY CLUSTERED  ([REF_ID]) ON [PRIMARY]
GO
