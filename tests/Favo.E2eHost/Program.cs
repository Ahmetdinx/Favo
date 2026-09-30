extern alias books;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Testcontainers.PostgreSql;
using Favo.Books.Modules.Identity.Persistence;
using Favo.Books.Modules.Catalog.Persistence;
using Favo.Books.Modules.Reading.Persistence;
using Favo.Books.Modules.Profiles.Persistence;
using Favo.Books.Modules.Community.Persistence;

var root = Environment.GetEnvironmentVariable("FAVO_BOOKS_ROOT") ?? throw new Exception("Set FAVO_BOOKS_ROOT.");
await using var database = new PostgreSqlBuilder("postgres:18.4-alpine3.24")
    .WithDatabase("favo_shared_auth_e2e").WithUsername("postgres").WithPassword("favo-tests-only")
    .Build();
await database.StartAsync();
await using var factory = new BooksFactory(root, database.GetConnectionString());
factory.UseKestrel(5118);
using (var scope = factory.Services.CreateScope())
{
    await scope.ServiceProvider.GetRequiredService<IdentityDbContext>().Database.MigrateAsync();
    await scope.ServiceProvider.GetRequiredService<CatalogDbContext>().Database.MigrateAsync();
    await scope.ServiceProvider.GetRequiredService<ReadingDbContext>().Database.MigrateAsync();
    await scope.ServiceProvider.GetRequiredService<ProfilesDbContext>().Database.MigrateAsync();
    await scope.ServiceProvider.GetRequiredService<CommunityDbContext>().Database.MigrateAsync();
}
using var client = new HttpClient { BaseAddress = new Uri("http://localhost:5118") };
var registration = await client.PostAsJsonAsync("/api/identity/register", new {
    email = "shared-auth@example.test", nickname = "FavoTestReader", password = "Favo-Test-Only-2026!"
});
registration.EnsureSuccessStatusCode();
Console.WriteLine("READY: isolated Books API on 5118, disposable test account seeded. Production database untouched.");
using var stop = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => { e.Cancel = true; stop.Cancel(); };
try { await Task.Delay(Timeout.Infinite, stop.Token); } catch (OperationCanceledException) { }

sealed class BooksFactory(string root, string connection) : WebApplicationFactory<books::Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseContentRoot(Path.Combine(root, "src/backend/Api/Favo.Books.Api"));
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Database", connection);
        builder.UseSetting("Jwt:Secret", "favo-isolated-e2e-only-signing-secret-at-least-32-characters");
        builder.UseSetting("Jwt:Issuer", "Favo.E2e");
        builder.UseSetting("Jwt:Audience", "Favo.E2e");
        builder.UseSetting("Jwt:ExpirationMinutes", "15");
        builder.UseSetting("Catalog:ImportJobs:WorkerEnabled", "false");
        builder.UseSetting("Google:ClientId", "");
        builder.UseSetting("Logging:LogLevel:Default", "Warning");
    }
}
