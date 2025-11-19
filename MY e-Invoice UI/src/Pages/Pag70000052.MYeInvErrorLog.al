page 70000052 "MY eInv Error Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MY eInv Error Log";
    Caption = 'MY eInv Error Log';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Error DateTime"; Rec."Error DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the error occurred.';
                }
                field("Error Type"; Rec."Error Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of error.';
                }
                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP status code.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("Submission UID"; Rec."Submission UID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the submission UID.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who encountered the error.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewRequestBody)
            {
                ApplicationArea = All;
                Caption = 'View Request Body';
                Image = View;
                ToolTip = 'View the full request body.';

                trigger OnAction()
                var
                    RequestText: Text;
                begin
                    RequestText := Rec.GetRequestBody();
                    if RequestText <> '' then
                        Message(RequestText)
                    else
                        Message('No request body available.');
                end;
            }
            action(ViewResponseBody)
            {
                ApplicationArea = All;
                Caption = 'View Response Body';
                Image = View;
                ToolTip = 'View the full response body.';

                trigger OnAction()
                var
                    ResponseText: Text;
                begin
                    ResponseText := Rec.GetResponseBody();
                    if ResponseText <> '' then
                        Message(ResponseText)
                    else
                        Message('No response body available.');
                end;
            }
            action(CopyErrorMessage)
            {
                ApplicationArea = All;
                Caption = 'Copy Error Message';
                Image = Copy;
                ToolTip = 'Copy the error message to clipboard.';

                trigger OnAction()
                begin
                    Message('Error Message copied:\%1', Rec."Error Message");
                end;
            }
            action(DeleteOldLogs)
            {
                ApplicationArea = All;
                Caption = 'Delete Old Logs';
                Image = Delete;
                ToolTip = 'Delete error logs older than 90 days.';

                trigger OnAction()
                var
                    ErrorLog: Record "MY eInv Error Log";
                    DeletedCount: Integer;
                begin
                    if not Confirm('Delete all error logs older than 90 days?', false) then
                        exit;

                    ErrorLog.SetFilter("Error DateTime", '<%1', CreateDateTime(CalcDate('<-90D>', Today), 0T));
                    DeletedCount := ErrorLog.Count;
                    ErrorLog.DeleteAll();

                    Message('%1 error log(s) deleted.', DeletedCount);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ViewRequestBody_Promoted; ViewRequestBody) { }
                actionref(ViewResponseBody_Promoted; ViewResponseBody) { }
                actionref(DeleteOldLogs_Promoted; DeleteOldLogs) { }
            }
        }
    }
}
