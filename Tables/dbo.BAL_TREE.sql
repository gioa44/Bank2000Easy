CREATE TABLE [dbo].[BAL_TREE]
(
[BAL_ACC] [smallint] NOT NULL,
[BAL_ACC_PARENT] [smallint] NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BAL_TREE] ADD CONSTRAINT [PK_BAL_TREE] PRIMARY KEY CLUSTERED  ([BAL_ACC]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BAL_TREE] WITH NOCHECK ADD CONSTRAINT [FK_BAL_TREE_BAL_TREE] FOREIGN KEY ([BAL_ACC_PARENT]) REFERENCES [dbo].[BAL_TREE] ([BAL_ACC])
GO
