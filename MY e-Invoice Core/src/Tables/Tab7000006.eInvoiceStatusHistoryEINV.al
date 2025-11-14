/// <summary>
/// Document status history for audit trail
/// </summary>
table 7000006 "e-Invoice Status History EINV"
{
    Caption = 'e-Invoice Status History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Document Type"; Enum "Document Type EINV")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }

        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }

        field(10; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            DataClassification = CustomerContent;
        }

        field(11; "Changed By"; Code[50])
        {
            Caption = 'Changed By';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(20; "Old Status"; Enum "e-Invoice Status EINV")
        {
            Caption = 'Old Status';
            DataClassification = CustomerContent;
        }

        field(21; "New Status"; Enum "e-Invoice Status EINV")
        {
            Caption = 'New Status';
            DataClassification = CustomerContent;
        }

        field(30; Message; Text[500])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }

        field(31; Reason; Text[1000])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }

        field(40; "LHDN UUID"; Text[50])
        {
            Caption = 'LHDN UUID';
            DataClassification = CustomerContent;
        }

        field(41; "Correlation ID"; Text[50])
        {
            Caption = 'Correlation ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Document Type", "Document No.", "Changed At") { }
        key(SK2; "Changed At") { }
    }
}
