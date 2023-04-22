codeunit 50106 CertificateEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://topsecretfunction.azurewebsites.net/api/SecureEndpointCertificate?code=55PPM6b1_ygT5HzA6B0LKkBtGkEUzuKEgssrgPA5IhZZAzFuf1O7sg==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('POST');

        if Content = '' then
            Content := GetContent();

        HttpContent.WriteFrom(Content);
        RequestMessage.Content(HttpContent);

        RequestMessage.Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
    end;

    local procedure GetContent(): Text
    begin
        EXIT('{"name":"Tine Staric","age":42}');
    end;
}