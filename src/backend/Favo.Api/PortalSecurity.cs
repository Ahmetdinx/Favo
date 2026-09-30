namespace Favo.Api;
public static class PortalSecurity
{
    public static bool IsTrustedMutation(string? origin, string? fetchSite, string publicOrigin)
        => fetchSite != "cross-site" && string.Equals(origin, publicOrigin, StringComparison.Ordinal);
    public static string ValidateOrigin(string value, bool development)
    {
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri)
            || uri.UserInfo.Length != 0 || uri.Query.Length != 0 || uri.Fragment.Length != 0
            || uri.AbsolutePath != "/"
            || (uri.Scheme != "https" && !(development && uri.Scheme == "http" && uri.IsLoopback)))
            throw new ArgumentException("Configure an HTTPS origin; loopback HTTP is supported only in Development.");
        return uri.GetLeftPart(UriPartial.Authority);
    }
}

