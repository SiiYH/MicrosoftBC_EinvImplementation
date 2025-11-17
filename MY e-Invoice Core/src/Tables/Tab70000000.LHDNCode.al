table 70000000 "MY eInv LHDN Code"
{
    Caption = 'LHDN Code';
    DataClassification = SystemMetadata;
    LookupPageId = "MY eInv Code List";
    DrillDownPageId = "MY eInv Code List";

    fields
    {
        field(1; "Code Type"; Enum "MY eInv LHDN Code Type")
        {
            Caption = 'Code Type';
            DataClassification = SystemMetadata;
        }
        field(2; "Code"; Code[50])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(20; "Description (Malay)"; Text[250])
        {
            Caption = 'Description (Malay)';
            DataClassification = SystemMetadata;
        }
        field(30; "Parent Code"; Code[50])
        {
            Caption = 'Parent Code';
            DataClassification = SystemMetadata;
            TableRelation = "MY eInv LHDN Code"."Code" where("Code Type" = field("Code Type"));
        }
        field(40; "Tax Rate %"; Decimal)
        {
            Caption = 'Tax Rate %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(50; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(60; "Sort Order"; Integer)
        {
            Caption = 'Sort Order';
            DataClassification = SystemMetadata;
        }
        field(100; "Last Updated"; DateTime)
        {
            Caption = 'Last Updated';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(101; "Source"; Text[100])
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code Type", "Code")
        {
            Clustered = true;
        }
        key(Idx1; "Code Type", Description) { }
        key(Idx2; "Code Type", "Sort Order") { }
        key(Idx3; "Code Type", Active) { }
    }

    trigger OnInsert()
    begin
        "Last Updated" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Updated" := CurrentDateTime;
    end;
}
