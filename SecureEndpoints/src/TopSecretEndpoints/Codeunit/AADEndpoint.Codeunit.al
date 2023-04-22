codeunit 50105 AADEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        RequestHeaders: HttpHeaders;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://topsecretfunction.azurewebsites.net/api/SecureEndpointAAD?code=ww0E70mHaO--VIV3oAnl-9ARvkTn70WP12uZlMcne42bAzFumeqnSg==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');

        if Token <> '' then begin
            RequestMessage.GetHeaders(RequestHeaders);

            RequestHeaders.Clear();
            RequestHeaders.Add('Authorization', 'Bearer ' + Token);
        end;
    end;
}