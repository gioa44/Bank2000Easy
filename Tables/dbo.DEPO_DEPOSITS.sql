CREATE TABLE [dbo].[DEPO_DEPOSITS]
(
[DEPO_ID] [int] NOT NULL IDENTITY(1, 1),
[ROW_VERSION] [int] NOT NULL CONSTRAINT [DF_DEPO_DEPOSITS_ROW_VERSION] DEFAULT ((1)),
[BRANCH_ID] [int] NOT NULL,
[DEPT_NO] [int] NOT NULL,
[STATE] [tinyint] NOT NULL,
[ALARM_STATE] [tinyint] NOT NULL CONSTRAINT [DF_DEPO_DEPOSITS_ALARM_STATE] DEFAULT ((0)),
[CLIENT_NO] [int] NOT NULL,
[TRUST_DEPOSIT] [bit] NULL,
[TRUST_CLIENT_NO] [int] NULL,
[TRUST_EXTRA_INFO] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PROD_ID] [int] NOT NULL,
[AGREEMENT_NO] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DEPO_TYPE] [tinyint] NOT NULL,
[DEPO_ACC_SUBTYPE] [int] NOT NULL,
[DEPO_ACCOUNT_STATE] [tinyint] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[AGREEMENT_AMOUNT] [money] NULL,
[AMOUNT] [money] NOT NULL,
[DATE_TYPE] [tinyint] NOT NULL,
[PERIOD] [int] NULL,
[START_DATE] [smalldatetime] NOT NULL,
[END_DATE] [smalldatetime] NULL,
[ANNULMENT_DATE] [smalldatetime] NULL,
[INTRATE] [money] NOT NULL,
[REAL_INTRATE] [dbo].[TRATE] NOT NULL,
[PERC_FLAGS] [int] NOT NULL,
[DAYS_IN_YEAR] [smallint] NOT NULL,
[PROD_ACCRUE_MIN] [money] NULL,
[PROD_ACCRUE_MAX] [money] NULL,
[PROD_SPEND_MIN] [money] NULL,
[PROD_SPEND_MAX] [money] NULL,
[FORMULA] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[INTRATE_SCHEMA] [int] NOT NULL,
[ACCRUE_TYPE] [tinyint] NOT NULL,
[RECALCULATE_TYPE] [tinyint] NOT NULL,
[REALIZE_SCHEMA] [int] NOT NULL,
[REALIZE_TYPE] [tinyint] NOT NULL,
[REALIZE_COUNT] [smallint] NULL,
[REALIZE_COUNT_TYPE] [tinyint] NULL,
[DEPO_REALIZE_SCHEMA] [tinyint] NOT NULL,
[DEPO_REALIZE_SCHEMA_AMOUNT] [money] NULL,
[CONVERTIBLE] [bit] NOT NULL,
[PROLONGABLE] [bit] NOT NULL,
[PROLONGATION_COUNT] [int] NULL,
[RENEWABLE] [bit] NOT NULL,
[RENEW_CAPITALIZED] [bit] NOT NULL,
[RENEW_MAX] [int] NULL,
[RENEW_COUNT] [int] NULL,
[RENEW_LAST_PROD_ID] [int] NULL,
[LAST_RENEW_DATE] [smalldatetime] NULL,
[SHAREABLE] [bit] NOT NULL,
[SHARED_CONTROL_CLIENT_NO] [int] NULL,
[SHARED_CONTROL] [bit] NOT NULL,
[REVISION_SCHEMA] [int] NOT NULL,
[REVISION_TYPE] [tinyint] NOT NULL,
[REVISION_COUNT] [smallint] NULL,
[REVISION_COUNT_TYPE] [tinyint] NULL,
[REVISION_GRACE_ITEMS] [int] NULL,
[REVISION_GRACE_DATE_TYPE] [tinyint] NULL,
[ANNULMENTED] [bit] NOT NULL,
[ANNULMENT_REALIZE] [bit] NOT NULL,
[ANNULMENT_SCHEMA] [int] NULL,
[ANNULMENT_SCHEMA_ADVANCE] [int] NULL,
[INTEREST_REALIZE_ADV] [bit] NOT NULL,
[INTEREST_REALIZE_ADV_AMOUNT] [money] NULL,
[CHILD_DEPOSIT] [bit] NOT NULL,
[CHILD_CONTROL_OWNER] [bit] NOT NULL,
[CHILD_CONTROL_CLIENT_NO_1] [int] NULL,
[CHILD_CONTROL_CLIENT_NO_2] [int] NULL,
[ACCUMULATIVE] [bit] NOT NULL,
[ACCUMULATE_PRODUCT] [bit] NOT NULL,
[ACCUMULATE_MIN] [money] NULL,
[ACCUMULATE_MAX] [money] NULL,
[ACCUMULATE_AMOUNT] [money] NULL,
[ACCUMULATE_MAX_AMOUNT_LIMIT] [money] NULL,
[ACCUMULATE_MAX_AMOUNT] [money] NULL,
[ACCUMULATE_SCHEMA_INTRATE] [tinyint] NULL,
[SPEND] [bit] NOT NULL,
[SPEND_INTRATE] [money] NULL,
[SPEND_AMOUNT] [money] NULL,
[SPEND_AMOUNT_INTRATE] [money] NULL,
[SPEND_CONST_AMOUNT] [money] NULL,
[DEPO_REALIZE_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_DEPO_DEPOSITS_DEPO_REALIZE_TYPE] DEFAULT ((1)),
[CREDITCARD_BALANCE_CHECK] [bit] NOT NULL,
[INTEREST_REALIZE_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_DEPO_DEPOSITS_INTEREST_REALIZE_TYPE] DEFAULT ((1)),
[DEPO_FILL_ACC_ID] [int] NULL,
[DEPO_ACC_ID] [int] NOT NULL,
[LOSS_ACC_ID] [int] NOT NULL,
[ACCRUAL_ACC_ID] [int] NOT NULL,
[DEPO_REALIZE_ACC_ID] [int] NULL,
[INTEREST_REALIZE_ACC_ID] [int] NULL,
[INTEREST_REALIZE_ADV_ACC_ID] [int] NULL,
[RESPONSIBLE_USER_ID] [int] NOT NULL,
[DEPO_NOTE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALARM_NOTE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEPOSIT_DEFAULT] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [PK_DEPO_DEPOSITS] PRIMARY KEY CLUSTERED  ([DEPO_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACC_SUBTYPES] FOREIGN KEY ([DEPO_ACC_SUBTYPE]) REFERENCES [dbo].[ACC_SUBTYPES] ([ACC_SUBTYPE])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS] FOREIGN KEY ([INTEREST_REALIZE_ADV_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_ACCRUAL_ACC_ID] FOREIGN KEY ([ACCRUAL_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_DEPO_ACC_ID] FOREIGN KEY ([DEPO_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_DEPO_FILL_ACC_ID] FOREIGN KEY ([DEPO_FILL_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_DEPO_REALIZE_ACC_ID] FOREIGN KEY ([DEPO_REALIZE_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_INTEREST_REALIZE_ACC_ID] FOREIGN KEY ([INTEREST_REALIZE_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_ACCOUNTS_LOSS_ACC_ID] FOREIGN KEY ([LOSS_ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_CLIENTS_CHILD_CONTROL_CLIENT_NO_1] FOREIGN KEY ([CHILD_CONTROL_CLIENT_NO_1]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_CLIENTS_CHILD_CONTROL_CLIENT_NO_2] FOREIGN KEY ([CHILD_CONTROL_CLIENT_NO_2]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_CLIENTS_SHARED_CONTROL_CLIENT_NO] FOREIGN KEY ([SHARED_CONTROL_CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_DEPO_PRODUCT_INTRATE_SCHEMA] FOREIGN KEY ([INTRATE_SCHEMA]) REFERENCES [dbo].[DEPO_PRODUCT_INTRATE_SCHEMA] ([SCHEMA_ID]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_DEPO_PRODUCT_REALIZE_SCHEMA] FOREIGN KEY ([REALIZE_SCHEMA]) REFERENCES [dbo].[DEPO_PRODUCT_REALIZE_SCHEMA] ([SCHEMA_ID]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_DEPO_PRODUCT_REVISION_SCHEMA] FOREIGN KEY ([REVISION_SCHEMA]) REFERENCES [dbo].[DEPO_PRODUCT_REVISION_SCHEMA] ([SCHEMA_ID])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_DEPTS_BRANCH_ID] FOREIGN KEY ([BRANCH_ID]) REFERENCES [dbo].[DEPTS] ([DEPT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_DEPTS_DEPT_NO] FOREIGN KEY ([DEPT_NO]) REFERENCES [dbo].[DEPTS] ([DEPT_NO])
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_USERS] FOREIGN KEY ([RESPONSIBLE_USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_DEPOSITS] ADD CONSTRAINT [FK_DEPO_DEPOSITS_VAL_CODES] FOREIGN KEY ([ISO]) REFERENCES [dbo].[VAL_CODES] ([ISO])
GO
