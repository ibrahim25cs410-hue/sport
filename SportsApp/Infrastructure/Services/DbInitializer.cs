using Microsoft.EntityFrameworkCore;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public static class DbInitializer
{
    public static async Task PatchAsync(AppDbContext db)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN ReferenceCode TEXT NULL");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN EndTime TEXT NOT NULL DEFAULT '0001-01-01 00:00:00'");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE Bookings SET EndTime = datetime(StartTime, '+' || Hours || ' hours')
            WHERE EndTime = '0001-01-01 00:00:00' OR EndTime IS NULL
            """);

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE Bookings SET ReferenceCode = 'RY-' || strftime('%Y%m%d', StartTime) || '-' || printf('%04d', Id)
            WHERE ReferenceCode IS NULL OR ReferenceCode = ''
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync("ALTER TABLE Stadiums ADD COLUMN Latitude REAL NULL");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync("ALTER TABLE Stadiums ADD COLUMN Longitude REAL NULL");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN PaymentStatus TEXT NOT NULL DEFAULT 'unpaid'");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS BookingPayments (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                BookingId INTEGER NOT NULL,
                UserId INTEGER NOT NULL,
                Amount INTEGER NOT NULL,
                Gateway TEXT NOT NULL,
                TransactionToken TEXT NOT NULL,
                ProviderReference TEXT NULL,
                GatewayTransactionId TEXT NULL,
                Status TEXT NOT NULL,
                CreatedAt TEXT NOT NULL,
                VerifiedAt TEXT NULL,
                FOREIGN KEY (BookingId) REFERENCES Bookings(Id),
                FOREIGN KEY (UserId) REFERENCES Users(Id)
            )
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE UNIQUE INDEX IF NOT EXISTS IX_BookingPayments_TransactionToken ON BookingPayments (TransactionToken)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_BookingPayments_BookingId_Status ON BookingPayments (BookingId, Status)");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE Stadiums SET Latitude = 36.3480, Longitude = 43.1450
            WHERE Name LIKE '%النور%' AND (Latitude IS NULL OR Longitude IS NULL)
            """);
        await db.Database.ExecuteSqlRawAsync("""
            UPDATE Stadiums SET Latitude = 36.3310, Longitude = 43.1180
            WHERE Name LIKE '%الأمل%' AND (Latitude IS NULL OR Longitude IS NULL)
            """);

        await EnsureOwnerPaymentTablesAsync(db);
        await EnsureWalletTablesAsync(db);
        await EnsureDeviceTokensTableAsync(db);
        await EnsurePricingLoyaltyColumnsAsync(db);
    }

    static async Task EnsurePricingLoyaltyColumnsAsync(AppDbContext db)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Users ADD COLUMN LoyaltyPoints INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Stadiums ADD COLUMN BasePrice INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE Stadiums SET BasePrice = PricePerHour
            WHERE BasePrice IS NULL OR BasePrice = 0
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN DiscountAmount INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN IsDiscountApplied INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }
    }

    static async Task EnsureDeviceTokensTableAsync(AppDbContext db)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Users ADD COLUMN FcmToken TEXT NULL");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS DeviceTokens (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NOT NULL,
                Token TEXT NOT NULL,
                Platform TEXT NULL,
                LastUpdated TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
            )
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE UNIQUE INDEX IF NOT EXISTS IX_DeviceTokens_Token ON DeviceTokens (Token)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_DeviceTokens_UserId ON DeviceTokens (UserId)");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            INSERT OR IGNORE INTO DeviceTokens (UserId, Token, Platform, LastUpdated)
            SELECT Id, FcmToken, NULL, datetime('now')
            FROM Users
            WHERE FcmToken IS NOT NULL AND TRIM(FcmToken) != ''
            """);
    }

    static async Task EnsureWalletTablesAsync(AppDbContext db)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN PaymentMethod TEXT NOT NULL DEFAULT 'online'");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN IsCommissionPaid INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS Wallets (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                OwnerId INTEGER NOT NULL UNIQUE,
                Balance REAL NOT NULL DEFAULT 0,
                LastUpdated TEXT NOT NULL,
                FOREIGN KEY (OwnerId) REFERENCES Users(Id) ON DELETE RESTRICT
            )
            """);

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS WalletTransactions (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                WalletId INTEGER NOT NULL,
                Amount INTEGER NOT NULL,
                Type TEXT NOT NULL,
                Description TEXT NOT NULL,
                BookingId INTEGER NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (WalletId) REFERENCES Wallets(Id) ON DELETE CASCADE,
                FOREIGN KEY (BookingId) REFERENCES Bookings(Id) ON DELETE SET NULL
            )
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_WalletTransactions_WalletId_CreatedAt ON WalletTransactions (WalletId, CreatedAt)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE WalletTransactions ADD COLUMN AdminNote TEXT NULL");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE WalletTransactions SET Type = 'admin_credit' WHERE Type = 'admin_top_up'
            """);

        await db.Database.ExecuteSqlRawAsync("""
            UPDATE WalletTransactions SET AdminNote = Description
            WHERE Type IN ('admin_credit', 'admin_top_up', 'owner_top_up')
              AND (AdminNote IS NULL OR AdminNote = '')
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN CancellationPenaltyIqd INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN CancellationOwnerShareIqd INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN CancellationPlatformShareIqd INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Users ADD COLUMN OutstandingPenaltyIqd INTEGER NOT NULL DEFAULT 0");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Users ADD COLUMN AccountStatus TEXT NOT NULL DEFAULT 'active'");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "ALTER TABLE Bookings ADD COLUMN CancelledAt TEXT NULL");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS SecurityLogs (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NULL,
                EventType TEXT NOT NULL,
                Reason TEXT NOT NULL,
                Details TEXT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE SET NULL
            )
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_SecurityLogs_UserId_CreatedAt ON SecurityLogs (UserId, CreatedAt)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_Bookings_UserId_CancelledAt ON Bookings (UserId, CancelledAt)");
        }
        catch { /* exists */ }

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS PushNotificationLogs (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                UserId INTEGER NULL,
                DeviceTokenPreview TEXT NOT NULL,
                Title TEXT NOT NULL,
                Body TEXT NOT NULL,
                EventType TEXT NOT NULL,
                Status TEXT NOT NULL,
                ProviderMessageId TEXT NULL,
                Error TEXT NULL,
                CreatedAt TEXT NOT NULL,
                FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE SET NULL
            )
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_PushNotificationLogs_UserId_CreatedAt ON PushNotificationLogs (UserId, CreatedAt)");
        }
        catch { /* exists */ }

        // Seed wallets for existing owners with starter balance so fields stay bookable in dev.
        await db.Database.ExecuteSqlRawAsync("""
            INSERT INTO Wallets (OwnerId, Balance, LastUpdated)
            SELECT u.Id, 500000, datetime('now')
            FROM Users u
            WHERE u.Role = 'owner'
              AND NOT EXISTS (SELECT 1 FROM Wallets w WHERE w.OwnerId = u.Id)
            """);
    }

    /// جداول عمولة المالك — تُنشأ تلقائياً إذا غابت عن قاعدة بيانات قديمة.
    static async Task EnsureOwnerPaymentTablesAsync(AppDbContext db)
    {
        await db.Database.ExecuteSqlRawAsync("""
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
            """);

        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS OwnerFeeInvoiceItems (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                InvoiceId INTEGER NOT NULL,
                BookingId INTEGER NOT NULL,
                FOREIGN KEY (InvoiceId) REFERENCES OwnerFeeInvoices(Id) ON DELETE CASCADE,
                FOREIGN KEY (BookingId) REFERENCES Bookings(Id) ON DELETE RESTRICT
            )
            """);

        await db.Database.ExecuteSqlRawAsync("""
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
            """);

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE UNIQUE INDEX IF NOT EXISTS IX_OwnerFeeInvoiceItems_BookingId ON OwnerFeeInvoiceItems (BookingId)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_OwnerFeeInvoiceItems_InvoiceId ON OwnerFeeInvoiceItems (InvoiceId)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_OwnerFeeInvoices_OwnerId_Status ON OwnerFeeInvoices (OwnerId, Status)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_PlatformPayments_InvoiceId ON PlatformPayments (InvoiceId)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE INDEX IF NOT EXISTS IX_PlatformPayments_OwnerId_Status ON PlatformPayments (OwnerId, Status)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE UNIQUE INDEX IF NOT EXISTS IX_PlatformPayments_TransactionToken ON PlatformPayments (TransactionToken)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "CREATE UNIQUE INDEX IF NOT EXISTS IX_PlatformPayments_GatewayTransactionId ON PlatformPayments (GatewayTransactionId)");
        }
        catch { /* exists */ }

        try
        {
            await db.Database.ExecuteSqlRawAsync(
                "INSERT OR IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260624022800_AddOwnerPayments', '8.0.11')");
            await db.Database.ExecuteSqlRawAsync(
                "INSERT OR IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260624022810_AddPaymentGatewayTransactionId', '8.0.11')");
        }
        catch { /* history table may not exist yet */ }
    }

    public static void Seed(AppDbContext db)
    {
        if (db.Fields.Any()) return;

        var owner = new User
        {
            Name = "أحمد المالك",
            Email = "owner@test.com",
            Phone = "07701234567",
            Province = "نينوى",
            Role = "owner"
        };
        owner.PasswordHash = PasswordService.Hash(owner, "123456");
        db.Users.Add(owner);
        db.SaveChanges();

        db.Fields.AddRange(
            new Field { OwnerId = owner.Id, Name = "ملعب النور", Address = "موصل - حي الزهور", Phone = "07701111111", PricePerHour = 15000, BasePrice = 15000, Latitude = 36.3480, Longitude = 43.1450 },
            new Field { OwnerId = owner.Id, Name = "ملعب الأمل", Address = "موصل - حي العربي", Phone = "07702222222", PricePerHour = 12000, BasePrice = 12000, Latitude = 36.3310, Longitude = 43.1180 }
        );
        db.SaveChanges();

        db.Wallets.Add(new Wallet
        {
            OwnerId = owner.Id,
            Balance = 500_000,
            LastUpdated = DateTime.UtcNow
        });
        db.SaveChanges();

        var admin = new User
        {
            Name = "مدير رياضة",
            Email = "admin@riyada.iq",
            Phone = "07700000000",
            Province = "نينوى",
            Role = "admin"
        };
        admin.PasswordHash = PasswordService.Hash(admin, "admin123");
        db.Users.Add(admin);
        db.SaveChanges();

        var testUser = new User
        {
            Name = "محمد اللاعب",
            Email = "user@test.com",
            Phone = "07709999999",
            Province = "نينوى",
            Role = "user"
        };
        testUser.PasswordHash = PasswordService.Hash(testUser, "123456");
        db.Users.Add(testUser);
        db.SaveChanges();
    }
}
