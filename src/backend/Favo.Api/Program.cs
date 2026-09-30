using System.Net;
using Favo.Api;
using Microsoft.Extensions.FileProviders;
using Yarp.ReverseProxy.Forwarder;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpForwarder();
var development = builder.Environment.IsDevelopment();
var publicOrigin = PortalSecurity.ValidateOrigin(builder.Configuration["Portal:Origin"]
    ?? throw new InvalidOperationException("Configure Portal:Origin."), development);
var apiOrigin = PortalSecurity.ValidateOrigin(builder.Configuration["Books:ApiOrigin"]
    ?? throw new InvalidOperationException("Configure Books:ApiOrigin."), development);
var booksRoot = Path.GetFullPath(builder.Configuration["Books:WebRoot"]
    ?? Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "kitap"), builder.Environment.ContentRootPath);
if (!File.Exists(Path.Combine(booksRoot, "index.html")))
    throw new InvalidOperationException("Books frontend is missing. Run Start-Favo.ps1 or Publish-Favo.ps1 first.");
using var booksFiles = new PhysicalFileProvider(booksRoot);
using var proxyClient = new HttpMessageInvoker(new SocketsHttpHandler
{
    UseProxy = false, UseCookies = false, AllowAutoRedirect = false,
    AutomaticDecompression = DecompressionMethods.None, ConnectTimeout = TimeSpan.FromSeconds(5)
});
var app = builder.Build();
app.Use(async (context, next) =>
{
    context.Response.Headers.XContentTypeOptions = "nosniff";
    context.Response.Headers["Referrer-Policy"] = "no-referrer";
    context.Response.Headers.ContentSecurityPolicy = "default-src 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline' https://accounts.google.com; script-src 'self' https://accounts.google.com; connect-src 'self' https://accounts.google.com; frame-src https://accounts.google.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'";
    if (context.Request.Path.StartsWithSegments("/api"))
    {
        context.Response.Headers.CacheControl = "private, no-store";
        if (!HttpMethods.IsGet(context.Request.Method) && !HttpMethods.IsHead(context.Request.Method)
            && !PortalSecurity.IsTrustedMutation(context.Request.Headers.Origin,
                context.Request.Headers["Sec-Fetch-Site"], publicOrigin))
        {
            context.Response.StatusCode = 403;
            await context.Response.WriteAsJsonAsync(new { message = "Bu işlem yalnızca Favo üzerinden yapılabilir." });
            return;
        }
    }
    await next();
});
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseStaticFiles(new StaticFileOptions { FileProvider = booksFiles, RequestPath = "/kitap" });
app.MapGet("/api/health", () => Results.Ok(new { status = "ok", application = "Favo" }));
app.MapGet("/go/books", (string? path, HttpContext context) =>
{
    context.Response.Headers.CacheControl = "no-store";
    var destination = BooksNavigation.Destination(path);
    return destination is null ? Results.BadRequest(new { message = "Geçersiz Kitap bağlantısı." })
        : Results.LocalRedirect(destination);
});
app.MapGet("/kitap", () => Results.LocalRedirect("/kitap/"));
app.Map("/api/{**path}", async (HttpContext context, IHttpForwarder forwarder) =>
{
    var error = await forwarder.SendAsync(context, apiOrigin, proxyClient,
        new ForwarderRequestConfig { ActivityTimeout = TimeSpan.FromSeconds(60) }, HttpTransformer.Default);
    if (error != ForwarderError.None && !context.Response.HasStarted)
    {
        context.Response.StatusCode = 502;
        await context.Response.WriteAsJsonAsync(new { message = "Kitap servisine ulaşılamıyor. Lütfen tekrar deneyin." });
    }
});
app.MapFallbackToFile("/kitap/{*path:nonfile}", "index.html", new StaticFileOptions { FileProvider = booksFiles });
app.MapFallbackToFile("index.html");
app.Run();

