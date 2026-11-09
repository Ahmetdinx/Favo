using Favo.Api;
var count = 0;
void Check(bool value, string name) { if (!value) throw new Exception(name); count++; }
Check(BooksNavigation.Destination(null) == "/kitap/catalog", "Catalog");
Check(BooksNavigation.Destination("/profile") == "/kitap/profile", "Profile");
var id = Guid.NewGuid();
Check(BooksNavigation.Destination($"/catalog/books/{id}") == $"/kitap/catalog/books/{id}", "Direct book");
foreach (var path in new[] { "//evil.test", "https://evil.test", "/\\evil.test", "/login", "/profile?returnUrl=https://evil.test", "/catalog#access_token=x", "/catalog/../login", "/catalog/books/not-a-guid", "/catalog/books/%2f%2fevil.test", "/%2f%2fevil.test", "\r\nLocation: https://evil.test" })
    Check(BooksNavigation.Destination(path) is null, "Reject unsafe destination");
foreach (var origin in new[] { "http://books.example.com", "https://user:pass@books.example.com", "https://books.example.com/path", "https://books.example.com/?x=1", "https://books.example.com/#fragment", "javascript:alert(1)", "http://localhost:5173" }) {
    var rejected = false;
    try { PortalSecurity.ValidateOrigin(origin, false); } catch (ArgumentException) { rejected = true; }
    Check(rejected, "Reject unsafe production origin");
}
Check(PortalSecurity.ValidateOrigin("http://localhost:5175", true) == "http://localhost:5175", "Development origin");
Check(PortalSecurity.IsTrustedMutation("https://favo.test", "same-origin", "https://favo.test"), "Same origin mutation");
Check(!PortalSecurity.IsTrustedMutation("https://evil.test", "same-site", "https://favo.test"), "Reject sibling site");
Check(!PortalSecurity.IsTrustedMutation(null, null, "https://favo.test"), "Missing Origin rejected");
Check(!PortalSecurity.IsTrustedMutation("null", "cross-site", "https://favo.test"), "Opaque origin rejected");
Check(!PortalSecurity.IsTrustedMutation("https://favo.test", "cross-site", "https://favo.test"), "Cross site rejected");
var forwarded = new Microsoft.AspNetCore.Http.DefaultHttpContext();
forwarded.Connection.RemoteIpAddress = System.Net.IPAddress.Parse("203.0.113.9");
forwarded.Request.Headers["X-Forwarded-For"] = "198.51.100.1";
using var proxied = new HttpRequestMessage();
await new ClientAddressTransformer().TransformRequestAsync(forwarded, proxied, "http://books.test/", default);
Check(string.Join(",", proxied.Headers.GetValues("X-Forwarded-For")) == "203.0.113.9", "Client forwarded address cannot be spoofed");
Console.WriteLine($"PASS: {count} navigation/CSRF/configuration checks.");
