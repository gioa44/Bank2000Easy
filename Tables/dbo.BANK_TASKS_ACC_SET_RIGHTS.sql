CREATE TABLE [dbo].[BANK_TASKS_ACC_SET_RIGHTS]
(
[TASK_ID] [int] NOT NULL,
[SET_ID] [smallint] NOT NULL,
[RIGHT_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BANK_TASKS_ACC_SET_RIGHTS] ADD CONSTRAINT [PK_BANK_TASKS_ACC_SET_RIGHTS] PRIMARY KEY CLUSTERED  ([TASK_ID], [SET_ID], [RIGHT_NAME]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BANK_TASKS_ACC_SET_RIGHTS] ADD CONSTRAINT [FK_BANK_TASKS_ACC_SET_RIGHTS_ACC_SET_RIGHT_NAMES] FOREIGN KEY ([RIGHT_NAME]) REFERENCES [dbo].[ACC_SET_RIGHT_NAMES] ([RIGHT_NAME]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BANK_TASKS_ACC_SET_RIGHTS] ADD CONSTRAINT [FK_BANK_TASKS_ACC_SET_RIGHTS_GROUPS] FOREIGN KEY ([TASK_ID]) REFERENCES [dbo].[BANK_TASKS] ([TASK_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[BANK_TASKS_ACC_SET_RIGHTS] ADD CONSTRAINT [FK_BANK_TASKS_ACC_SET_RIGHTS_SETS] FOREIGN KEY ([SET_ID]) REFERENCES [dbo].[ACC_SETS] ([SET_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
