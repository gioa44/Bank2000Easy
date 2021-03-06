CREATE TABLE [dbo].[DEPO_PRODUCTS]
(
[PROD_ID] [int] NOT NULL IDENTITY(1, 1),
[PROD_NO] [tinyint] NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[REG_DATE] [smalldatetime] NOT NULL CONSTRAINT [DF_DEPO_PRODUCTS_REG_DATE] DEFAULT (getdate()),
[ACTIVE] [bit] NOT NULL,
[DEPO_TYPE_ID] [int] NOT NULL CONSTRAINT [DF_DEPO_PRODUCTS_DEPO_TYPE_ID] DEFAULT ((1)),
[CLIENT_TYPE] [int] NOT NULL,
[MOVE_METHOD] [tinyint] NOT NULL,
[PERC_METHOD] [int] NOT NULL,
[PERC_CORRECT] [money] NULL CONSTRAINT [DF_DEPO_PRODUCTS_PERC_CORRECT] DEFAULT ((0)),
[ACRUAL_ACCOUNT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DISB_ACCOUNT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DEPOSIT_ACCOUNT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[PERC_FLAGS] [int] NOT NULL,
[DAYS_IN_YEAR] [smallint] NOT NULL,
[MAX_DAYS] [int] NULL,
[NO_CLIENT_ACCOUNT] [bit] NOT NULL CONSTRAINT [DF_DEPO_PRODUCTS_NO_CLIENT_ACCOUNT] DEFAULT ((0)),
[PROLONGATION] [bit] NOT NULL CONSTRAINT [DF_DEPO_PRODUCTS_PROLONGATION] DEFAULT ((0)),
[ANNULMENT_METHOD] [int] NULL,
[REALIZE_ADVANCE] [bit] NOT NULL,
[REALIZE_ADV_ACCOUNT] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[CONVERTED_DEPOSIT] [bit] NOT NULL,
[DEPO_ACC_SUBTYPE] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [PK_DP_PRODUCTS] PRIMARY KEY CLUSTERED  ([PROD_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [IX_DP_PRODUCTS] UNIQUE NONCLUSTERED  ([DESCRIP]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [FK_DEPO_PRODUCTS_DEPO_ANNULMENT_METHODS] FOREIGN KEY ([ANNULMENT_METHOD]) REFERENCES [dbo].[DEPO_ANNULMENT_METHODS] ([METHOD_ID])
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [FK_DEPO_PRODUCTS_DEPO_MOVE_METHODS] FOREIGN KEY ([MOVE_METHOD]) REFERENCES [dbo].[DEPO_MOVE_METHODS] ([METHOD_ID])
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [FK_DEPO_PRODUCTS_DEPO_PERC_METHODS] FOREIGN KEY ([PERC_METHOD]) REFERENCES [dbo].[DEPO_PERC_METHODS] ([METHOD_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_PRODUCTS] ADD CONSTRAINT [FK_PRODUCTS_DEPO_TYPES] FOREIGN KEY ([DEPO_TYPE_ID]) REFERENCES [dbo].[DEPO_TYPES] ([DEPO_TYPE_ID])
GO
