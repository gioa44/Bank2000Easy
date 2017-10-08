CREATE TABLE [dbo].[TCD_CASETTE_OPS]
(
[OP_ID] [int] NOT NULL IDENTITY(1, 1),
[COLLECTION_ID] [int] NOT NULL,
[OP_TYPE] [int] NOT NULL,
[OP_DATE] [smalldatetime] NOT NULL,
[COLLECTOR_ID] [int] NULL,
[OWNER] [int] NOT NULL,
[AUTH_DATE] [smalldatetime] NULL,
[AUTH_OWNER] [int] NULL,
[STATE] [tinyint] NOT NULL CONSTRAINT [DF_TCD_CASETTE_OPS_STATE] DEFAULT ((0)),
[OP_NOTE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DOC_REC_ID] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_TCD_CASETTE_OPS_DELETE] ON [dbo].[TCD_CASETTE_OPS]
AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@op_id int,
		@casette_serial_id int,
		@op_type int,
		@ccy varchar(3),
		@tcd_serial_id varchar(50),
		@casette_den int,
		@count int,
		@collector_id int,
		@collection_id int

	SELECT @op_id=OP_ID, @op_type=OP_TYPE, @collection_id=COLLECTION_ID, @collector_id=COLLECTOR_ID
	FROM deleted
	
	DECLARE cc CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT CASETTE_SERIAL_ID, CASETTE_CCY, CASETTE_DEN, [COUNT]
		FROM dbo.TCD_CASETTE_OP_DETAILS
		WHERE OP_ID = @op_id

	OPEN cc
	FETCH NEXT FROM cc INTO @casette_serial_id, @ccy, @casette_den, @count

	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @op_type = 2 -- გაგზავნა
		BEGIN
			UPDATE dbo.TCD_CASETTES
			SET STATE = 0, PENDING = 0, CURRENT_TCD_SERIAL_ID = null, COLLECTOR_ID = null
			WHERE CASETTE_SERIAL_ID = @casette_serial_id
		END
		ELSE
		IF @op_type = 3 -- ამოღება
		BEGIN		
			UPDATE dbo.TCD_CASETTES
			SET STATE = 40, PENDING = 0
			WHERE CASETTE_SERIAL_ID = @casette_serial_id
		END
		ELSE
		IF @op_type = 4 -- ჩადება
		BEGIN
			UPDATE dbo.TCD_CASETTES
			SET STATE = 20, PENDING = 0
			WHERE CASETTE_SERIAL_ID = @casette_serial_id
		END
		ELSE
		IF @op_type = 5 -- სალაროში დაბრუნება
		BEGIN
			UPDATE dbo.TCD_CASETTES
			SET STATE = 30, PENDING = 0
			WHERE CASETTE_SERIAL_ID = @casette_serial_id
		END

		FETCH NEXT FROM cc INTO @casette_serial_id, @ccy, @casette_den, @count
	END
	CLOSE cc
	DEALLOCATE cc

	DELETE FROM dbo.TCD_CASETTE_OP_DETAILS
	WHERE OP_ID = @op_id
END
GO
ALTER TABLE [dbo].[TCD_CASETTE_OPS] ADD CONSTRAINT [PK_TCD_CASETTE_OPS] PRIMARY KEY CLUSTERED  ([OP_ID]) ON [PRIMARY]
GO
