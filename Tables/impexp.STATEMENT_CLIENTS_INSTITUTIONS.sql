CREATE TABLE [impexp].[STATEMENT_CLIENTS_INSTITUTIONS]
(
[CLIENT_NO] [int] NOT NULL,
[RECEIVER_INSTITUTION] [dbo].[TINTBANKCODE] NOT NULL,
[RECEIVER_INSTITUTION_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[IS_ACTIVE] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[STATEMENT_CLIENTS_INSTITUTIONS] ADD CONSTRAINT [PK_STATEMENT_CLIENTS_INSTITUTIONS] PRIMARY KEY CLUSTERED  ([CLIENT_NO], [RECEIVER_INSTITUTION]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[STATEMENT_CLIENTS_INSTITUTIONS] ADD CONSTRAINT [FK_STATEMENT_CLIENTS_INSTITUTIONS_STATEMENT_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [impexp].[STATEMENT_CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO