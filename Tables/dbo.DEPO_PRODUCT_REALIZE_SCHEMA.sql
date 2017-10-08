CREATE TABLE [dbo].[DEPO_PRODUCT_REALIZE_SCHEMA]
(
[SCHEMA_ID] [int] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[REALIZE_TYPE] [tinyint] NOT NULL,
[REALIZE_COUNT] [smallint] NULL,
[REALIZE_COUNT_TYPE] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_PRODUCT_REALIZE_SCHEMA] ADD CONSTRAINT [PK_DEPO_PRODUCT_REALIZE_SCHEMA] PRIMARY KEY CLUSTERED  ([SCHEMA_ID]) ON [PRIMARY]
GO