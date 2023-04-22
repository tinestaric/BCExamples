enum 50101 IdentityProvider implements ITokenGetter
{
    Extensible = true;

    value(0; None)
    {
        Implementation = ITokenGetter = TokenGetterNone;
    }

    value(1; AADAuthCode)
    {
        Caption = 'Azure AD - Auth Code';
        Implementation = ITokenGetter = AADAuthCode;
    }
    value(2; AADS2S)
    {
        Caption = 'Azure AD - S2S';
        Implementation = ITokenGetter = AADS2S;
    }
    value(3; Facebook)
    {
        Implementation = ITokenGetter = FacebookAuthCode;
    }
}