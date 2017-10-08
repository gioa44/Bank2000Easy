CREATE TABLE [dbo].[DEPO_ATTRIBUTES]
(
[DEPO_ID] [int] NOT NULL,
[ATTRIB_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ATTRIB_VALUE] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_ATTRIBUTES] ADD CONSTRAINT [PK_DEPO_ATTRIBUTES] PRIMARY KEY CLUSTERED  ([DEPO_ID], [ATTRIB_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_ATTRIBUTES] ADD CONSTRAINT [FK_DEPO_ATTRIBUTES_DEPO_ATTRIB_CODES] FOREIGN KEY ([ATTRIB_CODE]) REFERENCES [dbo].[DEPO_ATTRIB_CODES] ([CODE]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_ATTRIBUTES] ADD CONSTRAINT [FK_DEPO_ATTRIBUTES_DEPO_DEPOSITS] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPO_DEPOSITS] ([DEPO_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO