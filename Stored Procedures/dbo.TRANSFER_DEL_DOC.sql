SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[TRANSFER_DEL_DOC]
  @source_date datetime,
  @doc_date datetime,
  @iso TISO,
  @amount TAMOUNT,
  @doc_num int,
  @descrip_in varchar(150),
  @transfer_type varchar (20)

AS

DELETE FROM TRANSFER_DOCS
WHERE  @source_date = SOURCE_DATE AND @doc_date = DOC_DATE AND @amount=AMOUNT AND @iso=ISO AND @doc_num=DOC_NUM AND
               @descrip_in = DESCRIP_IN AND @transfer_type = TRANSFER_TYPE

IF @@ERROR <> 0 RETURN (1)

RETURN (0)

GO
