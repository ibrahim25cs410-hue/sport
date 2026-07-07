using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

/// <summary>
/// Applies schema for SQLite (EF migrations) or PostgreSQL (model ensure + seed).
/// </summary>
public static class DatabaseInitializer
{
    private const string InitialMigrationId = "20260624022759_InitialCreate";

    public static async Task InitializeAsync(AppDbContext db, ILogger logger, DatabaseProviderInfo providerInfo)
    {
        if (providerInfo.Provider == DatabaseProvider.PostgreSql)
        {
            await InitializePostgreSqlAsync(db, logger);
            return;
        }

        await InitializeSqliteAsync(db, logger);
    }

    static async Task InitializePostgreSqlAsync(AppDbContext db, ILogger logger)
    {
        var hasUsers = await TableExistsAsync(db, "Users");
        if (!hasUsers)
        {
            logger.LogInformation("PostgreSQL: creating schema from model.");
            await db.Database.EnsureCreatedAsync();
        }
        else
        {
            logger.LogInformation("PostgreSQL: schema already present.");
        }

        await DbInitializer.PatchAsync(db);
        DbInitializer.Seed(db);
    }

    static async Task InitializeSqliteAsync(AppDbContext db, ILogger logger)
    {
        await NormalizeMigrationHistoryAsync(db);

        var applied = (await db.Database.GetAppliedMigrationsAsync()).ToList();
        var pending = (await db.Database.GetPendingMigrationsAsync()).ToList();

        if (!applied.Any() && await LegacySchemaExistsAsync(db))
        {
            logger.LogInformation("Legacy SQLite schema detected — baselining migration {MigrationId}.", InitialMigrationId);
            await BaselineLegacyAsync(db);
            await DbInitializer.PatchAsync(db);
        }
        else if (pending.Count > 0)
        {
            logger.LogInformation("Applying {Count} pending migration(s).", pending.Count);
            await db.Database.MigrateAsync();
        }
        else if (!applied.Any())
        {
            logger.LogInformation("Creating database via migrations.");
            await db.Database.MigrateAsync();
        }
        else
        {
            logger.LogInformation("Database schema is up to date.");
        }

        await DbInitializer.PatchAsync(db);
        DbInitializer.Seed(db);
    }

    static async Task<bool> TableExistsAsync(AppDbContext db, string tableName)
    {
        try
        {
            await db.Database.OpenConnectionAsync();
            await using var cmd = db.Database.GetDbConnection().CreateCommand();
            cmd.CommandText = """
                SELECT EXISTS (
                  SELECT 1 FROM information_schema.tables
                  WHERE table_schema = 'public' AND table_name = @name
                )
                """;
            var p = cmd.CreateParameter();
            p.ParameterName = "name";
            p.Value = tableName;
            cmd.Parameters.Add(p);
            var result = await cmd.ExecuteScalarAsync();
            return result is true or 1 or 1L;
        }
        catch
        {
            return false;
        }
        finally
        {
            await db.Database.CloseConnectionAsync();
        }
    }

    static async Task<bool> LegacySchemaExistsAsync(AppDbContext db)
    {
        try
        {
            await db.Database.OpenConnectionAsync();
            await using var cmd = db.Database.GetDbConnection().CreateCommand();
            cmd.CommandText = "SELECT name FROM sqlite_master WHERE type='table' AND name='Users' LIMIT 1";
            var result = await cmd.ExecuteScalarAsync();
            return result is not null;
        }
        catch
        {
            return false;
        }
        finally
        {
            await db.Database.CloseConnectionAsync();
        }
    }

    static async Task BaselineLegacyAsync(AppDbContext db)
    {
        await db.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS __EFMigrationsHistory (
                MigrationId TEXT NOT NULL CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY,
                ProductVersion TEXT NOT NULL
            );
            """);

        await db.Database.ExecuteSqlRawAsync(
            $"INSERT OR IGNORE INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('{InitialMigrationId}', '8.0.11')");
    }

    static async Task NormalizeMigrationHistoryAsync(AppDbContext db)
    {
        try
        {
            await db.Database.ExecuteSqlRawAsync("""
                UPDATE __EFMigrationsHistory SET MigrationId = '20260624022800_AddOwnerPayments'
                WHERE MigrationId = '20260622120000_AddOwnerPayments'
                """);
            await db.Database.ExecuteSqlRawAsync("""
                UPDATE __EFMigrationsHistory SET MigrationId = '20260624022810_AddPaymentGatewayTransactionId'
                WHERE MigrationId = '20260622140000_AddPaymentGatewayTransactionId'
                """);
        }
        catch
        {
            /* history table may not exist yet */
        }
    }
}
