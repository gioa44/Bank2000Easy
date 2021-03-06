CREATE TABLE [dbo].[BC_CLIENT_CLIENTS]
(
[BC_CLIENT_ID] [int] NOT NULL,
[CLIENT_NO] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_CLIENT_CLIENTS] ADD CONSTRAINT [PK_BC_CLIENT_CLIENTS] PRIMARY KEY CLUSTERED  ([BC_CLIENT_ID], [CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_CLIENT_CLIENTS] ADD CONSTRAINT [FK_BC_CLIENT_CLIENTS_BC_CLIENTS] FOREIGN KEY ([BC_CLIENT_ID]) REFERENCES [dbo].[BC_CLIENTS] ([BC_CLIENT_ID])
GO
ALTER TABLE [dbo].[BC_CLIENT_CLIENTS] ADD CONSTRAINT [FK_BC_CLIENT_CLIENTS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO
