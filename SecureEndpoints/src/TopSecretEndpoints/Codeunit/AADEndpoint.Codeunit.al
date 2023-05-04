codeunit 50105 AADEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        RequestHeaders: HttpHeaders;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://bc-apimanager.azure-api.net/TopSecret-AzureFunction/SecureEndpointAAD';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');

        if Token <> '' then begin
            RequestMessage.GetHeaders(RequestHeaders);

            RequestHeaders.Clear();
            RequestHeaders.Add('Authorization', 'Bearer ' + Token);
        end;
    end;
}