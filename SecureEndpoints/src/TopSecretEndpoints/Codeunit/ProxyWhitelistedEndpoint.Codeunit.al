codeunit 50109 ProxyWhitelistedEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        ResourceURL: Text;
    begin
        ResourceURL := 'https://bc-apimanager.azure-api.net/TopSecret-AzureFunction/SecureEndpointWhitelisted';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');
    end;
}