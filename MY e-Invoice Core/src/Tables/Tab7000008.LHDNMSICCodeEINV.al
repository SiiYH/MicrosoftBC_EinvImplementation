table 7000008 "LHDN MSIC Code EINV"
{
    Caption = 'LHDN MSIC Code EINV';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[500])
        {
            Caption = 'Description';
        }
        field(3; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
        }
        field(4; "Category Code"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Category Description"; Text[500])
        {
            Caption = 'Category Description';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
