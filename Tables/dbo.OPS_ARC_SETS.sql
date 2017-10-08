CREATE TABLE [dbo].[OPS_ARC_SETS]
(
[SET_ID] [smallint] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[JOIN_SQL] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[WHERE_SQL] [nvarchar] (4000) COLLATE Latin1_General_BIN NOT NULL,
[IS_EXCEPTION] [bit] NOT NULL CONSTRAINT [DF_OPS_ARC_SETS_IS_EXCEPTION] DEFAULT ((0)),
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OPS_ARC_SETS] ADD CONSTRAINT [PK_OPS_ARC_SETS] PRIMARY KEY CLUSTERED  ([SET_ID]) ON [PRIMARY]
GO
