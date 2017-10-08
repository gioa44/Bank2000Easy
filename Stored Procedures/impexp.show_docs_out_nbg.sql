SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[show_docs_out_nbg] 
	@date smalldatetime, 
	@portion int, 
	@set_row_id bit = 0
AS

DECLARE @today6 char(6)
SET @today6 = impexp.date_to_char6(@date)

DECLARE @tbl TABLE (
	VOBR char(1) NOT NULL,
	PDK char(1) NOT NULL,
	Z_R char(1) NOT NULL,
	NDOC_SV char(4),
	DATE_SV char(6),
	SUM_SV money,
	NDOC char(4),
	DATE char(6),
	NFA char(9),
	NLS char(9),
	[SUM] money,
	NFB char(9),
	NLSK char(9),
	VOP char(2),
	GIK char(11),
	NLS_AX char(34),
	MIK char(11),
	NLSK_AX char(34),
	BANK_A char(3),
	BANK_B char(3),
	GB char(50),
	G_O char(60),
	MB char(50),
	M_O char(60),
	GD char(190),
	ZXZ3 char(64),
	REC_DATE char(6),
	B_DATE char(6),
	SAXAZKOD char(9),
	DAMINF char(250),
	THP_NAME varchar(60),
	DOC_REC_ID int NOT NULL,
	ROW_ID int NULL,
	PRIMARY KEY (BANK_B, VOP DESC, DOC_REC_ID DESC)
)

INSERT INTO @tbl
SELECT 
	'2' AS VOBR, 
	'1' AS PDK , 
	' ' AS Z_R,
	NULL AS NDOC_SV, 
	@today6 AS DATE_SV, 
	$0.00 AS SUM_SV,
	NDOC, 
	impexp.date_to_char6(DATE) AS [DATE],
	NFA, 
	NLS, 
	[SUM], 
	NFB, 
	NLSK,
	'02' AS VOP,
	GIK, 
	NLS_AX, 
	MIK, 
	NLSK_AX,
	BANK_A, 
	BANK_B,
	SUBSTRING(GB, 1, 50),
	SUBSTRING(G_O, 1, 60),
	SUBSTRING(MB, 1, 50),
	SUBSTRING(M_O, 1, 60),
	SUBSTRING(GD, 1, 190),
	NULL AS ZXZ3,
	impexp.date_to_char6(REC_DATE) AS REC_DATE, 
	@today6 AS B_DATE, 
	SAXAZKOD,
	DAMINF,
	SUBSTRING(CASE WHEN ISNULL(THP_NAME,'') = '' AND NFB = 220101222 THEN G_O ELSE THP_NAME END, 1, 60),
	DOC_REC_ID,
	NULL
FROM impexp.DOCS_OUT_NBG
WHERE PORTION_DATE = @date AND PORTION = @portion

INSERT INTO @tbl (VOBR, PDK, Z_R, NDOC_SV, DATE_SV,	SUM_SV,	[SUM], NDOC, DATE, VOP, BANK_A, BANK_B, DOC_REC_ID)
SELECT '2', '1', ' ', ROW_NUMBER() OVER (ORDER BY BANK_B), @today6, SUM([SUM]), SUM([SUM]), @portion, @today6, '99', BANK_A, BANK_B, 0
FROM @tbl
GROUP BY BANK_A, BANK_B

UPDATE @tbl
SET NDOC_SV = REPLICATE('0', 4 - LEN(NDOC_SV)) + NDOC_SV, NDOC = REPLICATE('0', 4 - LEN(NDOC)) + NDOC
FROM @tbl A

UPDATE @tbl
SET NDOC_SV = (SELECT NDOC_SV FROM @tbl B WHERE B.BANK_B = A.BANK_B AND B.VOP = '99'),
	SUM_SV = (SELECT SUM_SV FROM @tbl B WHERE B.BANK_B = A.BANK_B AND B.VOP = '99')
FROM @tbl A
WHERE A.VOP <> '99'

DECLARE @row_id int
SET @row_id = 0

UPDATE @tbl
SET @row_id = ROW_ID = @row_id + 1

UPDATE A
SET A.ROW_ID = B.ROW_ID
FROM impexp.DOCS_OUT_NBG A
	INNER JOIN @tbl B ON A.DOC_REC_ID = B.DOC_REC_ID

SELECT * 
FROM @tbl
ORDER BY BANK_B, VOP DESC
GO
