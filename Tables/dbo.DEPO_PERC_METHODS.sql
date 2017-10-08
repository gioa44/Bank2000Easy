CREATE TABLE [dbo].[DEPO_PERC_METHODS]
(
[METHOD_ID] [int] NOT NULL IDENTITY(1, 1),
[METHOD_DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PERC_METHODS] ADD CONSTRAINT [PK_DEPO_PERC_METHODS] PRIMARY KEY CLUSTERED  ([METHOD_ID]) ON [PRIMARY]
GO
