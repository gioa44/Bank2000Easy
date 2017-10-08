SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  PROCEDURE [dbo].[PREFIX_ADD_DOC]
  @bank_code TINTACCOUNT,
  @bank_name varchar(50),
  @sender_acc TINTACCOUNT,
  @sender_name TINTACCOUNT,
  @receiver_acc TINTACCOUNT,
  @receiver_name TINTACCOUNT,
  @prefix varchar(6),
  @prefix_type varchar(10)

AS

INSERT INTO OUR_PREFIX(BANK_CODE, BANK_NAME, SENDER_ACC, SENDER_NAME, RECEIVER_ACC, RECEIVER_NAME, PREFIX, PREFIX_TYPE) VALUES (  @bank_code, @bank_name,
  @sender_acc, @sender_name, @receiver_acc, @receiver_name, @prefix, @prefix_type)

IF @@ERROR <> 0 RETURN (1)

RETURN (0)

GO
