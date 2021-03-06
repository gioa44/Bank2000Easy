CREATE TABLE [dbo].[DOC_DETAILS_VALPLAT]
(
[DOC_REC_ID] [int] NOT NULL,
[SENDER_BANK_CODE] [varchar] (37) COLLATE Latin1_General_BIN NOT NULL,
[SENDER_ACC] [varchar] (37) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_BANK_CODE] [varchar] (37) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_ACC] [varchar] (37) COLLATE Latin1_General_BIN NOT NULL,
[SENDER_BANK_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[RECEIVER_BANK_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[SENDER_ACC_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[RECEIVER_ACC_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[INTERMED_BANK_CODE] [varchar] (37) COLLATE Latin1_General_BIN NULL,
[INTERMED_BANK_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[EXTRA_INFO] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SENDER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[RECEIVER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[REF_NUM] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[COR_BANK_CODE] [varchar] (37) COLLATE Latin1_General_BIN NULL,
[COR_BANK_NAME] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[SWIFT_TEXT] [text] COLLATE Latin1_General_BIN NULL,
[DET_OF_CHARG] [char] (3) COLLATE Latin1_General_BIN NULL,
[EXTRA_INFO_DESCRIP] [bit] NULL,
[SENDER_ADDRESS_LAT] [varchar] (105) COLLATE Latin1_General_BIN NULL,
[RECEIVER_ADDRESS_LAT] [varchar] (105) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[ON_VALPLAT_DETAIL_INSERT_UPDATE] ON [dbo].[DOC_DETAILS_VALPLAT]
FOR INSERT, UPDATE
AS

IF @@ROWCOUNT > 1 OR dbo.bank_server_state() <> 0
	RETURN 

SET NOCOUNT ON

DECLARE
  @bank_code TINTBANKCODE,
  @account TINTACCOUNT,
  @descrip varchar(100),
  @doc_rec_id int

SELECT @doc_rec_id = DOC_REC_ID, @bank_code = SENDER_BANK_CODE, @account = SENDER_ACC, @descrip = SENDER_ACC_NAME
FROM inserted

SET @descrip = RTRIM(LTRIM(@descrip))
IF @descrip = '' OR @descrip IS NULL RETURN

IF dbo.bank_is_int_bank_in_our_db (@bank_code) = 0
BEGIN
  IF NOT EXISTS(SELECT * FROM dbo.OTHER_ACCOUNTS (NOLOCK) WHERE BANK_CODE=@bank_code AND ACCOUNT=@account)
    INSERT INTO dbo.OTHER_ACCOUNTS VALUES (@bank_code,@account,@descrip,NULL,1)
END

SELECT @bank_code = RECEIVER_BANK_CODE, @account = RECEIVER_ACC, @descrip = RECEIVER_ACC_NAME
FROM INSERTED

DECLARE @doc_type smallint

SELECT @doc_type = DOC_TYPE 
FROM dbo.OPS_0000 (NOLOCK)
WHERE REC_ID = @doc_rec_id

IF (NOT @doc_type IN (113,114,116)) -- charicxva fil, charicxva, transit
	AND dbo.bank_is_int_bank_in_our_db (@bank_code) = 0
BEGIN
  IF NOT EXISTS(SELECT * FROM dbo.OTHER_ACCOUNTS (NOLOCK) WHERE BANK_CODE = @bank_code AND ACCOUNT = @account)
    INSERT INTO dbo.OTHER_ACCOUNTS
	VALUES(@bank_code, @account, @descrip, NULL, 1)
END
GO
ALTER TABLE [dbo].[DOC_DETAILS_VALPLAT] ADD CONSTRAINT [PK_DOC_DETAILS_VALPLAT] PRIMARY KEY CLUSTERED  ([DOC_REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_DETAILS_VALPLAT] ADD CONSTRAINT [FK_DOC_DETAILS_VALPLAT_REC_ID_IN_OPS] FOREIGN KEY ([DOC_REC_ID]) REFERENCES [dbo].[OPS_0000] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
