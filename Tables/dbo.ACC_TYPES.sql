CREATE TABLE [dbo].[ACC_TYPES]
(
[ACC_TYPE] [tinyint] NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_TYPES] ADD CONSTRAINT [PK_ACC_TYPES] PRIMARY KEY CLUSTERED  ([ACC_TYPE]) ON [PRIMARY]
GO
