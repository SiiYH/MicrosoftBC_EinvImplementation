pageextension 70000061 "MY eInv Units of Measure" extends "Units of Measure"
{
    layout
    {
        addafter("International Standard Code")
        {
            field("MY eInv LHDN UOM"; Rec."MY eInv LHDN UOM")
            {
                ApplicationArea = All;
                ToolTip = 'LHDN Unit of Measure code for eInvoice submission';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(AutoMapLHDNUOM)
            {
                ApplicationArea = All;
                Caption = 'Auto-Map LHDN UOM';
                Image = MapAccounts;
                ToolTip = 'Automatically map Units of Measure to LHDN codes based on International Standard Code or description';

                trigger OnAction()
                var
                    UnitOfMeasure: Record "Unit of Measure";
                    LHDNUOM: Record "MY eInv LHDN Code";
                    MappedCount: Integer;
                begin
                    if not Confirm('This will automatically map UOMs to LHDN codes where possible.\Do you want to continue?', false) then
                        exit;

                    MappedCount := 0;

                    if UnitOfMeasure.FindSet(true) then
                        repeat
                            // Skip if already mapped
                            if UnitOfMeasure."MY eInv LHDN UOM" = '' then begin
                                // Try to match by International Standard Code first
                                if UnitOfMeasure."International Standard Code" <> '' then begin
                                    if LHDNUOM.Get(Enum::"MY eInv LHDN Code Type"::"Unit of Measurement", UnitOfMeasure."International Standard Code") then begin
                                        UnitOfMeasure."MY eInv LHDN UOM" := LHDNUOM.Code;
                                        UnitOfMeasure.Modify(true);
                                        MappedCount += 1;
                                    end;
                                end;

                                // If still not mapped, try by description matching
                                if UnitOfMeasure."MY eInv LHDN UOM" = '' then begin
                                    if TryMapByDescription(UnitOfMeasure, MappedCount) then
                                        ; // Mapped successfully
                                end;

                                // If still not mapped, try common BC code patterns
                                if UnitOfMeasure."MY eInv LHDN UOM" = '' then begin
                                    if TryMapByCommonCode(UnitOfMeasure, MappedCount) then
                                        ; // Mapped successfully
                                end;
                            end;
                        until UnitOfMeasure.Next() = 0;

                    CurrPage.Update(false);
                    Message('%1 units of measure have been automatically mapped to LHDN codes.', MappedCount);
                end;
            }
        }
    }

    local procedure TryMapByDescription(var UnitOfMeasure: Record "Unit of Measure"; var MappedCount: Integer): Boolean
    var
        LHDNUOM: Record "MY eInv LHDN Code";
        NormalizedUOMDesc: Text;
        NormalizedLHDNDesc: Text;
    begin
        if UnitOfMeasure.Description = '' then
            exit(false);

        NormalizedUOMDesc := NormalizeDescription(UnitOfMeasure.Description);

        // Search through LHDN UOM by description
        if LHDNUOM.FindSet() then
            repeat
                NormalizedLHDNDesc := NormalizeDescription(LHDNUOM.Description);

                // Check if descriptions match after normalization
                if NormalizedUOMDesc = NormalizedLHDNDesc then begin
                    UnitOfMeasure."MY eInv LHDN UOM" := LHDNUOM.Code;
                    UnitOfMeasure.Modify(true);
                    MappedCount += 1;
                    exit(true);
                end;
            until LHDNUOM.Next() = 0;

        exit(false);
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

    local procedure TryMapByCommonCode(var UnitOfMeasure: Record "Unit of Measure"; var MappedCount: Integer): Boolean
    var
        LHDNUOM: Record "MY eInv LHDN Code";
        SearchTerms: List of [Text];
        SearchTerm: Text;
    begin
        // Build search terms based on UOM code and description
        SearchTerms.Add(UpperCase(UnitOfMeasure.Code));
        SearchTerms.Add(UpperCase(UnitOfMeasure.Description));
        SearchTerms.Add(UpperCase(UnitOfMeasure."International Standard Code"));

        // Try to find LHDN UOM by searching its description
        foreach SearchTerm in SearchTerms do begin
            if SearchTerm <> '' then begin
                LHDNUOM.Reset();
                LHDNUOM.SetRange("Code Type", Enum::"MY eInv LHDN Code Type"::"Unit of Measurement");
                LHDNUOM.SetFilter(Description, '@*' + SearchTerm + '*'); // Contains search
                if LHDNUOM.FindFirst() then begin
                    UnitOfMeasure."MY eInv LHDN UOM" := LHDNUOM.Code;
                    UnitOfMeasure.Modify(true);
                    MappedCount += 1;
                    exit(true);
                end;

                // Also try searching by Code
                LHDNUOM.Reset();
                LHDNUOM.SetRange("Code Type", Enum::"MY eInv LHDN Code Type"::"Unit of Measurement");
                LHDNUOM.SetFilter(Code, '@*' + SearchTerm + '*');
                if LHDNUOM.FindFirst() then begin
                    UnitOfMeasure."MY eInv LHDN UOM" := LHDNUOM.Code;
                    UnitOfMeasure.Modify(true);
                    MappedCount += 1;
                    exit(true);
                end;
            end;
        end;

        exit(false);
    end;
}
