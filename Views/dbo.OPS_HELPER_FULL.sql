SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[OPS_HELPER_FULL] ASSELECT * FROM dbo.OPS_HELPER_0000  UNION ALLSELECT * FROM dbo.OPS_HELPER_2009 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2010 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2011 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2012 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2013 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2014 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2015 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2016 (NOLOCK)  UNION ALLSELECT * FROM dbo.OPS_HELPER_2017 (NOLOCK)
GO
