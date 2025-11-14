table 7000007 "LHDN Lookup Code EINV"
{
    Caption = 'LHDN Lookup Code EINV';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Lookup Type"; Enum "LHDN Lookup Type EINV")
        {
            Caption = 'Lookup Type';
        }
        field(2; "Code"; Code[35])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[500])
        {
            Caption = 'Description';
        }
        field(4; "Description (Malay)"; Text[500])
        {
            Caption = 'Description (Malay)';
        }
        field(5; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
        }
    }
    keys
    {
        key(PK; "Lookup Type", Code)
        {
            Clustered = true;
        }
    }
}
