/// <summary>
/// Batch submission queue
/// </summary>
table 7000004 "e-Invoice Batch Queue EINV"
{
    Caption = 'e-Invoice Batch Queue';
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

        field(4; "Document Table ID"; Integer)
        {
            Caption = 'Document Table ID';
            DataClassification = SystemMetadata;
        }

        field(5; "Document System ID"; Guid)
        {
            Caption = 'Document System ID';
            DataClassification = SystemMetadata;
        }

        field(10; Status; Enum "Batch Queue Status EINV")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }

        field(11; "Status Message"; Text[500])
        {
            Caption = 'Status Message';
            DataClassification = CustomerContent;
        }

        field(20; "Queued At"; DateTime)
        {
            Caption = 'Queued At';
            DataClassification = CustomerContent;
        }

        field(21; "Queued By"; Code[50])
        {
            Caption = 'Queued By';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(22; "Processing Started At"; DateTime)
        {
            Caption = 'Processing Started At';
            DataClassification = CustomerContent;
        }

        field(23; "Submitted At"; DateTime)
        {
            Caption = 'Submitted At';
            DataClassification = CustomerContent;
        }

        field(24; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = CustomerContent;
        }

        field(30; "Error Code"; Code[20])
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
            TableRelation = "LHDN Error Code EINV";
        }

        field(31; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }

        field(40; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
        }

        field(41; "Max Retries"; Integer)
        {
            Caption = 'Max Retries';
            DataClassification = CustomerContent;
            InitValue = 3;
        }

        field(42; "Next Retry At"; DateTime)
        {
            Caption = 'Next Retry At';
            DataClassification = CustomerContent;
        }

        field(50; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
            InitValue = 5;
            MinValue = 1;
            MaxValue = 10;
        }

        field(51; "Batch ID"; Guid)
        {
            Caption = 'Batch ID';
            DataClassification = CustomerContent;
        }

        field(60; "LHDN UUID"; Text[50])
        {
            Caption = 'LHDN UUID';
            DataClassification = CustomerContent;
        }

        field(61; "LHDN Submission UID"; Text[50])
        {
            Caption = 'LHDN Submission UID';
            DataClassification = CustomerContent;
        }

        field(62; "Correlation ID"; Text[50])
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
        key(SK1; Status, "Next Retry At", Priority) { }
        key(SK2; "Batch ID", Status) { }
        key(SK3; "Document Type", "Document No.") { }
        key(SK4; "Queued At") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Document No.", Status, "Queued At") { }
        fieldgroup(Brick; "Document No.", Status, "Error Message") { }
    }
}
