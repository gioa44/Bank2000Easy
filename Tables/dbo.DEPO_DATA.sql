CREATE TABLE [dbo].[DEPO_DATA]
(
[OP_ID] [int] NOT NULL,
[REC_STATE] [int] NOT NULL,
[AMOUNT] [money] NOT NULL,
[INT_RATE] [money] NOT NULL,
[ACCUMULATE] [bit] NOT NULL CONSTRAINT [DF_DEPO_DATA_ACUMULATE] DEFAULT ((0)),
[INC_AMOUNT] [money] NULL,
[MAX_AMOUNT] [money] NULL,
[OFFICER_ID] [int] NOT NULL,
[COMMENTS] [text] COLLATE Latin1_General_BIN NULL,
[END_DATE] [smalldatetime] NULL,
[MOVE_COUNT] [smallint] NULL,
[MOVE_COUNT_TYPE] [tinyint] NOT NULL,
[CALC_TYPE] [tinyint] NOT NULL,
[FORMULA] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[CLIENT_ACCOUNT] [int] NULL,
[PERC_CLIENT_ACCOUNT] [int] NULL,
[PERC_BANK_ACCOUNT] [int] NOT NULL,
[DAYS_IN_YEAR] [smallint] NOT NULL,
[CALC_AMOUNT] [money] NULL,
[TOTAL_CALC_AMOUNT] [money] NULL,
[TOTAL_PAYED_AMOUNT] [money] NULL,
[LAST_CALC_DATE] [smalldatetime] NULL,
[LAST_MOVE_DATE] [smalldatetime] NULL,
[PERC_FLAGS] [int] NOT NULL CONSTRAINT [DF_DEPO_DATA_PERC_FLAGS] DEFAULT ((0)),
[PERC_TYPE] [tinyint] NOT NULL,
[TAX_RATE] [money] NULL,
[START_DATE_TYPE] [tinyint] NULL,
[START_DATE_DAYS] [int] NULL,
[DATE_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_DEPO_DATA_DATE_TYPE] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_DATA] ADD CONSTRAINT [PK_DEPO_DATA] PRIMARY KEY CLUSTERED  ([OP_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_DATA] ADD CONSTRAINT [FK_DEPO_DATA_DEPO_OPS_OP_ID] FOREIGN KEY ([OP_ID]) REFERENCES [dbo].[DEPO_OPS] ([OP_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_DATA] ADD CONSTRAINT [FK_DEPO_DATA_USERS] FOREIGN KEY ([OFFICER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
