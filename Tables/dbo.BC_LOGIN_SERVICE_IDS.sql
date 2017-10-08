CREATE TABLE [dbo].[BC_LOGIN_SERVICE_IDS]
(
[BC_LOGIN_ID] [int] NOT NULL,
[SERVICE_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[ID_IN_PROVIDER] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGIN_SERVICE_IDS] ADD CONSTRAINT [PK_BC_LOGIN_SERVICE_IDS] PRIMARY KEY CLUSTERED  ([BC_LOGIN_ID], [SERVICE_ID], [REC_ID]) ON [PRIMARY]
GO