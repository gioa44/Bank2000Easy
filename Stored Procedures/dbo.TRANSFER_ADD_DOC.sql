SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[TRANSFER_ADD_DOC]
  @source_date smalldatetime,
  @doc_date datetime,
  @cash_date datetime =NULL,
  @amount TAMOUNT,
  @iso TISO,
  @doc_num int,
  @descrip_in varchar (150),
  @descrip_out varchar (150),
  @transfer_type varchar (20)

AS

INSERT INTO TRANSFER_DOCS VALUES (  @source_date, @doc_date, @cash_date, @amount, @iso,
  @doc_num, @descrip_in, @descrip_out, @transfer_type)

IF @@ERROR <> 0 RETURN (1)

RETURN (0)

GO
