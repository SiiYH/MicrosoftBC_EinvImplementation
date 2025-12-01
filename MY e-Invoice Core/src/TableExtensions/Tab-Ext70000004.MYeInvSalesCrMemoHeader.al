tableextension 70000004 "MY eInv Sales Cr Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(70000001; "MY eInv Type Code"; Code[20])
        {
            Caption = 'MY eInv Type Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("E-Invoice Type"));

            trigger OnValidate()
            var
                LHDNCode: Record "MY eInv LHDN Code";
            begin
                if "MY eInv Type Code" <> '' then begin
                    LHDNCode.Get(LHDNCode."Code Type"::"E-Invoice Type", "MY eInv Type Code");
                    "MY eInv Type Description" := LHDNCode.Description;
                end else
                    "MY eInv Type Description" := '';
            end;
        }

        field(70000002; "MY eInv Type Description"; Text[100])
        {
            Caption = 'MY eInv Type Description';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000003; "MY eInv Submission UID"; Text[50])
        {
            Caption = 'MY eInv Submission UID';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000004; "MY eInv Document Hash"; Text[100])
        {
            Caption = 'MY eInv Document Hash';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000005; "MY eInv Submission Date"; Date)
        {
            Caption = 'MY eInv Submission Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000006; "MY eInv Status"; Enum "MY eInv Status")
        {
            Caption = 'MY eInv Status';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000007; "MY eInv Long ID"; Text[100])
        {
            Caption = 'MY eInv Long ID';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000008; "MY eInv Validation URL"; Text[250])
        {
            Caption = 'MY eInv Validation URL';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000009; "MY eInv QR Code"; Blob)
        {
            Caption = 'MY eInv QR Code';
            DataClassification = CustomerContent;
            SubType = Bitmap;
        }

        field(70000010; "MY eInv Submitted"; Boolean)
        {
            Caption = 'MY eInv Submitted';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000011; "MY eInv Cancelled"; Boolean)
        {
            Caption = 'MY eInv Cancelled';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70000012; "MY eInv Error Message"; Text[250])
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // Helper Procedures
    // ═════════════════════════════════════════════════════════════════

    procedure SubmitToMyInvois()
    var
        DocumentProcessor: Codeunit "MY eInv Document Processor";
    begin
        DocumentProcessor.ProcessSalesCreditMemo(Rec);
    end;

    procedure ShowSubmissionLog()
    var
        SubmissionLog: Record "MY eInv Submission Log";
    begin
        SubmissionLog.SetFilter("Document Type", '%1|%2', '01', '03');
        SubmissionLog.SetRange("Document No.", "No.");
        Page.Run(Page::"MY eInv Submission Log List", SubmissionLog);
    end;

    procedure CheckStatusFromAPI()
    var
        Setup: Record "MY eInv Setup";
        Submission: Codeunit "MY eInv Submission";
        StatusText: Text;
        StatusReasonText: Text;
    begin
        if "MY eInv Submission UID" = '' then
            Error('This invoice has not been submitted to MyInvois yet.');

        Setup.Get();

        if Submission.CheckDocumentStatus("MY eInv Submission UID", Setup, StatusText, StatusReasonText) then begin
            // Update status
            case StatusText of
                'Valid':
                    "MY eInv Status" := "MY eInv Status"::Valid;
                'Submitted':
                    "MY eInv Status" := "MY eInv Status"::Submitted;
                'Cancelled':
                    begin
                        "MY eInv Status" := "MY eInv Status"::Cancelled;
                        "MY eInv Cancelled" := true;
                    end;
                'Rejected':
                    "MY eInv Status" := "MY eInv Status"::Rejected;
            end;

            Modify();
            Message('Status updated: %1\%2', StatusText, StatusReasonText);
        end else
            Error('Failed to retrieve document status from MyInvois API.');
    end;

    //comment for 01 Dec 25
    /* procedure CancelInMyInvois()
    var
        Setup: Record "MY eInv Setup";
        Submission: Codeunit "MY eInv Submission";
        CancellationReason: Text;
        Selection: Integer;
    begin
        if "MY eInv Submission UID" = '' then
            Error('This invoice has not been submitted to MyInvois yet.');

        if "MY eInv Cancelled" then
            Error('This invoice is already cancelled in MyInvois.');

        // Prompt for cancellation reason
        CancellationReason := '';

        // Use StrMenu for predefined reasons or plain assignment for free text
        Selection := StrMenu(
        'Wrong Invoice Details,Duplicate Invoice,Customer Request,Pricing Error,Data Entry Error,Other',
        1,
        'Select cancellation reason:');

        case Selection of
            0:
                exit; // User cancelled
            1:
                CancellationReason := 'Wrong Invoice Details';
            2:
                CancellationReason := 'Duplicate Invoice';
            3:
                CancellationReason := 'Customer Request';
            4:
                CancellationReason := 'Pricing Error';
            5:
                CancellationReason := 'Data Entry Error';
            6:
                CancellationReason := 'Other';
        end;

        if CancellationReason = '' then
            Error('Cancellation reason is required.');

        Setup.Get();

        if Submission.CancelDocument("MY eInv Submission UID", CancellationReason, Setup) then begin
            "MY eInv Status" := "MY eInv Status"::Cancelled;
            "MY eInv Cancelled" := true;
            Modify();
            Message('Invoice cancelled successfully in MyInvois.');
        end else
            Error('Failed to cancel invoice in MyInvois.');
    end; */

    procedure GetInvoiceTypeFromLHDN(): Code[20]
    var
        LHDNCode: Record "MY eInv LHDN Code";
    begin
        // Default invoice type based on document characteristics
        // You can customize this logic based on your business rules

        // Standard invoice
        if "MY eInv Type Code" <> '' then
            exit("MY eInv Type Code");

        // Default to standard invoice (01)
        LHDNCode.SetRange("Code Type", LHDNCode."Code Type"::"E-Invoice Type");
        LHDNCode.SetRange(Code, '01');
        if LHDNCode.FindFirst() then
            exit('01');

        exit('01');
    end;
}
