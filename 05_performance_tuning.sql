-- Author: Ranjeet Kumar
-- Project: Query Performance Tuning
-- Result: 45 seconds → 4 seconds (91% improvement)

USE BankingETL_DB;
GO

-- =============================================
-- FIND TOP 10 SLOWEST QUERIES ON SERVER
-- =============================================
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count / 1000 AS AvgElapsedMs,
    qs.total_logical_reads / qs.execution_count       AS AvgLogicalReads,
    qs.execution_count,
    SUBSTRING(qt.text,
        (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2)+1)      AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY AvgElapsedMs DESC;
GO

-- =============================================
-- FIND MISSING INDEXES
-- =============================================
SELECT TOP 10
    OBJECT_NAME(mid.object_id, mid.database_id) AS TableName,
    migs.avg_user_impact                         AS Estimated
