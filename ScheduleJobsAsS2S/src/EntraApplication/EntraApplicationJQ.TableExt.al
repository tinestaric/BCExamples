tableextension 50100 EntraApplicationJQ extends "AAD Application"
{
    fields
    {
        field(50100; "Use for Job Queues"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(SK1; "Use for Job Queues") { }
    }

    internal procedure GetSecret() Secret: SecretText
    begin
        if IsolatedStorage.Get(Rec."Client Id", DataScope::Company, Secret) then;
    end;

    internal procedure SetSecret(Secret: SecretText)
    begin
        IsolatedStorage.Set(Rec."Client Id", Secret, DataScope::Company);
    end;
}