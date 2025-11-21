table 70000004 "MY eInv TIN Category"
{
    Caption = 'MY eInv TIN Category';
    DataClassification = SystemMetadata;
    LookupPageId = "MY eInv TIN Category List";
    DrillDownPageId = "MY eInv TIN Category List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'TIN Code';
            DataClassification = SystemMetadata;
        }

        field(2; "Category"; Text[100])
        {
            Caption = 'Entity Category';
            DataClassification = SystemMetadata;
        }

        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }

        field(4; "Example TIN"; Text[20])
        {
            Caption = 'Example TIN';
            DataClassification = SystemMetadata;
        }

        field(5; "Digit Length"; Text[30])
        {
            Caption = 'Typical Length';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    // Initialize default LHDN TIN categories
    procedure InitializeTINCategoryData()
    begin
        InsertTINCategory('C', 'Companies', 'Registered companies under SSM', 'C20880050010', '12 (C + 11 digits)');
        InsertTINCategory('CS', 'Cooperative Societies', 'Registered cooperative societies', 'CS1234567890', '12 (CS + 10 digits)');
        InsertTINCategory('D', 'Partnerships', 'Business partnerships', 'D4800990020', '12 (D + 11 digits)');
        InsertTINCategory('F', 'Associations', 'Registered associations', 'F10234567090', '13 (F + 12 digits)');
        InsertTINCategory('PT', 'Limited Liability Partnerships', 'LLP entities registered under SSM', 'PT1234567890', '13 (PT + 11 digits)');
        InsertTINCategory('TA', 'Trust Bodies', 'Trust bodies and organizations', 'TA1234567890', '13 (TA + 11 digits)');
        InsertTINCategory('TC', 'Unit Trusts/Property Trusts', 'Unit trusts and property trust funds', 'TC1234567890', '13 (TC + 11 digits)');
        InsertTINCategory('TN', 'Business Trusts', 'Business trust entities', 'TN1234567890', '13 (TN + 11 digits)');
        InsertTINCategory('TR', 'REITs/Property Trust Funds', 'Real Estate Investment Trusts', 'TR1234567890', '13 (TR + 11 digits)');
        InsertTINCategory('TP', 'Deceased Person''s Estate', 'Estate of deceased persons', 'TP1234567890', '13 (TP + 11 digits)');
        InsertTINCategory('J', 'Hindu Joint Families', 'Hindu Joint Family entities', 'J12345678900', '12 (J + 11 digits)');
        InsertTINCategory('LE', 'Labuan Entities', 'Entities registered in Labuan', 'LE1234567890', '13 (LE + 11 digits)');
        InsertTINCategory('IG', 'Individual', 'Malaysian individuals (auto-issued by LHDN at age 18)', 'IG115002000', '11-13 (IG + 9-11 digits)');
    end;

    local procedure InsertTINCategory(CodeValue: Code[10]; CategoryText: Text[100]; DescriptionText: Text[250]; ExampleText: Text[20]; LengthText: Text[30])
    var
        TINCategory: Record "MY eInv TIN Category";
    begin
        if TINCategory.Get(CodeValue) then
            exit;

        TINCategory.Init();
        TINCategory.Code := CodeValue;
        TINCategory.Category := CategoryText;
        TINCategory.Description := DescriptionText;
        TINCategory."Example TIN" := ExampleText;
        TINCategory."Digit Length" := LengthText;
        TINCategory.Insert();
    end;

    procedure GetTINCategoryPrefix(EntityType: Enum "MY eInv Entity Type"): Code[10]
    begin
        // Return the appropriate TIN prefix based on entity type
        case EntityType of
            EntityType::"Malaysian Business",
            EntityType::"Non-Malaysian Business":
                exit('C'); // Most common for companies

            EntityType::"Malaysian Individual",
            EntityType::"Non-Malaysian Individual":
                exit('IG'); // Individuals

            EntityType::Government:
                exit('C'); // Government typically uses company-type TIN

            else
                exit('C'); // Default to company
        end;
    end;
}
