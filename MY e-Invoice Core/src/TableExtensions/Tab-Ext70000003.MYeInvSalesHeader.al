tableextension 70000003 "MY eInv Sales Header" extends "Sales Header"
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
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70000013; "MY eInv Submit On Post"; Boolean)
        {
            Caption = 'Submit to MyInvois on Post';
            DataClassification = CustomerContent;
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // Helper Procedures
    // ═════════════════════════════════════════════════════════════════

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
