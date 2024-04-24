table 50101 SimpleEntry
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; EntryNo; Integer) { AutoIncrement = true; }
    }

    keys
    {
        key(Key1; EntryNo) { Clustered = true; }
    }
}