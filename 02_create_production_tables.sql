-- Author: Ranjeet Kumar
-- Project: Banking ETL Pipeline
-- Script: Create Production Tables

USE BankingETL_DB;
GO

CREATE TABLE dbo.TransactionType (
    TypeCode    CHAR(3)       PRIMARY KEY,
    TypeName    NVARCHAR(50)  NOT NULL,
    IsDebit     BIT           NOT NULL DEFAULT 0
);
GO

INSERT INTO dbo.TransactionType VALUES
('CR', 'Credit',   0),
('DR', 'Debit',    1),
('TRF','Transfer', 1),
('INT','Interest', 0),
('CHG','Charge',   1);
GO

CREATE TABLE dbo.Customer (
    CustomerID    INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName  NVARCHAR(200) NOT NULL,
    AccountNumber NVARCHAR(50)  NOT NULL UNIQUE,
    BranchCode    NVARCHAR(20),
    IFSC_Code     NVARCHAR(20),
    CreatedAt     DATETIME2     DEFAULT GETDATE(),
    UpdatedAt     DATETIME2     DEFAULT GETDATE(),
    IsActive      BIT           DEFAULT 1
);
GO

CREATE TABLE dbo.Transaction (
    TransactionID     BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerID        INT            NOT NULL REFERENCES dbo.Customer(CustomerID),
    TransactionDate   DATE           NOT NULL,
    TransactionAmount DECIMAL(18,2)  NOT NULL,
    TypeCode          CHAR(3)        NOT NULL REFERENCES dbo.TransactionType(TypeCode),
    SourceStagingID   BIGINT,
    CreatedAt         DATETIME2      DEFAULT GETDATE()
);
GO

CREATE INDEX IX_Customer_AccountNumber   ON dbo.Customer(AccountNumber);
CREATE INDEX IX_Transaction_CustomerID   ON dbo.Transaction(CustomerID);
CREATE INDEX IX_Transaction_Date         ON dbo.Transaction(TransactionDate);
GO

PRINT 'Production tables created successfully.';
GO
