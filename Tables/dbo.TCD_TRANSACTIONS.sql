CREATE TABLE [dbo].[TCD_TRANSACTIONS]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[TCD_SERIAL_ID] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[OP_ID] [int] NOT NULL,
[COMMAND_ID] [int] NOT NULL,
[MOVE_FORWARD_OP_ID] [int] NOT NULL,
[CASETTE_SER_ID_0] [int] NULL,
[CASETTE_POSITION_0] [int] NULL,
[CASETTE_PREV_BALANCE_0] [int] NULL,
[CASETTE_REJECTED_NUM_0] [int] NULL,
[CASETTE_BALANCE_0] [int] NULL,
[CASETTE_SER_ID_1] [int] NULL,
[CASETTE_POSITION_1] [int] NULL,
[CASETTE_CCY_1] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_1] [int] NULL,
[CASETTE_PREV_BALANCE_1] [int] NULL,
[CASETTE_REQUESTED_NUM_1] [int] NULL,
[CASETTE_DISPENSED_NUM_1] [int] NULL,
[CASETTE_BALANCE_1] [int] NULL,
[CASETTE_SER_ID_2] [int] NULL,
[CASETTE_POSITION_2] [int] NULL,
[CASETTE_CCY_2] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_2] [int] NULL,
[CASETTE_PREV_BALANCE_2] [int] NULL,
[CASETTE_REQUESTED_NUM_2] [int] NULL,
[CASETTE_DISPENSED_NUM_2] [int] NULL,
[CASETTE_BALANCE_2] [int] NULL,
[CASETTE_SER_ID_3] [int] NULL,
[CASETTE_POSITION_3] [int] NULL,
[CASETTE_CCY_3] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_3] [int] NULL,
[CASETTE_PREV_BALANCE_3] [int] NULL,
[CASETTE_REQUESTED_NUM_3] [int] NULL,
[CASETTE_DISPENSED_NUM_3] [int] NULL,
[CASETTE_BALANCE_3] [int] NULL,
[CASETTE_SER_ID_4] [int] NULL,
[CASETTE_POSITION_4] [int] NULL,
[CASETTE_CCY_4] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_4] [int] NULL,
[CASETTE_PREV_BALANCE_4] [int] NULL,
[CASETTE_REQUESTED_NUM_4] [int] NULL,
[CASETTE_DISPENSED_NUM_4] [int] NULL,
[CASETTE_BALANCE_4] [int] NULL,
[CASETTE_SER_ID_5] [int] NULL,
[CASETTE_POSITION_5] [int] NULL,
[CASETTE_CCY_5] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_5] [int] NULL,
[CASETTE_PREV_BALANCE_5] [int] NULL,
[CASETTE_REQUESTED_NUM_5] [int] NULL,
[CASETTE_DISPENSED_NUM_5] [int] NULL,
[CASETTE_BALANCE_5] [int] NULL,
[CASETTE_SER_ID_6] [int] NULL,
[CASETTE_POSITION_6] [int] NULL,
[CASETTE_CCY_6] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN_6] [int] NULL,
[CASETTE_PREV_BALANCE_6] [int] NULL,
[CASETTE_REQUESTED_NUM_6] [int] NULL,
[CASETTE_DISPENSED_NUM_6] [int] NULL,
[CASETTE_BALANCE_6] [int] NULL,
[USER_ID] [int] NOT NULL,
[OP_DATE] [smalldatetime] NOT NULL,
[REPLY_MSG_ID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TCD_TRANSACTIONS] ADD CONSTRAINT [PK_TCD_TRANSACTIONS] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TCD_TRANSACTIONS] ADD CONSTRAINT [FK_TCD_TRANSACTIONS_TCD_OPS] FOREIGN KEY ([OP_ID]) REFERENCES [dbo].[TCD_OPS] ([OP_ID])
GO
ALTER TABLE [dbo].[TCD_TRANSACTIONS] ADD CONSTRAINT [FK_TCD_TRANSACTIONS_TCD_REPLY_MSG] FOREIGN KEY ([REPLY_MSG_ID]) REFERENCES [dbo].[TCD_REPLY_MSG] ([MSG_ID])
GO