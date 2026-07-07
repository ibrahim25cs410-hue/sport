"""Apply owner payment tables patch to sports.db (one-time fix for legacy DBs)."""
import sqlite3
from pathlib import Path

DB = Path(r"d:\sport\SportsApp\Api\sports.db")

SQL = [
    """
    CREATE TABLE IF NOT EXISTS OwnerFeeInvoices (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        OwnerId INTEGER NOT NULL,
        Amount INTEGER NOT NULL,
        TotalHours INTEGER NOT NULL,
        Status TEXT NOT NULL,
        Title TEXT NOT NULL,
        CreatedAt TEXT NOT NULL,
        PaidAt TEXT NULL,
        FOREIGN KEY (OwnerId) REFERENCES Users(Id) ON DELETE RESTRICT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS OwnerFeeInvoiceItems (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceId INTEGER NOT NULL,
        BookingId INTEGER NOT NULL,
        FOREIGN KEY (InvoiceId) REFERENCES OwnerFeeInvoices(Id) ON DELETE CASCADE,
        FOREIGN KEY (BookingId) REFERENCES Bookings(Id) ON DELETE RESTRICT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS PlatformPayments (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceId INTEGER NOT NULL,
        OwnerId INTEGER NOT NULL,
        Amount INTEGER NOT NULL,
        Gateway TEXT NOT NULL,
        TransactionToken TEXT NOT NULL,
        ProviderReference TEXT NULL,
        GatewayTransactionId TEXT NULL,
        Status TEXT NOT NULL,
        CreatedAt TEXT NOT NULL,
        VerifiedAt TEXT NULL,
        FOREIGN KEY (InvoiceId) REFERENCES OwnerFeeInvoices(Id) ON DELETE RESTRICT,
        FOREIGN KEY (OwnerId) REFERENCES Users(Id) ON DELETE RESTRICT
    )
    """,
    "CREATE UNIQUE INDEX IF NOT EXISTS IX_OwnerFeeInvoiceItems_BookingId ON OwnerFeeInvoiceItems (BookingId)",
    "CREATE INDEX IF NOT EXISTS IX_OwnerFeeInvoiceItems_InvoiceId ON OwnerFeeInvoiceItems (InvoiceId)",
    "CREATE INDEX IF NOT EXISTS IX_OwnerFeeInvoices_OwnerId_Status ON OwnerFeeInvoices (OwnerId, Status)",
    "CREATE INDEX IF NOT EXISTS IX_PlatformPayments_InvoiceId ON PlatformPayments (InvoiceId)",
    "CREATE INDEX IF NOT EXISTS IX_PlatformPayments_OwnerId_Status ON PlatformPayments (OwnerId, Status)",
    "CREATE UNIQUE INDEX IF NOT EXISTS IX_PlatformPayments_TransactionToken ON PlatformPayments (TransactionToken)",
    "CREATE UNIQUE INDEX IF NOT EXISTS IX_PlatformPayments_GatewayTransactionId ON PlatformPayments (GatewayTransactionId)",
    "INSERT OR IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260624022800_AddOwnerPayments', '8.0.11')",
    "INSERT OR IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260624022810_AddPaymentGatewayTransactionId', '8.0.11')",
]

def main():
    conn = sqlite3.connect(DB)
    for stmt in SQL:
        conn.execute(stmt)
    conn.commit()
    tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY 1")]
    conn.close()
    print("OK tables:", tables)

if __name__ == "__main__":
    main()
