SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[psp_help_allidx7]
as
/* Purpose: to list all indexes for each table
   Author : Eddy Djaja, Publix Super Markets, Inc.
   Revision: 12/07/1999 born date
*/
    
-- SET UP SOME CONSTANT VALUES FOR OUTPUT QUERY
declare @empty varchar(1) 
select @empty = ''
declare @des1		varchar(35),	-- 35 matches spt_values
	@des2		varchar(35),
	@des4		varchar(35),
	@des32		varchar(35),
	@des64		varchar(35),
	@des2048	varchar(35),
	@des4096	varchar(35),
	@des8388608	varchar(35),
	@des16777216	varchar(35)
select @des1 = name from master.dbo.spt_values where type = 'I' and number = 1
select @des2 = name from master.dbo.spt_values where type = 'I' and number = 2
select @des4 = name from master.dbo.spt_values where type = 'I' and number = 4
select @des32 = name from master.dbo.spt_values where type = 'I' and number = 32
select @des64 = name from master.dbo.spt_values where type = 'I' and number = 64
select @des2048 = name from master.dbo.spt_values where type = 'I' and number = 2048
select @des4096 = name from master.dbo.spt_values where type = 'I' and number = 4096
select @des8388608 = name from master.dbo.spt_values where type = 'I' and number = 8388608
select @des16777216 = name from master.dbo.spt_values where type = 'I' and number = 16777216

select 	o.name, 
	i.name,
	'index description' = convert(varchar(210), --bits 16 off, 1, 2, 16777216 on, located on group
				case when (i.status & 16)<>0 then 'clustered' else 'nonclustered' end 
				+ case when (i.status & 1)<>0 then ', '+@des1 else @empty end
				+ case when (i.status & 2)<>0 then ', '+@des2 else @empty end
				+ case when (i.status & 4)<>0 then ', '+@des4 else @empty end
				+ case when (i.status & 64)<>0 then ', '+@des64 else 
						case when (i.status & 32)<>0 then ', '+@des32 else @empty end end
				+ case when (i.status & 2048)<>0 then ', '+@des2048 else @empty end
				+ case when (i.status & 4096)<>0 then ', '+@des4096 else @empty end
				+ case when (i.status & 8388608)<>0 then ', '+@des8388608 else @empty end
				+ case when (i.status & 16777216)<>0 then ', '+@des16777216 else @empty end),
	'index column 1' = index_col(o.name,indid, 1),
	'index column 2' = index_col(o.name,indid, 2),
	'index column 3' = index_col(o.name,indid, 3)
from sysindexes i, sysobjects o
where i.id = o.id 
		and indid > 0 
		and indid < 255
		and o.type = 'U'
		--exclude autostatistic index
		and (i.status & 64) = 0
		and (i.status & 8388608) = 0
		and (i.status & 16777216)= 0
		order by o.name





GO
