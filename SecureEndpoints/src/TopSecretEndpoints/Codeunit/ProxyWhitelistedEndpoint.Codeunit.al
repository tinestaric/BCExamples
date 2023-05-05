codeunit 50109 ProxyWhitelistedEndpoint implements IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text) RequestMessage: HttpRequestMessage;
    var
        ResourceURL: Text;
    begin
        ResourceURL := 'https://ipwhitelister.azurewebsites.net/api/ForwardRequest?code=FjVnJssFctrMbUZGWqBxCBfZmRqxFNwF27ZAXA_xmeRCAzFuo1mYyg==';

        RequestMessage.SetRequestUri(ResourceURL);
        RequestMessage.Method('GET');
    end;
}