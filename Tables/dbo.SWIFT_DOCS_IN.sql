CREATE TABLE [dbo].[SWIFT_DOCS_IN]
(
[OP_NUM] [int] NOT NULL,
[REC_ID] [int] NOT NULL,
[UID] [int] NOT NULL,
[DATE_ADD] [smalldatetime] NOT NULL CONSTRAINT [DF_SWIFT_DOCS_IN_DATE_ADD] DEFAULT (getdate()),
[DOC_DATE] [smalldatetime] NOT NULL,
[DOC_DATE_IN_DOC] [smalldatetime] NULL,
[ISO] [dbo].[TISO] NOT NULL,
[AMOUNT] [dbo].[TAMOUNT] NOT NULL,
[AMOUNT_EQU] [dbo].[TAMOUNT] NOT NULL,
[DOC_NUM] [int] NULL,
[OP_CODE] [dbo].[TOPCODE] NULL,
[DEBIT_ID] [int] NOT NULL,
[CREDIT_ID] [int] NOT NULL,
[REC_STATE] [tinyint] NOT NULL CONSTRAINT [DF_SWIFT_DOCS_IN_REC_STATE] DEFAULT ((0)),
[BNK_CLI_ID] [int] NULL,
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PARENT_REC_ID] [int] NULL,
[OWNER] [int] NOT NULL,
[DOC_TYPE] [smallint] NOT NULL,
[ACCOUNT_EXTRA] [dbo].[TACCOUNT] NULL,
[PROG_ID] [int] NULL,
[FOREIGN_ID] [int] NULL,
[CHANNEL_ID] [int] NULL,
[DEPT_NO] [int] NULL,
[IS_SUSPICIOUS] [bit] NOT NULL CONSTRAINT [DF_SWIFT_DOCS_IN_IS_SUSPICIOUS] DEFAULT ((0)),
[SENDER_BANK_CODE] [dbo].[TINTBANKCODE] NOT NULL,
[SENDER_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[SENDER_ACC] [dbo].[TINTACCOUNT] NOT NULL,
[SENDER_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_BANK_CODE] [varchar] (37) COLLATE Latin1_General_BIN NULL,
[RECEIVER_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[RECEIVER_ACC] [dbo].[TINTACCOUNT] NOT NULL,
[RECEIVER_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[INTERMED_BANK_CODE] [dbo].[TINTBANKCODE] NULL,
[INTERMED_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[EXTRA_INFO] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[SENDER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[RECEIVER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[SWIFT_TEXT] [text] COLLATE Latin1_General_BIN NULL,
[REF_NUM] [varchar] (32) COLLATE Latin1_General_BIN NULL,
[COR_BANK_CODE] [dbo].[TINTBANKCODE] NULL,
[COR_ACCOUNT] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[COR_BANK_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[SWIFT_REC_STATE] [tinyint] NOT NULL CONSTRAINT [DF_SWIFT_DOCS_IN_SWIFT_REC_STATE] DEFAULT ((0)),
[SWIFT_ADD_DATE] [smalldatetime] NOT NULL CONSTRAINT [DF_SWIFT_DOCS_IN_SWIFT_ADD_DATE] DEFAULT (getdate()),
[SWIFT_REC_ID] AS ((CONVERT([varchar](20),[REC_ID],(0))+'-')+[SENDER_BANK_CODE]),
[RECEIVER_INSTITUTION] [dbo].[TINTBANKCODE] NULL,
[RECEIVER_INSTITUTION_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[SWIFT_OP_CODE] AS (CONVERT([varchar](30),ltrim(isnull([OP_CODE],') + isnull(convert(varchar(25),ACCOUNT_EXTRA),')),(0))),
[DOC_DATE_STR] AS ([dbo].[FN_SWIFT_GET_DATE_STR]([DOC_DATE])),
[SENDER_ACC_SWIFT] AS ('/'+[SENDER_ACC]),
[SENDER_DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[DESCRIP_EXT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIN_DATE] [smalldatetime] NULL,
[FIN_ACCOUNT_ID] [int] NULL,
[FIN_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[FIN_AMOUNT] [dbo].[TAMOUNT] NULL,
[FIN_ISO] [dbo].[TISO] NULL,
[FIN_DOC_REC_ID] [int] NULL,
[DET_OF_CHARG] [char] (3) COLLATE Latin1_General_BIN NULL,
[EXTRA_INFO_DESCRIP] [bit] NULL,
[FLAGS] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[SWIFT_DOCS_IN] ADD CONSTRAINT [PK_SWIFT_DOCS_IN] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
