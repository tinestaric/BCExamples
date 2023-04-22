codeunit 50102 AADAuthCode implements ITokenGetter
{
    var
        OAuth2: Codeunit OAuth2;
        EndpointManagement: Codeunit EndpointManagement;

    procedure GetToken() AccessToken: Text;
    var
        Error: Text;
    begin
        OAuth2.AcquireTokenByAuthorizationCode(
            GetClientId(),
            GetClientSecret(),
            GetAuthorityURL(),
            EndpointManagement.GetRedirectURL(),
            GetScope(),
            "Prompt Interaction"::Login,
            AccessToken,
            Error
        );

        if Error <> '' then
            Error(Error);
    end;

    local procedure GetClientId(): Text
    begin
        exit('79b345f6-8ab0-4cae-8305-65671c04199d');
    end;

    local procedure GetClientSecret() Secret: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('AADAzFunct-Secret', Secret);
    end;

    local procedure GetScope() Scopes: List of [Text]
    begin
        Scopes.Add('User.Read');
    end;

    local procedure GetAuthorityURL(): Text
    begin
        exit('https://login.microsoftonline.com/b65e6ce1-543b-4eb3-8b2a-5e3e0f086e36/oauth2/v2.0/authorize');
    end;
}