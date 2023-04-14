codeunit 50104 FBEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text): HttpRequestMessage;
    var
        RequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://topsecretfunction.azurewebsites.net/api/SecureEndpointFB?code=Q8qFCvv00H4GPrixeVkY38OSQMTgNJODpKIWhgibzDYgAzFuJ6QJ8g==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');

        if Token <> '' then begin
            RequestMessage.GetHeaders(RequestHeaders);

            RequestHeaders.Clear();
            RequestHeaders.Add('Authorization', 'Bearer ' + Token);
        end;
    end;
}