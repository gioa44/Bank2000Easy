CREATE TABLE [dbo].[CALENDAR]
(
[DT] [smalldatetime] NOT NULL,
[DAY_TYPE] [tinyint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CALENDAR_TRIGGER] ON [dbo].[CALENDAR] 
FOR INSERT, UPDATE, DELETE 
AS

EXEC _UPDATE_VERSION 'VER_CALENDAR'
GO
ALTER TABLE [dbo].[CALENDAR] ADD CONSTRAINT [PK_CALENDAR] PRIMARY KEY CLUSTERED  ([DT]) ON [PRIMARY]
GO
