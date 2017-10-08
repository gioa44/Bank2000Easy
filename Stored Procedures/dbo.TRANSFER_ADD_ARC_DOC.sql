SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[TRANSFER_ADD_ARC_DOC]
  @source_date datetime,
  @doc_date datetime,
  @cash_date datetime,
  @amount TAMOUNT,
  @iso TISO,
  @doc_num int,
  @descrip_in varchar (150),
  @descrip_out varchar (150),
  @transfer_type varchar (20)

AS

INSERT INTO TRANSFER_ARC_DOCS VALUES (  @source_date, @doc_date, @cash_date, @amount, @iso,
  @doc_num, @descrip_in, @descrip_out, @transfer_type);

IF @@ERROR <> 0 RETURN (1)

DELETE FROM TRANSFER_DOCS
WHERE  @source_date = SOURCE_DATE AND @doc_date = DOC_DATE AND @amount=AMOUNT AND @iso=ISO AND @doc_num=DOC_NUM AND
               @descrip_in = DESCRIP_IN AND @transfer_type = TRANSFER_TYPE

IF @@ERROR <> 0 RETURN (2)

RETURN (0)

GO
