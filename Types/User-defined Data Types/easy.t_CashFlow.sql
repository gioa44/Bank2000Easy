CREATE TYPE [easy].[t_CashFlow] AS TABLE
(
[FLOW_TYPE] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DATE] [datetime] NOT NULL,
[AMOUNT] [money] NOT NULL,
[AMOUNT_NOMINAL] [money] NULL,
[CCY_NOMINAL] [char] (3) COLLATE Latin1_General_BIN NULL,
[NAME] [nvarchar] (250) COLLATE Latin1_General_BIN NULL,
[YearSpan] [float] NULL,
PRIMARY KEY CLUSTERED  ([DATE], [FLOW_TYPE])
)
GO
