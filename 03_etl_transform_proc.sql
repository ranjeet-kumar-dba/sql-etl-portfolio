-- Author: Ranjeet Kumar
-- Project: Banking ETL Pipeline
-- Script: ETL Transform Stored Procedure

USE BankingETL_DB;
GO

CREATE OR ALTER PROCEDURE etl.usp_TransformBankingData
    @BatchSize  INT = 10000,
    @Debug      BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrorRows  INT = 0;
    DECLARE @ProcessedRows INT = 0;
    DECLARE @StartTime  DATETIME2 = GETDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- STEP 1: Flag invalid records
        UPDATE staging.RawTransactions
        SET ProcessStatus = 'E',
            ErrorMessage = CASE
                WHEN AccountNumber IS NULL
                    THEN 'Missing AccountNumber'
                WHEN ISDATE(TransactionDate) = 0
                    THEN 'Invalid Date'
                WHEN ISNUMERIC(TransactionAmount) = 0
                    THEN 'Invalid Amount'
                WHEN TransactionType NOT IN ('CR','DR','TRF','INT','CHG')
                    THEN 'Invalid Type'
            END
        WHERE ProcessStatus = 'N'
          AND (
                AccountNumber IS NULL
             OR ISDATE(TransactionDate) = 0
             OR ISNUMERIC(TransactionAmount) = 0
             OR TransactionType NOT IN ('CR','DR','TRF','INT','CHG')
          );

        SET @ErrorRows = @@ROWCOUNT;

        -- STEP 2: Upsert Customer
        MERGE dbo.Customer AS target
        USING (
            SELECT DISTINCT
                LTRIM(RTRIM(AccountNumber)) AS AccountNumber,
                LTRIM(RTRIM(CustomerName))  AS CustomerName,
                LTRIM(RTRIM(BranchCode))    AS BranchCode,
                LTRIM(RTRIM(IFSC_Code))     AS IFSC_Code
            FROM staging.RawTransactions
            WHERE ProcessStatus = 'N'
        ) AS source
        ON target.AccountNumber = source.AccountNumber
        WHEN NOT MATCHED THEN
            INSERT (CustomerName, AccountNumber, BranchCode, IFSC_Code)
            VALUES (source.CustomerName, source.AccountNumber,
                    source.BranchCode, source.IFSC_Code)
        WHEN MATCHED AND target.CustomerName != source.CustomerName THEN
            UPDATE SET CustomerName = source.CustomerName,
                       UpdatedAt = GETDATE();

        -- STEP 3: Load Transactions
        INSERT INTO dbo.Transaction
            (CustomerID, TransactionDate, TransactionAmount, TypeCode, SourceStagingID)
        SELECT
            c.CustomerID,
            CAST(s.TransactionDate   AS DATE),
            CAST(s.TransactionAmount AS DECIMAL(18,2)),
            s.TransactionType,
            s.StagingID
        FROM staging.RawTransactions s
        JOIN dbo.Customer c
            ON c.AccountNumber = LTRIM(RTRIM(s.AccountNumber))
        WHERE s.ProcessStatus = 'N';

        SET @ProcessedRows = @@ROWCOUNT;

        -- STEP 4: Mark Done
        UPDATE staging.RawTransactions
        SET ProcessStatus = 'D'
        WHERE ProcessStatus = 'N';

        COMMIT TRANSACTION;

        IF @Debug = 1
            SELECT
                'ETL Complete'  AS Status,
                @ProcessedRows  AS RowsLoaded,
                @ErrorRows      AS RowsErrored,
                DATEDIFF(SECOND, @StartTime, GETDATE()) AS DurationSeconds;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT 'ETL procedure created successfully.';
GO
