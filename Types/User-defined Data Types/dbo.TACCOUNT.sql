CREATE TYPE [dbo].[TACCOUNT] FROM decimal (15, 0) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[TACCOUNT] TO [public]
GO