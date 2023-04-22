codeunit 50107 MyCertificateSigner implements ICertificateSigner
{
    procedure Sign(DataInStream: InStream) Base64Signature: Text
    var
        Base64: Codeunit "Base64 Convert";
        CryptographyManagement: Codeunit "Cryptography Management";
        SignatureKey: Codeunit "Signature Key";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        SignatureOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(SignatureOutStream);

        SignatureKey.FromBase64String(GetCertificate(), '', true);
        CryptographyManagement.SignData(DataInStream, SignatureKey, "Hash Algorithm"::SHA256, SignatureOutStream);

        TempBlob.CreateInStream(InStr);
        Base64Signature := Base64.ToBase64(InStr);
    end;

    procedure Sign(Data: Text) Base64Signature: Text
    var
        Base64: Codeunit "Base64 Convert";
        CryptographyManagement: Codeunit "Cryptography Management";
        SignatureKey: Codeunit "Signature Key";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        SignatureOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(SignatureOutStream);

        SignatureKey.FromBase64String(GetCertificate(), '', true);
        CryptographyManagement.SignData(Data, SignatureKey, "Hash Algorithm"::SHA256, SignatureOutStream);

        TempBlob.CreateInStream(InStr);
        Base64Signature := Base64.ToBase64(InStr);
    end;

    local procedure GetCertificate() SecretValue: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('SelfSigned-SigningCert', SecretValue);

        exit(SecretValue);
    end;
}