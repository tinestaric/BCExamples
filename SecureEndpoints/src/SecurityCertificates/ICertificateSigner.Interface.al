interface ICertificateSigner
{
    procedure Sign(DataInStream: InStream) Base64Signature: Text;
    procedure Sign(Data: Text) Base64Signature: Text;
}