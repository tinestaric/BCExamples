pageextension 50101 JobQueueEntryCard extends "Job Queue Entry Card"
{
    actions
    {
        addfirst(processing)
        {
            action(ScheduleAsSystem)
            {
                ApplicationArea = All;
                Caption = 'Schedule Job as System';
                ToolTip = 'Schedules the job to run as the system user.';
                Image = New;
                Promoted = true;

                Trigger OnAction()
                var
                    EnqueueJobExternalRequest: Codeunit EnqueueJobExternalRequest;
                begin
                    EnqueueJobExternalRequest.EnqueueJob(Rec.ID);
                end;
            }
        }
    }
}