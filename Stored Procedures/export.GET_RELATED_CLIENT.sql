SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [export].[GET_RELATED_CLIENT]
  @client_id int,
  @rel_type tinyint
AS

	IF @rel_type = 0 --Principal Manager
	BEGIN
		SELECT
			rel.REL_CLIENT_NO AS REL_CLIENT_ID,
			cl2.CLIENT_TYPE AS REL_CLIENT_TYPE,
			cl1.TAX_INSP_CODE,
			export.get_client_code(rel.REL_CLIENT_NO) AS UNIQUE_P_NUMBER,
			34 AS JOB_TITLE_CODE
		FROM dbo.CLIENT_RELATIONS rel
		INNER JOIN dbo.CLIENTS cl1 ON rel.CLIENT_NO = cl1.CLIENT_NO
		INNER JOIN dbo.CLIENTS cl2 ON rel.REL_CLIENT_NO = cl2.CLIENT_NO
		WHERE rel.CLIENT_NO = @client_id AND rel.CLIENT_RELATION_TYPE_ID = 10 -- ÀÒÀÒÓÄÁÖËÉ ÌÍÉÛÅÍÄËÏÁÀ, ÁÀÍÊÛÉ ÉØÍÄÁÀ ÛÄÓÀÓßÏÒÄÁÄËÉ
	END
	ELSE 
	IF @rel_type = 1 --Board Member
	BEGIN
		SELECT
			rel.REL_CLIENT_NO AS REL_CLIENT_ID,
			cl2.CLIENT_TYPE AS REL_CLIENT_TYPE,
			cl1.TAX_INSP_CODE,
			export.get_client_code(rel.REL_CLIENT_NO) AS UNIQUE_P_NUMBER,
			1 AS BOARD_RESP_CODE
		FROM dbo.CLIENT_RELATIONS rel
		INNER JOIN dbo.CLIENTS cl1 ON rel.CLIENT_NO = cl1.CLIENT_NO
		INNER JOIN dbo.CLIENTS cl2 ON rel.REL_CLIENT_NO = cl2.CLIENT_NO
		WHERE rel.CLIENT_NO = @client_id AND rel.CLIENT_RELATION_TYPE_ID = 11 -- ÀÒÀÒÓÄÁÖËÉ ÌÍÉÛÅÍÄËÏÁÀ, ÁÀÍÊÛÉ ÉØÍÄÁÀ ÛÄÓÀÓßÏÒÄÁÄËÉ
	END
	ELSE
	IF @rel_type = 2 -- Principal Shareholder
	BEGIN
		SELECT
			rel.REL_CLIENT_NO AS REL_CLIENT_ID,
			cl2.CLIENT_TYPE AS REL_CLIENT_TYPE,
			cl1.TAX_INSP_CODE,
			export.get_client_code(rel.REL_CLIENT_NO) AS UNIQUE_P_NUMBER,
			1 AS OWNERSHIP_DESC_ID, --ასეთი რამე დასამატებელია (წესით როცა კავშირი არის თანამშრომელი იმის დიტეილი იქნება ეს სია რომელიც ექსელის ფაილში მაქვს)
			-1 AS OWNERSHIP_AS_PERCENT
		FROM dbo.CLIENT_RELATIONS rel
		INNER JOIN dbo.CLIENTS cl1 ON rel.CLIENT_NO = cl1.CLIENT_NO
		INNER JOIN dbo.CLIENTS cl2 ON rel.REL_CLIENT_NO = cl2.CLIENT_NO
		WHERE rel.CLIENT_NO = @client_id AND rel.CLIENT_RELATION_TYPE_ID = 12 -- ÀÒÀÒÓÄÁÖËÉ ÌÍÉÛÅÍÄËÏÁÀ, ÁÀÍÊÛÉ ÉØÍÄÁÀ ÛÄÓÀÓßÏÒÄÁÄËÉ
	END
GO
