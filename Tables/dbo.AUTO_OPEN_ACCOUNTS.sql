CREATE TABLE [dbo].[AUTO_OPEN_ACCOUNTS]
(
[ACCOUNT] [dbo].[TACCOUNT] NOT NULL,
[GEL] [bit] NOT NULL CONSTRAINT [DF_AUTO_OPEN_ACCOUNTS_GEL] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AUTO_OPEN_ACCOUNTS] ADD CONSTRAINT [PK_AUTO_OPEN_ACCOUNTS] PRIMARY KEY CLUSTERED  ([ACCOUNT], [GEL]) ON [PRIMARY]
GO
