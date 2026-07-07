using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Riyada.Infrastructure.Data;

public static class DatabaseServiceExtensions
{
    public static IServiceCollection AddRiyadaDatabase(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("ConnectionStrings:Default is required.");

        var provider = DatabaseProvider.Detect(connectionString);

        services.AddDbContext<AppDbContext>(options =>
        {
            if (provider == DatabaseProvider.PostgreSql)
                options.UseNpgsql(connectionString, npgsql => npgsql.EnableRetryOnFailure(3));
            else
                options.UseSqlite(connectionString);
        });

        services.AddSingleton(new DatabaseProviderInfo(provider));
        return services;
    }
}

public sealed record DatabaseProviderInfo(string Provider);
