CREATE TABLE [dbo].[DOC_DETAILS_PASSPORTS]
(
[DOC_REC_ID] [int] NOT NULL,
[FIRST_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[LAST_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FATHERS_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[BIRTH_DATE] [smalldatetime] NULL,
[BIRTH_PLACE] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ADDRESS_JUR] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ADDRESS_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[COUNTRY] [char] (2) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_DOC_DETAILS_PASSPORTS_COUNTRY] DEFAULT ('GE'),
[PASSPORT_TYPE_ID] [tinyint] NOT NULL CONSTRAINT [DF_DOC_DETAILS_PASSPORTS_PASSPORT_TYPE_ID] DEFAULT ((0)),
[PASSPORT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PERSONAL_ID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[REG_ORGAN] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PASSPORT_ISSUE_DT] [smalldatetime] NULL,
[PASSPORT_END_DATE] [smalldatetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_DETAILS_PASSPORTS] ADD CONSTRAINT [PK_DOC_DETAILS_PASSPORTS] PRIMARY KEY CLUSTERED  ([DOC_REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_DETAILS_PASSPORTS] ADD CONSTRAINT [FK_DOC_DETAILS_PASSPORTS_REC_ID_IN_OPS] FOREIGN KEY ([DOC_REC_ID]) REFERENCES [dbo].[OPS_0000] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
