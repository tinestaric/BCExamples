page 50100 "OAuth2 Control Add-In"
{
    PageType = NavigatePage;
    Caption = 'Waiting for a response. Do not close this page.';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;


    layout
    {
        area(Content)
        {
            group(BodyGroup)
            {
                InstructionalText = 'A sign in window is open. To continue, pick the account you want to use and accept the conditions. This message will close when you are done.';
                ShowCaption = false;
            }
            usercontrol(OAuthIntegration; OAuthControlAddIn)
            {
                ApplicationArea = All;
                trigger AuthorizationCodeRetrieved(code: Text)
                var
                    Properties: Dictionary of [Text, Text];
                begin
                    OAuth2Impl.GetOAuthProperties(code, Properties);

                    AuthCode := Properties.Get('code');

                    if State = '' then
                        AuthError += NoStateErr
                    else
                        if Properties.Get('state') <> State then
                            AuthError += NotMatchingStateErr;

                    CurrPage.Close();
                end;

                trigger AuthorizationErrorOccurred(error: Text; desc: Text);
                begin
                    AuthError := StrSubstNo(AuthCodeErrorLbl, error, desc);
                    CurrPage.Close();
                end;

                trigger ControlAddInReady();
                begin
                    CurrPage.OAuthIntegration.StartAuthorization(OAuthRequestUrl);
                end;
            }
        }
    }

    var

        OAuth2Impl: Codeunit "OAuth2 Impl";
        OAuthRequestUrl: Text;
        State: Text;
        AuthCode: Text;
        AuthError: Text;
        NoStateErr: Label 'No state has been returned.';
        NotMatchingStateErr: Label 'The state parameter value does not match.';
        AuthCodeErrorLbl: Label 'Error: %1, description: %2', Comment = '%1 = The authorization error message, %2 = The authorization error description';

    procedure SetOAuth2Properties(AuthRequestUrl: Text; AuthInitialState: Text)
    begin
        OAuthRequestUrl := AuthRequestUrl;
        State := AuthInitialState;
    end;

    procedure GetAuthCode(): Text
    begin
        exit(AuthCode);
    end;

    procedure GetAuthError(): Text
    begin
        exit(AuthError);
    end;
}