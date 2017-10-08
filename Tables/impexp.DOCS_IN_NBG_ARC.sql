CREATE TABLE [impexp].[DOCS_IN_NBG_ARC]
(
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[ROW_ID] [int] NOT NULL,
[UID] [int] NOT NULL,
[NDOC] [int] NULL,
[DATE] [smalldatetime] NOT NULL,
[NFA] [int] NOT NULL,
[NLS] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
[SUM] [money] NOT NULL,
[NFB] [int] NOT NULL,
[NLSK] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
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
[STATE] [int] NOT NULL,
[IS_READY] [bit] NOT NULL,
[ACCOUNT] [dbo].[TACCOUNT] NULL,
[ACC_ID] [int] NULL,
[OTHER_INFO] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[ERROR_REASON] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[DOC_DATE] [smalldatetime] NULL,
[DOC_REC_ID] [int] NULL,
[IS_AUTHORIZED] [bit] NULL,
[IS_MODIFIED] [bit] NULL,
[FINALYZE_DOC_REC_ID] [int] NULL
) ON [ARCHIVE]
GO
ALTER TABLE [impexp].[DOCS_IN_NBG_ARC] ADD CONSTRAINT [PK_DOCS_IN_NBG_ARC] PRIMARY KEY CLUSTERED  ([PORTION_DATE], [PORTION], [ROW_ID]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_DOCS_IN_NBG_ARC_DOC_REC_ID] ON [impexp].[DOCS_IN_NBG_ARC] ([DOC_REC_ID]) ON [ARCHIVE]
GO
ALTER TABLE [impexp].[DOCS_IN_NBG_ARC] ADD CONSTRAINT [FK_DOCS_IN_NBG_ARC_PORTIONS_IN_NBG_ARC] FOREIGN KEY ([PORTION_DATE], [PORTION]) REFERENCES [impexp].[PORTIONS_IN_NBG_ARC] ([PORTION_DATE], [PORTION])
GO