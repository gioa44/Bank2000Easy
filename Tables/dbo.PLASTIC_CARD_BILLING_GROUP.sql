CREATE TABLE [dbo].[PLASTIC_CARD_BILLING_GROUP]
(
[BILLING_GROUP] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[REC_STATE] [bit] NOT NULL CONSTRAINT [DF_PLASTIC_CARD_BILLING_GROUP_REC_STATE] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PLASTIC_CARD_BILLING_GROUP] ADD CONSTRAINT [PK_PLASTIC_CARD_BILLING_GROUP] PRIMARY KEY CLUSTERED  ([BILLING_GROUP]) ON [PRIMARY]
GO
