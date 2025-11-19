table 70000003 "MY eInv Error Log"
{
    Caption = 'MY eInv Error Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(2; "Error DateTime"; DateTime)
        {
            Caption = 'Error Date Time';
            DataClassification = CustomerContent;
        }
        field(3; "Error Type"; Text[100])
        {
            Caption = 'Error Type';
            DataClassification = CustomerContent;
        }
        field(4; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = CustomerContent;
        }
        field(5; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Document Type"; Code[20])
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(12; "Submission UID"; Text[100])
        {
            Caption = 'Submission UID';
            DataClassification = CustomerContent;
        }
        field(20; "Request Body"; Blob)
        {
            Caption = 'Request Body';
            DataClassification = CustomerContent;
        }
        field(21; "Response Body"; Blob)
        {
            Caption = 'Response Body';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DateTime; "Error DateTime")
        {
        }
        key(ErrorType; "Error Type")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Error DateTime", "Error Type", "HTTP Status Code")
        {
        }
    }

    procedure SetRequestBody(RequestText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Request Body");
        "Request Body".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(RequestText);
    end;

    procedure GetRequestBody(): Text
    var
        InStream: InStream;
        RequestText: Text;
    begin
        CalcFields("Request Body");
        if not "Request Body".HasValue then
            exit('');

        "Request Body".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(RequestText);
        exit(RequestText);
    end;

    procedure SetResponseBody(ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Response Body");
        "Response Body".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ResponseText);
    end;

    procedure GetResponseBody(): Text
    var
        InStream: InStream;
        ResponseText: Text;
    begin
        CalcFields("Response Body");
        if not "Response Body".HasValue then
            exit('');

        "Response Body".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(ResponseText);
        exit(ResponseText);
    end;
}
