namespace Riyada.Infrastructure.Data;

/// <summary>Detects database provider from connection string.</summary>
public static class DatabaseProvider
{
    public const string PostgreSql = "postgresql";
    public const string Sqlite = "sqlite";

    public static string Detect(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString)) return Sqlite;
        var cs = connectionString.Trim();
        if (cs.Contains("Host=", StringComparison.OrdinalIgnoreCase) ||
            cs.Contains("Server=", StringComparison.OrdinalIgnoreCase) && cs.Contains("Port=5432", StringComparison.OrdinalIgnoreCase) ||
            cs.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase) ||
            cs.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase))
            return PostgreSql;
        return Sqlite;
    }

    public static bool IsPostgreSql(string? connectionString) =>
        Detect(connectionString) == PostgreSql;
}
