CREATE TABLE [dbo].[BC_LOGINS]
(
[BC_LOGIN_ID] [int] NOT NULL IDENTITY(1, 1),
[BC_CLIENT_ID] [int] NOT NULL,
[BC_LOGIN] [varchar] (12) COLLATE Latin1_General_BIN NOT NULL,
[FLAGS] [int] NOT NULL CONSTRAINT [DF_BC_LOGINS_FLAGS] DEFAULT ((0)),
[FLAGS2] [int] NOT NULL CONSTRAINT [DF_BC_LOGINS_FLAGS2] DEFAULT ((0)),
[FLAGS3] [int] NOT NULL CONSTRAINT [DF_BC_LOGINS_FLAGS3] DEFAULT ((0)),
[BC_PIN] [char] (32) COLLATE Latin1_General_BIN NULL,
[INTERNET_PIN] [char] (32) COLLATE Latin1_General_BIN NULL,
[PHONE_PIN] [char] (32) COLLATE Latin1_General_BIN NULL,
[DEADLINE] [smalldatetime] NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PUB_KEY] [text] COLLATE Latin1_General_BIN NULL,
[LOCKED_UNTIL] [smalldatetime] NULL,
[PSW_MUST_BE_CHANGED] [bit] NOT NULL CONSTRAINT [DF_BC_LOGINS_PSW_MUST_BE_CHANGED] DEFAULT ((0)),
[LOGIN_COUNTER] [int] NOT NULL CONSTRAINT [DF_BC_LOGINS_LOGIN_COUNTER] DEFAULT ((0)),
[LAST_LOGIN] [datetime] NULL,
[REG_DATE] [smalldatetime] NOT NULL CONSTRAINT [DF_BC_LOGINS_REG_DATE] DEFAULT (getdate()),
[DEADLINE2] [smalldatetime] NULL,
[FINISH_DATE] [smalldatetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGINS] ADD CONSTRAINT [PK_BC_LOGINS] PRIMARY KEY CLUSTERED  ([BC_LOGIN_ID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_BC_LOGINS_BC_CLIENT_ID] ON [dbo].[BC_LOGINS] ([BC_CLIENT_ID], [BC_LOGIN]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGINS] ADD CONSTRAINT [FK_BC_LOGINS_BC_CLIENTS] FOREIGN KEY ([BC_CLIENT_ID]) REFERENCES [dbo].[BC_CLIENTS] ([BC_CLIENT_ID])
GO