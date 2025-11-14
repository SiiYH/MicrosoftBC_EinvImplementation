/// <summary>
/// API call logging for debugging and audit
/// </summary>
table 7000005 "e-Invoice API Log EINV"
{
    Caption = 'e-Invoice API Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Log Type"; Enum "API Log Type EINV")
        {
            Caption = 'Log Type';
            DataClassification = CustomerContent;
        }

        field(10; "Called At"; DateTime)
        {
            Caption = 'Called At';
            DataClassification = CustomerContent;
        }

        field(11; "Called By"; Code[50])
        {
            Caption = 'Called By';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(12; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            DataClassification = CustomerContent;
        }

        field(20; "Endpoint Name"; Text[100])
        {
            Caption = 'Endpoint Name';
            DataClassification = CustomerContent;
        }

        field(21; "HTTP Method"; Text[10])
        {
            Caption = 'HTTP Method';
            DataClassification = CustomerContent;
        }

        field(22; "Request URL"; Text[250])
        {
            Caption = 'Request URL';
            DataClassification = CustomerContent;
        }

        field(30; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = CustomerContent;
        }

        field(31; "Success"; Boolean)
        {
            Caption = 'Success';
            DataClassification = CustomerContent;
        }

        field(40; "Document Type"; Enum "Document Type EINV")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }

        field(41; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }

        field(42; "LHDN UUID"; Text[50])
        {
            Caption = 'LHDN UUID';
            DataClassification = CustomerContent;
        }

        field(43; "Correlation ID"; Text[50])
        {
            Caption = 'Correlation ID';
            DataClassification = CustomerContent;
        }

        field(50; "Error Code"; Code[20])
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
        }

        field(51; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }

        field(60; "Request Payload"; Blob)
        {
            Caption = 'Request Payload';
            DataClassification = CustomerContent;
        }

        field(61; "Response Payload"; Blob)
        {
            Caption = 'Response Payload';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Called At") { }
        key(SK2; "Document Type", "Document No.") { }
        key(SK3; Success, "Called At") { }
        key(SK4; "Correlation ID") { }
    }

    procedure SetRequestPayload(PayloadText: Text)
    var
        OutStream: OutStream;
    begin
        "Request Payload".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(PayloadText);
    end;

    procedure GetRequestPayload(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Request Payload");
        if "Request Payload".HasValue then begin
            "Request Payload".CreateInStream(InStream, TextEncoding::UTF8);
            InStream.ReadText(Result);
        end;
        exit(Result);
    end;

    procedure SetResponsePayload(PayloadText: Text)
    var
        OutStream: OutStream;
    begin
        "Response Payload".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(PayloadText);
    end;

    procedure GetResponsePayload(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Response Payload");
        if "Response Payload".HasValue then begin
            "Response Payload".CreateInStream(InStream, TextEncoding::UTF8);
            InStream.ReadText(Result);
        end;
        exit(Result);
    end;
}
