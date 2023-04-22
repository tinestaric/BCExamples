codeunit 50101 EndpointManagement
{

    // [NonDebuggable]
    internal procedure GetTopSecretInfo(
        ITokenGetter: Interface ITokenGetter;
        IEndpoint: Interface IEndpoint
    ) ResponseMessage: HttpResponseMessage
    var
        Token: Text;
    begin
        Token := ITokenGetter.GetToken();

        ResponseMessage := CallEndpoint(IEndpoint, Token);
    end;

    local procedure CallEndpoint(IEndpoint: Interface IEndpoint; Token: Text) ResponseMessage: HttpResponseMessage
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
    begin
        RequestMessage := IEndpoint.GetRequestMessage(Token, '');

        Client.Send(RequestMessage, ResponseMessage);
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
}