CREATE TABLE [dbo].[ITRS_CODES]
(
[ID] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[COMMENT] [text] COLLATE Latin1_General_BIN NULL,
[DEBIT_CODE] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CREDIT_CODE] [varchar] (4) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[ITRS_CODES] ADD CONSTRAINT [PK_ITRS_CODES] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO