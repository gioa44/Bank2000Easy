CREATE TABLE [impexp].[SWIFT_CORR_BANKS]
(
[ISO_1] [dbo].[TISO] NOT NULL,
[BIC] [varchar] (11) COLLATE Latin1_General_BIN NOT NULL,
[ISO_2] [dbo].[TISO] NOT NULL,
[RECEIVER_BANK_CODE] [varchar] (11) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[SWIFT_CORR_BANKS] ADD CONSTRAINT [PK_SWIFT_CORR_BANKS] PRIMARY KEY CLUSTERED  ([ISO_1], [BIC], [ISO_2], [RECEIVER_BANK_CODE]) ON [PRIMARY]
GO
