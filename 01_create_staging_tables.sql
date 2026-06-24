-- Author: Ranjeet Kumar
-- Project: Banking ETL Pipeline
-- Script: Create Staging Tables

USE BankingETL_DB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

CREATE TABLE staging.RawTransactions (
    StagingID         BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceFileName    NVARCHAR(255)   NOT NULL,
    AccountNumber     NVARCHAR(50),
    TransactionDate   NVARCHAR(50),
    TransactionAmount NVARCHAR(50),
    TransactionType   NVARCHAR(50),
    BranchCode        NVARCHAR(20),
    IFSC_Code         NVARCHAR(20),
    CustomerName      NVARCHAR(200),
    RawData           NVARCHAR(MAX),
    LoadedAt          DATETIME2       DEFAULT GETDATE(),
    ProcessStatus     CHAR(1)         DEFAULT 'N',
    ErrorMessage      NVARCHAR(1000)  NULL
);
GO

CREATE TABLE staging.FileLoadAudit (
    AuditID        INT IDENTITY(1,1) PRIMARY KEY,
    FileName       NVARCHAR(255)   NOT NULL,
    LoadStartTime  DATETIME2       DEFAULT GETDATE(),
    LoadEndTime    DATETIME2       NULL,
    TotalRows      INT             DEFAULT 0,
    SuccessRows    INT             DEFAULT 0,
    ErrorRows      INT             DEFAULT 0,
    LoadStatus     NVARCHAR(20)    DEFAULT 'STARTED',
    LoadedBy       NVARCHAR(100)   DEFAULT SYSTEM_USER
);
GO

PRINT 'Staging tables created successfully.';
GO
