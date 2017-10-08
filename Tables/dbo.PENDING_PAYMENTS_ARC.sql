CREATE TABLE [dbo].[PENDING_PAYMENTS_ARC]
(
[DOC_REC_ID] [int] NOT NULL,
[IS_ONLINE] [bit] NOT NULL,
[PROVIDER_ID] [int] NOT NULL,
[SERVICE_ALIAS] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DOC_TYPE] [smallint] NOT NULL,
[OWNER] [int] NOT NULL,
[DEPT_NO] [int] NOT NULL,
[CHANNEL_ID] [int] NOT NULL,
[REC_STATE] [int] NOT NULL,
[SORT_ORDER] [int] NOT NULL,
[DT_TM] [smalldatetime] NOT NULL,
[AMOUNT] [money] NOT NULL,
[ID_IN_PROVIDER] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ID2_IN_PROVIDER] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CARD_ID] [varchar] (19) COLLATE Latin1_General_BIN NULL,
[CARD_TYPE] [smallint] NULL,
[INFO] [text] COLLATE Latin1_General_BIN NULL,
[RESPONSE] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[REF_NUM] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[INSERT_TIME] [datetime] NULL,
[PAUSED] [bit] NULL,
[LOCK_FLAG] [int] NULL,
[WAITING_FLAG] [int] NULL,
[DELETE_FLAG] [int] NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
