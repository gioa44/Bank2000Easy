SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[WBC_ACC_VIEW] AS
SELECT A.ACCOUNT, A.ISO,
   ISNULL(A.SALDO,$0.00) + ISNULL(A.SHADOW_DBO,$0.00) - ISNULL(A.SHADOW_CRO,$0.00) AS BALANCE,
   CONVERT(VARCHAR(50), CASE A.ACC_USAGE_TYPE WHEN 0 THEN NULL 
                        WHEN 1 THEN 'ÌÉÌÃÉÍÀÒÄ' WHEN 2 THEN 'ÁÀÒÀÈÉ' WHEN 3 THEN 'ÊÒÄÃÉÔÉ' WHEN 4 THEN 'ÅÀÃÉÀÍÉ ÀÍÀÁÀÒÉ' WHEN 5 THEN 'ÆÒÃÀÃÉ ÀÍÀÁÀÒÉ' 
                        WHEN 6 THEN 'ÛÄÌÍÀáÅÄËÉ' END + CASE WHEN A.ACC_USAGE_DESCRIP IS NULL THEN '' ELSE ' (' + A.ACC_USAGE_DESCRIP + ')' END) AS ACC_DESCRIP,
   CONVERT(VARCHAR(50), CASE A.ACC_USAGE_TYPE WHEN 0 THEN NULL 
                        WHEN 1 THEN 'Current acc.' WHEN 2 THEN 'Plastic card' WHEN 3 THEN 'Loan' WHEN 4 THEN 'Term Deposit' WHEN 5 THEN 'Increasing Deposit' 
                        WHEN 6 THEN 'Savings acc.' END + CASE WHEN A.ACC_USAGE_DESCRIP IS NULL THEN '' ELSE ' (' + A.ACC_USAGE_DESCRIP + ')' END) AS ACC_DESCRIP_LAT,
   CONVERT (VARCHAR(20),
         CASE A.REC_STATE WHEN 2 THEN ' (ÃÀáÖÒÖËÉ)' WHEN 4 THEN ' (ÌáÏËÏÃ ÊÒÄÃ.)' WHEN 8 THEN ' (ÌáÏËÏÃ ÁÉÖã.)' WHEN 16 THEN ' (ÂÀÚÉÍÖËÉ)' WHEN 32 THEN ' (ÊÏÍÔÒÏËÉ)' WHEN 64 THEN ' (ÒÄÆÄÒÅÉ)' WHEN 128 THEN ' (ÂÀÖØÌÄÁÖËÉ)' ELSE '' END) AS STATUS,
   CONVERT (VARCHAR(20),
         CASE A.REC_STATE WHEN 2 THEN ' (closed)' WHEN 4 THEN ' (only cred.)' WHEN 8 THEN ' (only budj.)' WHEN 16 THEN ' (frozen)' WHEN 32 THEN ' (control)' WHEN 64 THEN ' (reserve)' WHEN 128 THEN ' (deleted)' ELSE '' END) AS STATUS_LAT
FROM dbo.ACC_VIEW A


GO
