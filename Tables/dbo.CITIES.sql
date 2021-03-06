CREATE TABLE [dbo].[CITIES]
(
[COUNTRY] [char] (2) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_CITIES_COUNTRY] DEFAULT ('GE'),
[CITY] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[CITY_LAT] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CITIES] ADD CONSTRAINT [PK_CITIES] PRIMARY KEY CLUSTERED  ([COUNTRY], [CITY]) ON [PRIMARY]
GO
