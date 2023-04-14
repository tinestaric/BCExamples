codeunit 50103 FacebookIdP implements IIdentityProvider
{
    [NonDebuggable]
    procedure GetTokenWithAuthCode(): Text;
    var
        OAuth2ControlAddIn: Page "OAuth2 Control Add-In";
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        AuthorityUrlLbl: Label 'https://www.facebook.com/v15.0/dialog/oauth?client_id=%1&redirect_uri=%2&state=%3', Comment = '%1 - ClientId, %2 - Redirect Uri, %3 - State', Locked = true;
        TokenUrlLbl: Label 'https://graph.facebook.com/v15.0/oauth/access_token?client_id=%1&redirect_uri=%2&client_secret=%3&code=%4', Comment = '%1 - Client Id, %2 - Redirect Uri, %3 - Client Secret, %4 - Auth Code', Locked = true;
        AuthCode: Text;
        AuthCodeErr: Text;
        OAuthAuthorityURL: Text;
        ResourceURL: Text;
        ResponseBody: Text;
        State: Text;
    begin
        State := Format(CreateGuid());

        OAuthAuthorityURL := StrSubstNo(AuthorityUrlLbl, GetClientId(), GetRedirectUrl(), State);

        OAuth2ControlAddIn.SetOAuth2Properties(OAuthAuthorityURL, State);
        OAuth2ControlAddIn.RunModal();

        AuthCode := OAuth2ControlAddIn.GetAuthCode();
        AuthCodeErr := OAuth2ControlAddIn.GetAuthError();

        if AuthCodeErr <> '' then
            Error(AuthCodeErr);

        ResourceURL := StrSubstNo(TokenUrlLbl, GetClientId(), GetRedirectUrl(), GetClientSecret(), AuthCode);

        Client.Get(ResourceURL, ResponseMessage);

        if ResponseMessage.IsSuccessStatusCode then begin
            ResponseMessage.Content.ReadAs(ResponseBody);
            Message(ResponseBody); //TODO: Parse out a token
        end else begin
            ResponseMessage.Content.ReadAs(ResponseBody);
            Error('%1 %2', ResponseMessage.ReasonPhrase, ResponseBody);
        end;
    end;

    procedure GetTokenWithRefreshToken(): Text;
    begin

    end;

    procedure GetTokenWithClientCredentials(): Text;
    begin

    end;

    local procedure GetClientId(): Text
    begin
        EXIT('556109569412929')
    end;

    local procedure GetRedirectUrl(): Text
    var
        Environment: Codeunit "Environment Information";
    begin
        if Environment.IsSaaSInfrastructure() then
            exit('https://businesscentral.dynamics.com/OAuthLanding.htm')
        else
            exit('https://cloud-bc-dev.northeurope.cloudapp.azure.com/BC/');
    end;

    [NonDebuggable]
    local procedure GetClientSecret() Secret: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('FBSecret', Secret);
    end;
}