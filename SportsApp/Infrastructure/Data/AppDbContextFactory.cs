using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Data;

/// <summary>
/// مصنع تصميم لأوامر dotnet ef migrations.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var config = new ConfigurationBuilder()
            .SetBasePath(Path.Combine(Directory.GetCurrentDirectory(), "../Api"))
            .AddJsonFile("appsettings.json", optional: false)
            .Build();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(config.GetConnectionString("Default"))
            .Options;

        return new AppDbContext(options);
    }
}
