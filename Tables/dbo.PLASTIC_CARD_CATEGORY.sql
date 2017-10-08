CREATE TABLE [dbo].[PLASTIC_CARD_CATEGORY]
(
[CARD_CATEGORY] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[REC_STATE] [bit] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_CATEGORY_REC_STATE] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PLASTIC_CARD_CATEGORY] ADD CONSTRAINT [PK_PLASTIC_CARD_CARD_CATEGORY] PRIMARY KEY CLUSTERED  ([CARD_CATEGORY]) ON [PRIMARY]
GO