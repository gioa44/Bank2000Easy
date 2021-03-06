CREATE TABLE [dbo].[GROUP_CONV_LIMITS]
(
[GROUP_ID] [int] NOT NULL,
[CONV_RATE_PERC] [money] NOT NULL CONSTRAINT [DF_GROUP_CONV_LIMITS_CONV_RATE_PERC] DEFAULT ((0.0000)),
[CONV_RATE_PERC_KAS] [money] NOT NULL CONSTRAINT [DF_GROUP_CONV_LIMITS_CONV_RATE_PERC_KAS] DEFAULT ((0.0000))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[GROUP_CONV_LIMITS] ADD CONSTRAINT [PK_GROUP_CONV_LIMITS] PRIMARY KEY CLUSTERED  ([GROUP_ID]) ON [PRIMARY]
GO
