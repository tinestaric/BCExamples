codeunit 50200 Ext1Subscriber
{
    var
        Log: Record Log;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsertEventTable()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnBeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertEventTable()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnAfterInsert');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnInsertRecordEvent, '', false, false)]
    local procedure OnInsertRecordEventPage()
    begin
        Log.AddLog('EXT1', 'Subscriber-Page', 'OnInsertRecord');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalInsert, '', false, false)]
    local procedure OnGlobalInsertGlobal()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnGlobalInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseInsert, '', false, false)]
    local procedure OnDatabaseInsertGlobal()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnDatabaseInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeValidateEvent, MyField2, false, false)]
    local procedure OnBeforeValidateEventTable()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnBeforeValidateEvent');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterValidateEvent, MyField2, false, false)]
    local procedure OnAfterValidateEventTable()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnAfterValidateEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnBeforeValidateEvent, MyField2, false, false)]
    local procedure OnBeforeValidateEventPage()
    begin
        Log.AddLog('EXT1', 'Subscriber-Page', 'OnBeforeValidateEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnAfterValidateEvent, MyField2, false, false)]
    local procedure OnAfterValidateEventPage()
    begin
        Log.AddLog('EXT1', 'Subscriber-Page', 'OnAfterValidateEvent');
    end;


    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeModifyEvent, '', false, false)]
    local procedure AAOnBeforeModify()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnBeforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterModifyEvent, '', false, false)]
    local procedure AAOnAfterModify()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnAfterModify');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnModifyRecordEvent, '', false, false)]
    local procedure AAOnModifyRecord()
    begin
        Log.AddLog('EXT1', 'Subscriber-Page', 'OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalModify, '', false, false)]
    local procedure AAOnGlobalModify(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnGlobalModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseModify, '', false, false)]
    local procedure AAOnDatabaseModify(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalModify, '', false, false)]
    local procedure OnAfterOnGlobalModify()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnGlobalModify');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseModify, '', false, false)]
    local procedure OnAfterOnDatabaseModify()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseModify, '', false, false)]
    local procedure OnBeforeOnDatabaseModify()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnBeforeOnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeDeleteEvent, '', false, false)]
    local procedure AAOnBeforeDelete()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterDeleteEvent, '', false, false)]
    local procedure AAOnAfterDelete()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnAfterDelete');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnDeleteRecordEvent, '', false, false)]
    local procedure AAOnDeleteRecord()
    begin
        Log.AddLog('EXT1', 'Subscriber-Page', 'OnDeleteRecordEvent');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalDelete, '', false, false)]
    local procedure AAOnGlobalDelete(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnGlobalDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseDelete, '', false, false)]
    local procedure AAOnDatabaseDelete(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnDatabaseDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalDelete, '', false, false)]
    local procedure OnAfterOnGlobalDelete()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnGlobalDelete');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseDelete, '', false, false)]
    local procedure OnAfterOnDatabaseDelete()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnDatabaseDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseDelete, '', false, false)]
    local procedure OnBeforeOnDatabaseDelete()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnBeforeOnDatabaseDelete');
    end;



    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeRenameEvent, '', false, false)]
    local procedure AAOnBeforeRename()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnBeforeRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterRenameEvent, '', false, false)]
    local procedure AAOnAfterRename()
    begin
        Log.AddLog('EXT1', 'Subscriber-Table', 'OnAfterRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalRename, '', false, false)]
    local procedure AAOnGlobalRename(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnGlobalRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseRename, '', false, false)]
    local procedure AAOnDatabaseRename(RecRef: RecordRef)
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnDatabaseRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalRename, '', false, false)]
    local procedure OnAfterOnGlobalRename()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnGlobalRename');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseRename, '', false, false)]
    local procedure OnAfterOnDatabaseRename()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnAfterOnDatabaseRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseRename, '', false, false)]
    local procedure OnBeforeOnDatabaseRename()
    begin
        Log.AddLog('EXT1', 'Subscriber-Global', 'OnBeforeOnDatabaseRename');
    end;
}