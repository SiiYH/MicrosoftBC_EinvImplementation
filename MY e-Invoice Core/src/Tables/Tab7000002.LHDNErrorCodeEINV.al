table 7000002 "LHDN Error Code EINV"
{
    Caption = 'LHDN Error Code';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Error Code"; Code[20])
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = CustomerContent;
        }

        field(3; "Error Category"; Enum "Error Category EINV")
        {
            Caption = 'Error Category';
            DataClassification = CustomerContent;
        }

        field(10; "Technical Message (EN)"; Text[500])
        {
            Caption = 'Technical Message (English)';
            DataClassification = CustomerContent;
        }

        field(11; "Technical Message (MS)"; Text[500])
        {
            Caption = 'Technical Message (Malay)';
            DataClassification = CustomerContent;
        }

        field(20; "User Message"; Text[500])
        {
            Caption = 'User-Friendly Message';
            DataClassification = CustomerContent;
        }

        field(30; "Resolution Steps"; Text[1000])
        {
            Caption = 'How to Fix';
            DataClassification = CustomerContent;
        }

        field(40; "Is Retryable"; Boolean)
        {
            Caption = 'Can Retry';
            DataClassification = CustomerContent;
        }

        field(41; "Retry Delay (Seconds)"; Integer)
        {
            Caption = 'Wait Before Retry';
            DataClassification = CustomerContent;
        }

        field(50; "Documentation URL"; Text[250])
        {
            Caption = 'Documentation URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(PK; "Error Code")
        {
            Clustered = true;
        }
        key(SK1; "HTTP Status Code") { }
        key(SK2; "Error Category") { }
    }
}
