CREATE TABLE [dbo].[DOC_DETAILS_PLAT]
(
[DOC_REC_ID] [int] NOT NULL,
[SENDER_BANK_CODE] [dbo].[TGEOBANKCODE] NOT NULL,
[SENDER_ACC] [dbo].[TINTACCOUNT] NOT NULL,
[SENDER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[RECEIVER_BANK_CODE] [dbo].[TGEOBANKCODE] NOT NULL,
[RECEIVER_ACC] [dbo].[TINTACCOUNT] NOT NULL,
[RECEIVER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[SENDER_BANK_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RECEIVER_BANK_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[SENDER_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[RECEIVER_ACC_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[POR] [smallint] NULL,
[REC_DATE] [smalldatetime] NULL,
[SAXAZKOD] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[EXTRA_INFO] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[REF_NUM] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[TAX_PAYER_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[TAX_PAYER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_PLAT_DETAIL_INSERT_UPDATE] ON [dbo].[DOC_DETAILS_PLAT]
FOR INSERT,UPDATE
AS

IF @@ROWCOUNT > 1 OR dbo.bank_server_state() <> 0
	RETURN

SET NOCOUNT ON

DECLARE
  @bank_code TGEOBANKCODE,
  @tax_code varchar(11),
  @account TINTACCOUNT,
  @descrip varchar(100),
  @doc_rec_id int

SELECT @doc_rec_id = DOC_REC_ID, @bank_code = SENDER_BANK_CODE, @account = SENDER_ACC, @descrip = SENDER_ACC_NAME, @tax_code = SENDER_TAX_CODE
FROM inserted

IF @bank_code <> 220101222
BEGIN
	SET @descrip = RTRIM(LTRIM(@descrip))
	IF @descrip IS NULL OR @descrip = '' RETURN

	IF dbo.bank_is_geo_bank_in_our_db (@bank_code) = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.OTHER_ACCOUNTS (NOLOCK) WHERE BANK_CODE = CONVERT(VARCHAR(30),@bank_code) AND ACCOUNT = @account)
		INSERT INTO dbo.OTHER_ACCOUNTS 
		VALUES (@bank_code, @account, @descrip, @tax_code, 1)
	END
END

SELECT @doc_rec_id = DOC_REC_ID, @bank_code = RECEIVER_BANK_CODE, @account = RECEIVER_ACC, @descrip = RECEIVER_ACC_NAME, @tax_code = RECEIVER_TAX_CODE
FROM inserted

IF @bank_code <> 220101222
BEGIN
	DECLARE @doc_type smallint

	SELECT @doc_type = DOC_TYPE 
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @doc_rec_id

	IF (NOT @doc_type IN (103,104,106)) -- charicxva fil, charicxva, transit
		AND dbo.bank_is_geo_bank_in_our_db (@bank_code) = 0
	BEGIN
	  IF NOT EXISTS(SELECT * FROM dbo.OTHER_ACCOUNTS WHERE BANK_CODE = CONVERT(VARCHAR(30),@bank_code) AND ACCOUNT = @account)
		INSERT INTO dbo.OTHER_ACCOUNTS 
		VALUES(@bank_code, @account, @descrip, @tax_code, 1)
	END
END
GO
ALTER TABLE [dbo].[DOC_DETAILS_PLAT] ADD CONSTRAINT [PK_DOC_DETAILS_PLAT] PRIMARY KEY CLUSTERED  ([DOC_REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_DETAILS_PLAT] ADD CONSTRAINT [FK_DOC_DETAILS_PLAT_REC_ID_IN_OPS] FOREIGN KEY ([DOC_REC_ID]) REFERENCES [dbo].[OPS_0000] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
