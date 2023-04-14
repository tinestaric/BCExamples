codeunit 50100 "OAuth2 Impl"
{
    procedure GetOAuthProperties(AuthorizationCode: Text; var Properties: Dictionary of [Text, Text])
    var
        Uri: Codeunit Uri;
        Property: Text;
        KeyValuePair: List of [Text];
    begin
        if AuthorizationCode = '' then
            exit;

        Uri.Init('https://client.example.com/callback?' + AuthorizationCode);
        AuthorizationCode := Uri.GetQuery().TrimStart('?');

        foreach Property in AuthorizationCode.Split('&') do begin
            KeyValuePair := Property.Split('=');
            Properties.Add(KeyValuePair.Get(1), KeyValuePair.Get(2));
        end;
    end;
}