CREATE TABLE [dbo].[DEPO_CLASSIFED]
(
[DEPO_ID] [int] NOT NULL,
[ID] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_CLASSIFED] ADD CONSTRAINT [PK_DEPO_CLASSIFED] PRIMARY KEY CLUSTERED  ([DEPO_ID], [ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_CLASSIFED] ADD CONSTRAINT [FK_DEPO_CLASSIFED_DEPO_CLASSIF] FOREIGN KEY ([ID]) REFERENCES [dbo].[DEPO_CLASSIF] ([ID]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_CLASSIFED] ADD CONSTRAINT [FK_DEPO_CLASSIFED_DEPO_DEPOSITS] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPO_DEPOSITS] ([DEPO_ID]) ON DELETE CASCADE
GO
