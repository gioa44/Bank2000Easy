CREATE TABLE [dbo].[BANK_TASKS]
(
[TASK_ID] [int] NOT NULL IDENTITY(1, 1),
[ACCESS_STRING] [dbo].[TACCESS] NOT NULL,
[ACCESS_STRING_2] [dbo].[TACCESS2] NOT NULL,
[DESCRIP] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BANK_TASKS] ADD CONSTRAINT [PK_BANK_TASKS] PRIMARY KEY CLUSTERED  ([TASK_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BANK_TASKS] ADD CONSTRAINT [IX_BANK_TASKS] UNIQUE NONCLUSTERED  ([DESCRIP]) ON [PRIMARY]
GO
