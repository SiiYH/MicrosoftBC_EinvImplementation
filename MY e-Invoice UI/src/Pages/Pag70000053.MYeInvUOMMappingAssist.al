page 70000053 "MY eInv UOM Mapping Assist"
{
    Caption = 'UOM Mapping Assistant';
    PageType = List;
    SourceTable = "Unit of Measure";
    SourceTableView = where("MY eInv LHDN UOM" = const(''));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("International Standard Code"; Rec."International Standard Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(SuggestedLHDNUOM; SuggestedLHDNCode)
                {
                    ApplicationArea = All;
                    Caption = 'Suggested LHDN UOM';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        LHDNUOMLookup: Page "MY eInv Code List";
                        LHDNUOM: Record "MY eInv LHDN Code";
                    begin
                        LHDNUOM.SetFilter("Code Type", '%1', Enum::"MY eInv LHDN Code Type"::"Unit of Measurement");
                        LHDNUOMLookup.SetTableView(LHDNUOM);
                        LHDNUOMLookup.LookupMode(true);
                        if LHDNUOMLookup.RunModal() = Action::LookupOK then begin
                            LHDNUOMLookup.GetRecord(TempLHDNUOM);
                            SuggestedLHDNCode := TempLHDNUOM.Code;
                            Rec."MY eInv LHDN UOM" := TempLHDNUOM.Code;
                            Rec.Modify(true);
                            CurrPage.Update(false);
                        end;
                    end;
                }

                field(SuggestedDescription; SuggestedLHDNDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Suggested Description';
                    Editable = false;
                }

                field("MY eInv LHDN UOM"; Rec."MY eInv LHDN UOM")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FindSuggestedMapping();
    end;

    local procedure FindSuggestedMapping()
    var
        LHDNUOM: Record "MY eInv LHDN Code";
    begin
        Clear(SuggestedLHDNCode);
        Clear(SuggestedLHDNDescription);

        // Try exact match on International Standard Code
        if Rec."International Standard Code" <> '' then begin
            if LHDNUOM.Get(Enum::"MY eInv LHDN Code Type"::"Unit of Measurement", Rec."International Standard Code") then begin
                SuggestedLHDNCode := LHDNUOM.Code;
                SuggestedLHDNDescription := LHDNUOM.Description;
                exit;
            end;

            // Try codes ending with ISO code
            LHDNUOM.Reset();
            LHDNUOM.SetFilter("Code Type", '%1', Enum::"MY eInv LHDN Code Type"::"Unit of Measurement");
            LHDNUOM.SetFilter(Code, '*' + Rec."International Standard Code");
            if LHDNUOM.FindFirst() then begin
                SuggestedLHDNCode := LHDNUOM.Code + ' (?)';
                SuggestedLHDNDescription := LHDNUOM.Description;
                exit;
            end;
        end;

        // Try description matching
        if Rec.Description <> '' then begin
            LHDNUOM.Reset();
            LHDNUOM.SetFilter("Code Type", '%1', Enum::"MY eInv LHDN Code Type"::"Unit of Measurement");
            LHDNUOM.SetFilter(Description, '@*' + NormalizeDescription(Rec.Description) + '*');
            if LHDNUOM.FindFirst() then begin
                SuggestedLHDNCode := LHDNUOM.Code + ' (?)';
                SuggestedLHDNDescription := LHDNUOM.Description;
                exit;
            end;
        end;
    end;

    local procedure NormalizeDescription(Description: Text): Text
    var
        Normalized: Text;
    begin
        Normalized := UpperCase(Description);

        // Remove spaces
        Normalized := DelChr(Normalized, '=', ' ');

        // Handle common spelling variations
        Normalized := Normalized.Replace('METER', 'METRE');
        Normalized := Normalized.Replace('LITER', 'LITRE');
        Normalized := Normalized.Replace('CENTIMETER', 'CENTIMETRE');
        Normalized := Normalized.Replace('MILLIMETER', 'MILLIMETRE');
        Normalized := Normalized.Replace('KILOMETER', 'KILOMETRE');
        Normalized := Normalized.Replace('DECIMETER', 'DECIMETRE');

        // Remove common suffixes/prefixes
        Normalized := Normalized.Replace('(S)', '');
        Normalized := Normalized.Replace('S', ''); // Be careful with this one

        exit(Normalized);
    end;

    var
        TempLHDNUOM: Record "MY eInv LHDN Code";
        SuggestedLHDNCode: Text;
        SuggestedLHDNDescription: Text;
}
