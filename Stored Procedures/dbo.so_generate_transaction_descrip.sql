SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[so_generate_transaction_descrip]
	@task_id int, 
	@ccy1 TISO,
	@ccy2 TISO,
	@client_no int, 
	@schedule_date datetime, 
	@agreement_no varchar(50), 
	@descrip varchar(250) OUTPUT, 
	@descrip_lat varchar(250) OUTPUT
AS

--ტეგები:
--	<EQUN>		შეიცვლება @schedule_date -ისათვის არსებული ეროვნული კურსით
--	<EQUB>		შეიცვლება @schedule_date -ისათვის არსებული ბანკის კომერციული კურსით
--	<CLIENT>	შეიცვლება კლიენტის დასახელებით
--	<DATE>		შეიცვლება @schedule_date თარიღით
--	<AGRN>		შეიცვლება დავალების ხელშეკრულების №-ით


DECLARE
	@c_descrip varchar(100),
	@c_descrip_lat varchar(100),
	@cross_rate varchar(10),
	@is_reverse bit,
	@rate money,
	@rate_items int
	
SET @c_descrip = ''
SET @c_descrip_lat = ''
SET @ccy2 = ISNULL(@ccy2, @ccy1)
SET @descrip_lat = ISNULL(@descrip_lat, @descrip)
	
IF (@client_no IS NOT NULL AND (CHARINDEX('<CLIENT>', @descrip) > 0 OR CHARINDEX('<CLIENT>', @descrip_lat) > 0))
	SELECT @c_descrip = DESCRIP, @c_descrip_lat = DESCRIP_LAT 
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no

IF  CHARINDEX('<EQUN>', @descrip) > 0 OR CHARINDEX('<EQUN>', @descrip_lat) > 0
	SET @cross_rate = CONVERT(varchar(10), dbo.get_cross_rate(@ccy1, @ccy2, @schedule_date))

IF  CHARINDEX('<EQUB>', @descrip) > 0 OR CHARINDEX('<EQUB>', @descrip_lat) > 0
BEGIN
	IF (@ccy1 = @ccy2)
		SET @rate = 1
	ELSE
	BEGIN		
		EXEC dbo.GET_CROSS_RATE 
			@rate_politics_id = NULL, 
			@iso1 = @ccy1, 
			@iso2 = @ccy2,
			@look_buy = 0/*?*/, 
			@amount = @rate OUTPUT, 
			@items = @rate_items OUTPUT, 
			@reverse = @is_reverse OUTPUT, 
			@rate_type = 0
		  
		IF @is_reverse = 0
			SET @rate = @rate / @rate_items
		ELSE
			SET @rate = @rate_items / @rate		
	END
END

IF  CHARINDEX('<EQUN>', @descrip) > 0
	SET @descrip = REPLACE(@descrip, '<EQUN>', @cross_rate)
IF  CHARINDEX('<EQUB>', @descrip) > 0
	SET @descrip = REPLACE(@descrip, '<EQUB>', CAST(@rate AS varchar))
IF  CHARINDEX('<CLIENT>', @descrip) > 0
	SET @descrip = REPLACE(@descrip, '<CLIENT>', @c_descrip)
IF  CHARINDEX('<AGRN>', @descrip) > 0
	SET @descrip = REPLACE(@descrip, '<AGRN>', @agreement_no)
IF  CHARINDEX('<DATE>', @descrip) > 0
	SET @descrip = REPLACE(@descrip, '<DATE>', CONVERT(varchar(50), @schedule_date, 103))

IF  CHARINDEX('<EQUN>', @descrip_lat) > 0
	SET @descrip_lat = REPLACE(@descrip_lat, '<EQUN>', @cross_rate)
IF  CHARINDEX('<EQUB>', @descrip_lat) > 0
	SET @descrip_lat = REPLACE(@descrip_lat, '<EQUB>', CAST(@rate AS varchar))
IF  CHARINDEX('<CLIENT>', @descrip_lat) > 0
	SET @descrip_lat = REPLACE(@descrip_lat, '<CLIENT>', @c_descrip_lat)
IF  CHARINDEX('<AGRN>', @descrip_lat) > 0
	SET @descrip_lat = REPLACE(@descrip_lat, '<AGRN>', @agreement_no)
IF  CHARINDEX('<DATE>', @descrip_lat) > 0
	SET @descrip_lat = REPLACE(@descrip_lat, '<DATE>', CONVERT(varchar(50), @schedule_date, 103))	

RETURN 0
GO
