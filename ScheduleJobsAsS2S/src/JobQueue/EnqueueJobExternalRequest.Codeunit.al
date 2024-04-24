codeunit 50101 EnqueueJobExternalRequest
{
    Access = Internal;

    var
        _ServiceNameLbl: Label 'ScheduleJobAPI';
        _APINameLbl: Label 'EnqueueJob';

    internal procedure EnqueueJob(EntryGuid: Guid)
    var
        AADApplication: Record "AAD Application";
        ScheduledJobsPerApp: Query ScheduledJobsPerApp;
    begin
        // Check if the web service is created and published
        CheckWebService();

        AADApplication := ScheduledJobsPerApp.FindLeastLoadedApp();
        SendRequest(EntryGuid, GetToken(AADApplication));
    end;

    local procedure CheckWebService()
    var
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(5, Codeunit::ScheduleJobAPI, _ServiceNameLbl, true);
    end;

    procedure GetToken(AADApp: Record "AAD Application") AccessToken: SecretText;
    var
        Client: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        JsonToken: JsonToken;
        TokenURLTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        ResponseBody: Text;
        ContentText: SecretText;
    begin
        Request.SetRequestUri(StrSubstNo(TokenURLTok, GetTenantGuid()));
        Request.Method('POST');

        // Create the content for S2S token request
        ContentText := SecretStrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&scope=https://api.businesscentral.dynamics.com/.default', Format(AADApp."Client Id"), AADApp.GetSecret());
        HttpContent.WriteFrom(ContentText);

        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        Request.Content(HttpContent);

        Client.Send(Request, Response);

        Response.Content.ReadAs(ResponseBody);

        // Parse the response to get the access token
        if Response.IsSuccessStatusCode then begin
            JsonToken.ReadFrom(ResponseBody);
            AccessToken := GetValueAsText(JsonToken, 'access_token');
        end else
            Error('%1 %2', Response.ReasonPhrase, ResponseBody);
    end;

    local procedure GetTenantGuid(): Text
    var
        URLList: List of [Text];
    begin
        URLList := GetUrl(ClientType::Web).Split('/');
        exit(URLList.Get(4));
    end;

    local procedure SelectJsonToken(JObject: JsonObject; Path: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.SelectToken(Path, JToken) then
            if not JToken.AsValue().IsNull() then
                exit(JToken.AsValue().AsText());
    end;

    local procedure GetValueAsText(JToken: JsonToken; ParamString: Text): Text
    var
        JObject: JsonObject;
    begin
        JObject := JToken.AsObject();
        exit(SelectJsonToken(JObject, ParamString));
    end;

    local procedure SendRequest(EntryGuid: Guid; AccessToken: SecretText)
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        RequestMessage: HttpRequestMessage;
        Headers: HttpHeaders;
        StatusCode: Integer;
        IsSuccessful: Boolean;
        ContentText: Text;
        ResponseBody: Text;
    begin
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));
        RequestMessage.SetRequestUri(GetRequestUrl());
        RequestMessage.Method('POST');

        ContentText := '{"entryGuid": "' + Format(EntryGuid) + '"}';
        HttpContent.WriteFrom(ContentText);

        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Content(HttpContent);

        IsSuccessful := Client.Send(RequestMessage, ResponseMessage);

        if not IsSuccessful then
            Error('An API call with the provided header has failed.');

        ResponseMessage.Content.ReadAs(ResponseBody);

        if not ResponseMessage.IsSuccessStatusCode() then begin
            StatusCode := ResponseMessage.HttpStatusCode();
            Error('The request has failed with status code: %1 \ and error message %2', Format(StatusCode), ResponseBody);
        end;
    end;

    local procedure GetRequestUrl(): Text
    var
        EnvInfo: Codeunit "Environment Information";
    begin
        exit('https://api.businesscentral.dynamics.com/v2.0/' + EnvInfo.GetEnvironmentName() + '/ODataV4/' + _ServiceNameLbl + '_' + _APINameLbl + '?company=' + CompanyProperty.UrlName());
    end;
}