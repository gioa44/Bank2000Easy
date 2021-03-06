CREATE TABLE [dbo].[AUTHENTICATION_PARAMS]
(
[PASSWORD_ATTEMPT_WINDOW] [int] NOT NULL,
[MAX_INVALID_PASSWORD_ATTEMPTS] [int] NOT NULL,
[TEMP_LOCK_PERIOD] [int] NOT NULL,
[SESSION_TIMEOUT] [int] NOT NULL,
[USER_AUTO_LOCK_DAYS] [int] NOT NULL,
[PASSWORD_EXPIRE_DAYS] [int] NOT NULL,
[PASSWORD_HISTORY_LENGTH] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AUTHENTICATION_PARAMS] ADD CONSTRAINT [CK_AUTHENTICATION_PARAMS_MAX_INVALID_PASSWORD_ATTEMPTS] CHECK (([MAX_INVALID_PASSWORD_ATTEMPTS]>(0)))
GO
