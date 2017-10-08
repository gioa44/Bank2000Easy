CREATE TABLE [impexp].[DOCS_OUT_NBG_ARC]
(
[DOC_REC_ID] [int] NOT NULL,
[UID] [int] NOT NULL,
[DOC_DATE] [smalldatetime] NOT NULL,
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[OLD_FLAGS] [int] NOT NULL,
[NDOC] [char] (4) COLLATE Latin1_General_BIN NULL,
[DATE] [smalldatetime] NOT NULL,
[NFA] [int] NOT NULL,
[NLS] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
[SUM] [money] NOT NULL,
[NFB] [int] NOT NULL,
[NLSK] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[GIK] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[NLS_AX] [varchar] (34) COLLATE Latin1_General_BIN NOT NULL,
[MIK] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[NLSK_AX] [varchar] (34) COLLATE Latin1_General_BIN NOT NULL,
[BANK_A] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[BANK_B] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[GB] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[G_O] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[MB] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[M_O] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[GD] [varchar] (200) COLLATE Latin1_General_BIN NOT NULL,
[REC_DATE] [smalldatetime] NOT NULL,
[SAXAZKOD] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[DAMINF] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[ROW_ID] [int] NULL,
[OP_CODE] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[THP_NAME] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [ARCHIVE]
GO
ALTER TABLE [impexp].[DOCS_OUT_NBG_ARC] ADD CONSTRAINT [PK_DOCS_OUT_NBG_ARC] PRIMARY KEY CLUSTERED  ([DOC_REC_ID]) ON [ARCHIVE]
GO
ALTER TABLE [impexp].[DOCS_OUT_NBG_ARC] ADD CONSTRAINT [FK_DOCS_OUT_NBG_ARC_PORTIONS_OUT_NBG_ARC] FOREIGN KEY ([PORTION_DATE], [PORTION]) REFERENCES [impexp].[PORTIONS_OUT_NBG_ARC] ([PORTION_DATE], [PORTION])
GO
