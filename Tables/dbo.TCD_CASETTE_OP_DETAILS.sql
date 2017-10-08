CREATE TABLE [dbo].[TCD_CASETTE_OP_DETAILS]
(
[OP_ID] [int] NOT NULL,
[CASETTE_SERIAL_ID] [int] NOT NULL,
[CASETTE_POSITION] [int] NULL,
[CASETTE_CCY] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CASETTE_DEN] [tinyint] NULL,
[COUNT] [int] NULL,
[TOTAL_AMOUNT] AS ([COUNT]*[CASETTE_DEN]),
[IS_REJECT] [bit] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_TCD_CASETTE_OP_DETAILS_INSERT] ON [dbo].[TCD_CASETTE_OP_DETAILS]
AFTER INSERT
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

	SELECT @op_id = OP_ID, @casette_serial_id = CASETTE_SERIAL_ID, @ccy = CASETTE_CCY, @casette_den = CASETTE_DEN, @count = [COUNT]
	FROM inserted
	
	SELECT @op_type = OP_TYPE, @collector_id = COLLECTOR_ID, @collection_id = COLLECTION_ID
	FROM dbo.TCD_CASETTE_OPS 
	WHERE OP_ID = @op_id

	SELECT @tcd_serial_id = TCD_SERIAL_ID
	FROM dbo.TCD_CASETTE_COLLECTIONS
	WHERE COLLECTION_ID = @collection_id

	IF @op_type = 1 --  ჩადება
	BEGIN
		UPDATE dbo.TCD_CASETTES
		SET [STATE] = 10, PENDING = 1, CURRENT_TCD_SERIAL_ID = null, COLLECTOR_ID = null, CURRENT_CCY = @ccy, CURRENT_DEN = @casette_den, CURRENT_COUNT = @count
		WHERE CASETTE_SERIAL_ID = @casette_serial_id
	END
	ELSE
	IF @op_type = 2 -- გაგზავნა
	BEGIN
		UPDATE dbo.TCD_CASETTES
		SET STATE = 20, PENDING = 1, CURRENT_TCD_SERIAL_ID = @tcd_serial_id, COLLECTOR_ID = @collector_id
		WHERE CASETTE_SERIAL_ID = @casette_serial_id
	END
	ELSE
	IF @op_type = 3 -- ამოღება
	BEGIN		
		UPDATE dbo.TCD_CASETTES
		SET STATE = 30, PENDING = 1, CURRENT_TCD_SERIAL_ID = null, COLLECTOR_ID = @collector_id, CURRENT_COUNT = @count
		WHERE CASETTE_SERIAL_ID = @casette_serial_id
	END
	ELSE
	IF @op_type = 4 -- ჩადება
	BEGIN
		UPDATE dbo.TCD_CASETTES
		SET STATE = 40, PENDING = 1
		WHERE CASETTE_SERIAL_ID = @casette_serial_id
	END
	ELSE
	IF @op_type = 5 -- სალაროში დაბრუნება
	BEGIN
		UPDATE dbo.TCD_CASETTES
		SET STATE = 0, PENDING = 1, CURRENT_TCD_SERIAL_ID = null, COLLECTOR_ID = null, CURRENT_CCY = null, CURRENT_DEN = null, CURRENT_COUNT = null
		WHERE CASETTE_SERIAL_ID = @casette_serial_id
	END
END
GO
CREATE NONCLUSTERED INDEX [IX_TCD_CASETTE_OP_DETAILS] ON [dbo].[TCD_CASETTE_OP_DETAILS] ([OP_ID]) ON [PRIMARY]
GO
