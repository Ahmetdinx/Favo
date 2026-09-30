namespace Favo.Api;
public static class BooksNavigation
{
    public static string? Destination(string? path)
    {
        path ??= "/catalog";
        if (path is "/" or "/catalog" or "/profile") return "/kitap" + path;
        const string prefix = "/catalog/books/";
        if (path.StartsWith(prefix, StringComparison.Ordinal)
            && Guid.TryParseExact(path[prefix.Length..], "D", out var id))
            return "/kitap" + prefix + id.ToString("D");
        return null;
    }
}

