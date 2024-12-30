codeunit 50100 Subscriber
{
    var
        Log: Record Log;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", GetDatabaseTableTriggerSetup, '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableID = Database::MyCustomer then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
            OnDatabaseDelete := true;
            OnDatabaseRename := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterGetDatabaseTableTriggerSetup, '', false, false)]
    local procedure OnAfterGetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableID = Database::MyCustomer then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
            OnDatabaseDelete := true;
            OnDatabaseRename := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeInsertEvent, '', false, false)]
    local procedure AAOnBeforeInsert()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnBeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterInsertEvent, '', false, false)]
    local procedure AAOnAfterInsert()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnAfterInsert');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnInsertRecordEvent, '', false, false)]
    local procedure AAOnInsertRecord()
    begin
        Log.AddLog('Core', 'Subscriber-Page', 'OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalInsert, '', false, false)]
    local procedure AAOnGlobalInsert(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnGlobalInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseInsert, '', false, false)]
    local procedure AAOnDatabaseInsert(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnDatabaseInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalInsert, '', false, false)]
    local procedure OnAfterOnGlobalInsert()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnGlobalInsert');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseInsert, '', false, false)]
    local procedure OnAfterOnDatabaseInsert()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnDatabaseInsert');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseInsert, '', false, false)]
    local procedure OnBeforeOnDatabaseInsert()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnBeforeOnDatabaseInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeValidateEvent, MyField2, false, false)]
    local procedure OnBeforeValidateEvent()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnBeforeValidateEvent');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterValidateEvent, MyField2, false, false)]
    local procedure OnAfterValidateEvent()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnAfterValidateEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnBeforeValidateEvent, MyField2, false, false)]
    local procedure OnBeforeValidateEvent2()
    begin
        Log.AddLog('Core', 'Subscriber-Page', 'OnBeforeValidateEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnAfterValidateEvent, MyField2, false, false)]
    local procedure OnAfterValidateEvent2()
    begin
        Log.AddLog('Core', 'Subscriber-Page', 'OnAfterValidateEvent');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeModifyEvent, '', false, false)]
    local procedure AAOnBeforeModify()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnBeforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterModifyEvent, '', false, false)]
    local procedure AAOnAfterModify()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnAfterModify');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnModifyRecordEvent, '', false, false)]
    local procedure AAOnModifyRecord()
    begin
        Log.AddLog('Core', 'Subscriber-Page', 'OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalModify, '', false, false)]
    local procedure AAOnGlobalModify(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnGlobalModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseModify, '', false, false)]
    local procedure AAOnDatabaseModify(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalModify, '', false, false)]
    local procedure OnAfterOnGlobalModify()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnGlobalModify');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseModify, '', false, false)]
    local procedure OnAfterOnDatabaseModify()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseModify, '', false, false)]
    local procedure OnBeforeOnDatabaseModify()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnBeforeOnDatabaseModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeDeleteEvent, '', false, false)]
    local procedure AAOnBeforeDelete()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterDeleteEvent, '', false, false)]
    local procedure AAOnAfterDelete()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnAfterDelete');
    end;

    [EventSubscriber(ObjectType::Page, Page::MyCustomer, OnDeleteRecordEvent, '', false, false)]
    local procedure AAOnDeleteRecord()
    begin
        Log.AddLog('Core', 'Subscriber-Page', 'OnDeleteRecordEvent');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalDelete, '', false, false)]
    local procedure AAOnGlobalDelete(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnGlobalDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseDelete, '', false, false)]
    local procedure AAOnDatabaseDelete(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnDatabaseDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalDelete, '', false, false)]
    local procedure OnAfterOnGlobalDelete()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnGlobalDelete');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseDelete, '', false, false)]
    local procedure OnAfterOnDatabaseDelete()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnDatabaseDelete');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseDelete, '', false, false)]
    local procedure OnBeforeOnDatabaseDelete()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnBeforeOnDatabaseDelete');
    end;


    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnBeforeRenameEvent, '', false, false)]
    local procedure AAOnBeforeRename()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnBeforeRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::MyCustomer, OnAfterRenameEvent, '', false, false)]
    local procedure AAOnAfterRename()
    begin
        Log.AddLog('Core', 'Subscriber-Table', 'OnAfterRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnGlobalRename, '', false, false)]
    local procedure AAOnGlobalRename(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnGlobalRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", OnDatabaseRename, '', false, false)]
    local procedure AAOnDatabaseRename(RecRef: RecordRef)
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnDatabaseRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnGlobalRename, '', false, false)]
    local procedure OnAfterOnGlobalRename()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnGlobalRename');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterOnDatabaseRename, '', false, false)]
    local procedure OnAfterOnDatabaseRename()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnAfterOnDatabaseRename');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnBeforeOnDatabaseRename, '', false, false)]
    local procedure OnBeforeOnDatabaseRename()
    begin
        Log.AddLog('Core', 'Subscriber-Global', 'OnBeforeOnDatabaseRename');
    end;
}