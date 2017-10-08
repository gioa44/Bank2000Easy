CREATE TABLE [dbo].[LOAN_ATTRIB_CODES]
(
[CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [dbo].[TDESCRIP] NOT NULL,
[DESCRIP_LAT] [dbo].[TDESCRIP] NULL,
[IS_COMMON] [bit] NOT NULL CONSTRAINT [DF_LOAN_ATTRIB_CODES_IS_COMMON] DEFAULT ((0)),
[IS_REQUIRED] [tinyint] NOT NULL CONSTRAINT [DF_LOAN_ATTRIB_CODES_IS_REQUIRED] DEFAULT ((0)),
[ONLY_ONE_VALUE] [bit] NOT NULL CONSTRAINT [DF_LOAN_ATTRIB_CODES_ONLY_ONE_VALUE] DEFAULT ((0)),
[TYPE] [tinyint] NOT NULL CONSTRAINT [DF_LOAN_ATTRIB_CODES_TYPE] DEFAULT ((0)),
[VALUES] [varchar] (4000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_ATTRIB_CODES] ADD CONSTRAINT [PK_LOAN_ATTRIB_CODES] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
