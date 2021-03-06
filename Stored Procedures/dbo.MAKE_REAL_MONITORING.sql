SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MAKE_REAL_MONITORING] AS

DECLARE @id  int
DECLARE @acc TACCOUNT
DECLARE @iso TISO
DECLARE CURS CURSOR LOCAL FOR 
SELECT LA.PRP_ID, LA.PRINC_ACC AS ACC, LP.ISO  
FROM  LOAN_ACCS LA, LOAN_PROPS LP
WHERE (LA.DT = (SELECT MAX(AC.DT) FROM LOAN_ACCS AC WHERE (AC.PRP_ID=LA.PRP_ID))) AND
(LP.PRP_ID = LA.PRP_ID) AND (LP.PRP_STATE = 3)
FOR READ ONLY
OPEN CURS
FETCH NEXT FROM CURS INTO @id, @acc, @iso
WHILE @@FETCH_STATUS = 0
BEGIN
  INSERT INTO LOAN_REAL_MONITORING(PRP_NO, DT, PRINCIPAL_AMOUNT, LOAN_AMOUNT, ISO, ISDEFAULT)
  SELECT @id, DA.DOC_DATE,
  CASE WHEN (DA.CREDIT=@acc) THEN DA.AMOUNT ELSE NULL END,
  CASE WHEN (DA.DEBIT=@acc) THEN DA.AMOUNT ELSE NULL END, @iso, 0
  FROM DOCS_ARC DA WHERE ((DA.DEBIT=@acc) OR (DA.CREDIT=@acc)) AND (DA.ISO=@iso)
  FETCH NEXT FROM CURS INTO @id, @acc, @iso
END
  UPDATE LOAN_PRP_PRPER 
  SET LOAN_STATE = 10
  WHERE EXISTS (SELECT * FROM LOAN_REAL_MONITORING LRM WHERE LRM.PRP_NO = PRP_ID) 
CLOSE CURS
DEALLOCATE CURS


GO
