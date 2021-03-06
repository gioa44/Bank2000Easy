CREATE TABLE [dbo].[OTHER_CLIENT_INFO]
(
[PERSONAL_ID] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[FIRST_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[LAST_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FATHERS_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[BIRTH_DATE] [smalldatetime] NULL,
[BIRTH_PLACE] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ADDRESS_JUR] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ADDRESS_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[COUNTRY] [char] (2) COLLATE Latin1_General_BIN NULL,
[PASSPORT_TYPE_ID] [tinyint] NOT NULL,
[PASSPORT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[REG_ORGAN] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PASSPORT_ISSUE_DT] [smalldatetime] NULL,
[PASSPORT_END_DATE] [smalldatetime] NULL,
[BLOB_DATA] [image] NULL,
[BLOB_DATA2] [image] NULL,
[BLOB_DATA3] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [BLOBS]
GO
ALTER TABLE [dbo].[OTHER_CLIENT_INFO] ADD CONSTRAINT [PK_OTHER_CLIENT_INFO] PRIMARY KEY CLUSTERED  ([PERSONAL_ID]) ON [PRIMARY]
GO
