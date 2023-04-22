codeunit 50106 CertificateEndpoint implements IEndpoint
{
    var
        _ICertificateSigner: Interface ICertificateSigner;
        IsInitialized: Boolean;

    procedure Initialize(ICertificateSigner: Interface ICertificateSigner)
    begin
        ICertificateSigner := ICertificateSigner;
        IsInitialized := true;
    end;

    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        ContentSignature: Text;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://topsecretfunction.azurewebsites.net/api/SecureEndpointCertificate?code=55PPM6b1_ygT5HzA6B0LKkBtGkEUzuKEgssrgPA5IhZZAzFuf1O7sg==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('POST');

        if Content = '' then
            Content := GetContent();

        HttpContent.WriteFrom(Content);
        HttpContent.ReadAs(Content);
        RequestMessage.Content(HttpContent);

        RequestMessage.Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        _ICertificateSigner := GetCertificateSigner();
        ContentSignature := _ICertificateSigner.Sign(Content);

        ContentHeaders.Add('Digest', ContentSignature);
    end;

    local procedure GetCertificateSigner(): Interface ICertificateSigner
    var
        MyCertificateSigner: Codeunit MyCertificateSigner;
    begin
        if not IsInitialized then
            exit(MyCertificateSigner)
        else
            exit(_ICertificateSigner);
    end;

    local procedure GetContent(): Text
    begin
        EXIT('{"name":"Tine Staric","age":42}');
    end;
}