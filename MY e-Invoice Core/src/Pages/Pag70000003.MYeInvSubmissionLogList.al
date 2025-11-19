page 70000003 "MY eInv Submission Log List"
{
    ApplicationArea = All;
    Caption = 'MY eInv Submission Log List';
    PageType = List;
    SourceTable = "MY eInv Submission Log";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Cancellation Date Time"; Rec."Cancellation Date Time")
                {
                    ToolTip = 'Specifies the value of the Cancellation Date Time field.', Comment = '%';
                }
                field("Cancellation Reason"; Rec."Cancellation Reason")
                {
                    ToolTip = 'Specifies the value of the Cancellation Reason field.', Comment = '%';
                }
                field(Cancelled; Rec.Cancelled)
                {
                    ToolTip = 'Specifies the value of the Cancelled field.', Comment = '%';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the value of the Currency Code field.', Comment = '%';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ToolTip = 'Specifies the value of the Customer Name field.', Comment = '%';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the value of the Customer No. field.', Comment = '%';
                }
                field("Document Amount"; Rec."Document Amount")
                {
                    ToolTip = 'Specifies the value of the Document Amount field.', Comment = '%';
                }
                field("Document Hash"; Rec."Document Hash")
                {
                    ToolTip = 'Specifies the value of the Document Hash field.', Comment = '%';
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type';
                    Lookup = true;
                    AssistEdit = true;
                }
                field("Document Type Description"; Rec."Document Type Description")
                {
                    ToolTip = 'Specifies the value of the Document Type field.', Comment = '%';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ToolTip = 'Specifies the value of the External Document No. field.', Comment = '%';
                }
                field("Internal ID"; Rec."Internal ID")
                {
                    ToolTip = 'Specifies the value of the Internal ID field.', Comment = '%';
                }
                field("Last Status Check"; Rec."Last Status Check")
                {
                    ToolTip = 'Specifies the value of the Last Status Check field.', Comment = '%';
                }
                field("Long ID"; Rec."Long ID")
                {
                    ToolTip = 'Specifies the value of the Long ID field.', Comment = '%';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the value of the Posting Date field.', Comment = '%';
                }
                field("QR Code"; Rec."QR Code")
                {
                    ToolTip = 'Specifies the value of the QR Code field.', Comment = '%';
                }
                field("Response Text"; Rec."Response Text")
                {
                    ToolTip = 'Specifies the value of the Response Text field.', Comment = '%';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ToolTip = 'Specifies the value of the Retry Count field.', Comment = '%';
                }
                field("Signed XML"; Rec."Signed XML")
                {
                    ToolTip = 'Specifies the value of the Signed XML field.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field("Status Reason"; Rec."Status Reason")
                {
                    ToolTip = 'Specifies the value of the Status Reason field.', Comment = '%';
                }
                field("Submission Date Time"; Rec."Submission Date Time")
                {
                    ToolTip = 'Specifies the value of the Submission Date Time field.', Comment = '%';
                }
                field("Submission UID"; Rec."Submission UID")
                {
                    ToolTip = 'Specifies the value of the Submission UID field.', Comment = '%';
                }
                field(Success; Rec.Success)
                {
                    ToolTip = 'Specifies the value of the Success field.', Comment = '%';
                }
                field("Type Code"; Rec."Type Code")
                {
                    ToolTip = 'Specifies the value of the Type Code field.', Comment = '%';
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the value of the User ID field.', Comment = '%';
                }
                field("Validation URL"; Rec."Validation URL")
                {
                    ToolTip = 'Specifies the value of the Validation URL field.', Comment = '%';
                }
                field("XML Document"; Rec."XML Document")
                {
                    ToolTip = 'Specifies the value of the XML Document field.', Comment = '%';
                }
            }
        }
    }
}
