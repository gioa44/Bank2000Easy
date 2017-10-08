SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  PROCEDURE [dbo].[PREFIX_UPD_DOC]
  @pr_id integer,
  @bank_code TINTACCOUNT,
  @bank_name varchar(50),
  @sender_acc TINTACCOUNT,
  @sender_name TINTACCOUNT,
  @receiver_acc TINTACCOUNT,
  @receiver_name TINTACCOUNT,
  @prefix varchar(6),
  @prefix_type varchar(10)

AS

UPDATE OUR_PREFIX
SET
      BANK_CODE = @bank_code,
      BANK_NAME = @bank_name,
      SENDER_ACC = @sender_acc,
      SENDER_NAME = @sender_name, 
      RECEIVER_ACC = @receiver_acc,
      RECEIVER_NAME = @receiver_name, 
      PREFIX = @prefix,
      PREFIX_TYPE = @prefix_type
WHERE PR_ID = @pr_id;

IF @@ERROR <> 0 RETURN (1)

RETURN (0)

GO
