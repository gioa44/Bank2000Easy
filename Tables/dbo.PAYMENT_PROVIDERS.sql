CREATE TABLE [dbo].[PAYMENT_PROVIDERS]
(
[PROVIDER_ID] [int] NOT NULL IDENTITY(1, 100),
[PROVIDER_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_NAME_LAT] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_SRV_TYPE_LABEL] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_SRV_TYPE_LABEL_LAT] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_INFO1] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_INFO1_LAT] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_INFO2] [text] COLLATE Latin1_General_BIN NOT NULL,
[PROVIDER_INFO2_LAT] [text] COLLATE Latin1_General_BIN NOT NULL,
[ASSEMBLY_NAME] [sys].[sysname] NULL,
[CLASS_NAME] [sys].[sysname] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[PAYMENT_PROVIDERS] ADD CONSTRAINT [PK_PAYMENT_PROVIDERS] PRIMARY KEY CLUSTERED  ([PROVIDER_ID]) ON [PRIMARY]
GO
