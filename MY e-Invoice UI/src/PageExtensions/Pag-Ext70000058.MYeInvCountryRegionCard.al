pageextension 70000058 "MY eInv Country/Region Card" extends "Countries/Regions"
{
    layout
    {
        addafter(Name)
        {
            field("MY eInv ISO Code"; Rec."MY eInv ISO Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the MY eInv ISO Code field.', Comment = '%';
            }
        }
    }
    actions
    {
        addafter("&Country/Region")
        {
            group("MY eInvoice")
            {
                action(MapToLHDNCountryCode)
                {
                    Caption = 'Map To LHDN Country Code';
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                        if Rec.FindSet() then
                            repeat
                                Rec."MY eInv ISO Code" := MapToLHDNCountryCode(Rec.Code);
                                Rec.Modify();
                            until Rec.Next() = 0;
                    end;
                }
            }

        }
    }

    local procedure MapToLHDNCountryCode(BCCountryCode: Code[10]): Text[3]
    var
        CountryRegion: Record "Country/Region";
        MYeInvCodeTable: Record "MY eInv LHDN Code";
    begin
        // First: Check Country/Region table
        if CountryRegion.Get(BCCountryCode) then begin
            if CountryRegion."MY eInv ISO Code" <> '' then
                exit(CountryRegion."MY eInv ISO Code");
        end;

        // Second: Direct lookup in code table (in case BC code matches ISO code)
        MYeInvCodeTable.SetRange("Code Type", Enum::"MY eInv LHDN Code Type"::Country);
        MYeInvCodeTable.SetRange(Code, UpperCase(BCCountryCode));
        MYeInvCodeTable.SetRange(Active, true);
        if MYeInvCodeTable.FindFirst() then
            exit(MYeInvCodeTable.Code);

        // Third: Try to find by name match
        if CountryRegion.Get(BCCountryCode) then begin
            MYeInvCodeTable.SetRange(Code);
            MYeInvCodeTable.SetFilter(Description, '@*' + CountryRegion.Name + '*');
            if MYeInvCodeTable.FindFirst() then
                exit(MYeInvCodeTable.Code);
        end;

        // Return empty if no match found
        exit('');
    end;
}
