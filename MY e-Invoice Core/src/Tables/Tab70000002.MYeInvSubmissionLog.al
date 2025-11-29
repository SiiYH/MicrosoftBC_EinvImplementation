table 70000002 "MY eInv Submission Log"
{
    Caption = 'MY eInv Submission Log';
    DataClassification = CustomerContent;
    LookupPageId = "MY eInv Submission Log List";
    DrillDownPageId = "MY eInv Submission Log List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }

        field(2; "Document Type"; Code[20])
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;

            TableRelation = "MY eInv LHDN Code".Code
        WHERE("Code Type" = CONST("E-Invoice Type"));
        }


        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }


        field(4; "Submission Date Time"; DateTime)
        {
            Caption = 'Submission Date Time';
            DataClassification = CustomerContent;
        }

        field(5; "Submission UID"; Text[50])
        {
            Caption = 'Submission UID';
            DataClassification = CustomerContent;
        }

        field(6; "Document Hash"; Text[100])
        {
            Caption = 'Document Hash';
            DataClassification = CustomerContent;
        }

        field(7; Success; Boolean)
        {
            Caption = 'Success';
            DataClassification = CustomerContent;
        }

        field(8; "Response Text"; Text[2048])
        {
            Caption = 'Response Text';
            DataClassification = CustomerContent;
        }

        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
        }

        field(10; "Status"; Enum "MY eInv Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }


        field(11; "Status Reason"; Text[250])
        {
            Caption = 'Status Reason';
            DataClassification = CustomerContent;
        }

        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }

        field(13; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            DataClassification = CustomerContent;
        }

        field(14; "Document Amount"; Decimal)
        {
            Caption = 'Document Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }

        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }

        field(16; "Last Status Check"; DateTime)
        {
            Caption = 'Last Status Check';
            DataClassification = CustomerContent;
        }

        field(17; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
        }

        field(18; "Cancelled"; Boolean)
        {
            Caption = 'Cancelled';
            DataClassification = CustomerContent;
        }

        field(19; "Cancellation Date Time"; DateTime)
        {
            Caption = 'Cancellation Date Time';
            DataClassification = CustomerContent;
        }

        field(20; "Cancellation Reason"; Text[250])
        {
            Caption = 'Cancellation Reason';
            DataClassification = CustomerContent;
        }

        field(21; "XML Document"; Blob)
        {
            Caption = 'XML Document';
            DataClassification = CustomerContent;
        }

        field(22; "Signed XML"; Blob)
        {
            Caption = 'Signed XML';
            DataClassification = CustomerContent;
        }

        field(23; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }

        field(24; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }

        field(25; "QR Code"; Blob)
        {
            Caption = 'QR Code';
            DataClassification = CustomerContent;
            SubType = Bitmap;
        }

        field(26; "Validation URL"; Text[250])
        {
            Caption = 'Validation URL';
            DataClassification = CustomerContent;
        }

        field(27; "Long ID"; Text[100])
        {
            Caption = 'Long ID';
            DataClassification = CustomerContent;
        }

        field(28; "Internal ID"; Text[100])
        {
            Caption = 'Internal ID';
            DataClassification = CustomerContent;
        }

        field(29; "Type Code"; Code[10])
        {
            Caption = 'Type Code';
            DataClassification = CustomerContent;
        }
        field(30; "Document Type Description"; Text[250])
        {
            Caption = 'Document Type';
            CalcFormula = Lookup("MY eInv LHDN Code".Description WHERE(Code = FIELD("Document Type"),
                          "Code Type" = CONST("E-Invoice Type")));
            FieldClass = FlowField;
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DocumentKey; "Document Type", "Document No.")
        {
        }
        key(SubmissionUID; "Submission UID")
        {
        }
        key(DateTime; "Submission Date Time")
        {
        }
        key(Status; Success, "Status")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Document Type", "Document No.", "Submission Date Time", Success)
        {
        }
    }

    trigger OnInsert()
    begin
        if "Submission Date Time" = 0DT then
            "Submission Date Time" := CurrentDateTime;

        if "User ID" = '' then
            "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
    end;

    // ═════════════════════════════════════════════════════════════════
    // Helper Procedures
    // ═════════════════════════════════════════════════════════════════

    procedure SetXMLDocument(XMLText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("XML Document");
        "XML Document".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);
        Modify();
    end;

    procedure GetXMLDocument(): Text
    var
        InStream: InStream;
        XMLText: Text;
    begin
        CalcFields("XML Document");
        if not "XML Document".HasValue then
            exit('');

        "XML Document".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(XMLText);
        exit(XMLText);
    end;

    procedure SetSignedXML(XMLText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Signed XML");
        "Signed XML".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);
        Modify();
    end;

    procedure GetSignedXML(): Text
    var
        InStream: InStream;
        XMLText: Text;
    begin
        CalcFields("Signed XML");
        if not "Signed XML".HasValue then
            exit('');

        "Signed XML".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(XMLText);
        exit(XMLText);
    end;

    procedure ShowXMLDocument()
    var
        XMLText: Text;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        XMLText := GetXMLDocument();
        if XMLText = '' then begin
            Message('No XML document available.');
            exit;
        end;

        // Display XML in a message or download
        Message(XMLText);
    end;

    procedure DownloadXMLDocument()
    var
        XMLText: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
    begin
        XMLText := GetXMLDocument();
        if XMLText = '' then begin
            Message('No XML document available.');
            exit;
        end;

        // Create temp blob
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        // Download file
        FileName := StrSubstNo('%1_%2.xml', "Document No.", Format("Submission Date Time", 0, '<Year4><Month,2><Day,2>_<Hours24><Minutes,2><Seconds,2>'));
        DownloadFromStream(InStream, 'Download XML', '', 'XML Files (*.xml)|*.xml', FileName);
    end;

    procedure DownloadSignedXML()
    var
        XMLText: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
    begin
        XMLText := GetSignedXML();
        if XMLText = '' then begin
            Message('No signed XML document available.');
            exit;
        end;

        // Create temp blob
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        // Download file
        FileName := StrSubstNo('%1_%2_signed.xml', "Document No.", Format("Submission Date Time", 0, '<Year4><Month,2><Day,2>_<Hours24><Minutes,2><Seconds,2>'));
        DownloadFromStream(InStream, 'Download Signed XML', '', 'XML Files (*.xml)|*.xml', FileName);
    end;

    procedure UpdateStatusFromAPI()
    var
        Setup: Record "MY eInv Setup";
        Submission: Codeunit "MY eInv Submission";
        StatusText: Text;
        StatusReasonText: Text;
    begin
        if "Submission UID" = '' then begin
            Message('No submission UID available to check status.');
            exit;
        end;

        Setup.Get();

        if Submission.CheckDocumentStatus("Submission UID", Setup, StatusText, StatusReasonText) then begin
            "Last Status Check" := CurrentDateTime;
            "Status Reason" := CopyStr(StatusReasonText, 1, MaxStrLen("Status Reason"));

            // Map status text to enum
            case StatusText of
                'Valid':
                    "Status" := "Status"::Valid;
                'Submitted':
                    "Status" := "Status"::Submitted;
                'Cancelled':
                    begin
                        "Status" := "Status"::Cancelled;
                        Cancelled := true;
                    end;
                'Rejected':
                    "Status" := "Status"::Rejected;
            end;

            Modify();
            Message('Status updated successfully: %1', StatusText);
        end else
            Error('Failed to retrieve document status from API.');
    end;

    procedure Resubmit()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Submission: Codeunit "MY eInv Submission";
        XMLText: Text;
        ErrorMsg: Text;
    begin
        XMLText := GetSignedXML();
        if XMLText = '' then
            XMLText := GetXMLDocument();

        if XMLText = '' then
            Error('No XML document available to resubmit.');

        // Sales Invoice: 01 (Invoice), 03 (Debit Note)
        if "Document Type" in ['01', '03'] then begin
            if not SalesInvoiceHeader.Get("Document No.") then
                Error('Sales Invoice %1 not found.', "Document No.");

            ErrorMsg := '';
            Submission.SubmitInvoice(XMLText, SalesInvoiceHeader, ErrorMsg);
        end
        // Sales Credit Memo: 02 (Credit Note), 04 (Refund Note)
        else if "Document Type" in ['02', '04'] then begin
            if not SalesCrMemoHeader.Get("Document No.") then
                Error('Sales Credit Memo %1 not found.', "Document No.");

            // You'd need to add a similar SubmitDocument procedure for credit memos
            Error('Credit memo resubmission not implemented yet.');
        end
        // Purchase Invoice: 11 (Self-billed Invoice), 13 (Self-billed Debit Note)
        else if "Document Type" in ['11', '13'] then begin
            if not PurchInvHeader.Get("Document No.") then
                Error('Purchase Invoice %1 not found.', "Document No.");

            Error('Self-billed invoice resubmission not implemented yet.');
        end
        // Purchase Credit Memo: 12 (Self-billed Credit Note), 14 (Self-billed Refund Note)
        else if "Document Type" in ['12', '14'] then begin
            if not PurchCrMemoHdr.Get("Document No.") then
                Error('Purchase Credit Memo %1 not found.', "Document No.");

            Error('Self-billed credit memo resubmission not implemented yet.');
        end
        else
            Error('Unknown or unsupported document type: %1', "Document Type");

        "Retry Count" += 1;
        Modify();
    end;
}
