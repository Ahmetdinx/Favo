using Yarp.ReverseProxy.Forwarder;

namespace Favo.Api;

/// <summary>Sends the real client address and discards any X-Forwarded-For value supplied by the client.</summary>
public sealed class ClientAddressTransformer : HttpTransformer
{
    public override async ValueTask TransformRequestAsync(HttpContext httpContext, HttpRequestMessage proxyRequest,
        string destinationPrefix, CancellationToken cancellationToken)
    {
        await base.TransformRequestAsync(httpContext, proxyRequest, destinationPrefix, cancellationToken);
        proxyRequest.Headers.Remove("X-Forwarded-For");
        if (httpContext.Connection.RemoteIpAddress is { } address)
            proxyRequest.Headers.TryAddWithoutValidation("X-Forwarded-For", address.ToString());
    }
}
