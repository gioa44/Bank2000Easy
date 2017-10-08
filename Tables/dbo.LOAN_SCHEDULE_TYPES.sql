CREATE TABLE [dbo].[LOAN_SCHEDULE_TYPES]
(
[SCHEDULE_ID] [int] NOT NULL,
[DESCRIP] [dbo].[TDESCRIP] NOT NULL,
[DESCRIP_LAT] [dbo].[TDESCRIP] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_SCHEDULE_TYPES] ADD CONSTRAINT [PK_LOAN_SCHEDULE_TYPES] PRIMARY KEY CLUSTERED  ([SCHEDULE_ID]) ON [PRIMARY]
GO
