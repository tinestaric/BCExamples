codeunit 50108 WhitelistedEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text): HttpRequestMessage;
    var
        RequestMessage: HttpRequestMessage;
        ResourceURL: Text;
    begin
        ResourceURL := 'https://topsecretfunction.azurewebsites.net/api/SecureEndpointWhitelisted?code=9XhWwjsphrkfdXVekJ7byXiDsoyaOt1dLvNtNhqj6XrRAzFuDq3d1Q==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');
    end;
}