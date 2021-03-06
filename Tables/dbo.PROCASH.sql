CREATE TABLE [dbo].[PROCASH]
(
[SAFE_NR] [varchar] (8) COLLATE Latin1_General_BIN NOT NULL,
[PROCASH_NUM] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DEPT_NO] [int] NOT NULL,
[PROCASH_ACC_N] [dbo].[TACCOUNT] NOT NULL,
[PROCASH_ACC_V] [dbo].[TACCOUNT] NOT NULL,
[TRANSIT_ACC_N] [dbo].[TACCOUNT] NOT NULL,
[TRANSIT_ACC_V] [dbo].[TACCOUNT] NOT NULL,
[TIME_OUT] [tinyint] NOT NULL CONSTRAINT [DF_PROCASH_TIME_OUT] DEFAULT ((10)),
[TIME_STEP] [tinyint] NOT NULL CONSTRAINT [DF_PROCASH_TIME_STEP] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PROCASH] ADD CONSTRAINT [CK_PROCASH] CHECK (([TIME_OUT]>[TIME_STEP]))
GO
ALTER TABLE [dbo].[PROCASH] ADD CONSTRAINT [PK_PROCASH] PRIMARY KEY CLUSTERED  ([SAFE_NR]) ON [PRIMARY]
GO
