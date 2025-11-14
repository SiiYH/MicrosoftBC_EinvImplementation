/// <summary>
/// Schema Version Configuration
/// </summary>
table 7000003 "e-Invoice Schema Version EINV"
{
    Caption = 'e-Invoice Schema Version';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Version Code"; Code[10])
        {
            Caption = 'Version Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; "Document Type"; Enum "Document Type EINV")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }

        field(10; "XMLPort ID"; Integer)
        {
            Caption = 'XMLPort ID';
            DataClassification = CustomerContent;
        }

        field(11; "Schema URL"; Text[250])
        {
            Caption = 'Schema URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }

        field(20; "Effective From"; Date)
        {
            Caption = 'Effective From';
            DataClassification = CustomerContent;
        }

        field(21; "Effective To"; Date)
        {
            Caption = 'Effective To';
            DataClassification = CustomerContent;
        }

        field(22; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(30; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Version Code", "Document Type")
        {
            Clustered = true;
        }
        key(SK1; "Document Type", "Is Active", "Effective From") { }
    }
}
