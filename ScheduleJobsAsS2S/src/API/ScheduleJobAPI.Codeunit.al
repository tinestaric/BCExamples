codeunit 50100 ScheduleJobAPI
{
    procedure EnqueueJob(EntryGuid: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(EntryGuid);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;
}