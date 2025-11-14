// ============================================================================
// 2. MASTER DATA TABLES
// ============================================================================

/// <summary>
/// LHDN Classification Codes Master
/// </summary>
/// 
table 7000001 "LHDN Classification Code EINV"
{
    Caption = 'LHDN Classification Code';
    DataClassification = CustomerContent;
    LookupPageId = "LHDN Classification Codes EINV";
    DrillDownPageId = "LHDN Classification Codes EINV";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        field(3; "Description (Malay)"; Text[100])
        {
            Caption = 'Description (Malay)';
            DataClassification = CustomerContent;
        }

        field(4; Category; Enum "Classification Category EINV")
        {
            Caption = 'Category';
            DataClassification = CustomerContent;
        }

        field(5; "Default Tax Code"; Code[20])
        {
            Caption = 'Default Tax Code';
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";
        }

        field(10; "Effective From"; Date)
        {
            Caption = 'Effective From';
            DataClassification = CustomerContent;
        }

        field(11; "Effective To"; Date)
        {
            Caption = 'Effective To';
            DataClassification = CustomerContent;
        }

        field(12; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(SK1; Category, "Is Active") { }
    }
}
