codeunit 50101 EndpointManagement
{
    var
        _ICertificateSigner: Interface ICertificateSigner;
        IsInitialized: Boolean;

    [NonDebuggable]
    internal procedure GetTopSecretInfo(
        ITokenGetter: Interface ITokenGetter;
        IEndpoint: Interface IEndpoint;
        SignMessage: Boolean
    ) ResponseMessage: HttpResponseMessage
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        Token: Text;
    begin
        Token := ITokenGetter.GetToken();

        RequestMessage := IEndpoint.GetRequestMessage(Token, '');

        if SignMessage then
            SignMessageContent(RequestMessage);

        Client.Send(RequestMessage, ResponseMessage);
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

    internal procedure GetRedirectUrl(): Text
    var
        Environment: Codeunit "Environment Information";
    begin
        if Environment.IsSaaSInfrastructure() then
            exit('https://businesscentral.dynamics.com/OAuthLanding.htm')
        else
            exit(GetBaseUrl() + '/OAuthLanding.htm');
    end;

    local procedure GetBaseUrl(): Text
    var
        BaseIndex: Integer;
        EndBaseUrlIndex: Integer;
        Baseurl: Text;
        RedirectUrl: Text;
    begin
        RedirectUrl := GetUrl(ClientType::Web);

        if StrPos(LowerCase(RedirectUrl), 'https://') <> 0 then
            BaseIndex := 9;
        if StrPos(LowerCase(RedirectUrl), 'http://') <> 0 then
            BaseIndex := 8;

        Baseurl := CopyStr(RedirectUrl, BaseIndex);
        EndBaseUrlIndex := StrPos(Baseurl, '?');

        if EndBaseUrlIndex = 0 then
            exit(RedirectUrl);

        Baseurl := CopyStr(Baseurl, 1, EndBaseUrlIndex - 1);
        exit(CopyStr(RedirectUrl, 1, BaseIndex - 1) + Baseurl);
    end;

    local procedure SignMessageContent(var RequestMessage: HttpRequestMessage)
    var
        ICertificateSigner: Interface ICertificateSigner;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        Content: Text;
        ContentSignature: Text;
    begin
        HttpContent := RequestMessage.Content();
        HttpContent.ReadAs(Content);

        ICertificateSigner := GetCertificateSigner();
        ContentSignature := ICertificateSigner.Sign(Content);

        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Digest', ContentSignature);
    end;
}