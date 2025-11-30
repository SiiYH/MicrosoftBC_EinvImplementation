tableextension 70000006 "MY eInv Country/Region" extends "Country/Region"
{
    fields
    {
        field(70000; "MY eInv ISO Code"; Code[3])
        {
            Caption = 'MY eInv ISO Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("Country"), Active = const(true));
        }
    }

    keys
    {
        key(eInvCountryRegion; "MY eInv ISO Code") { }
    }

    trigger OnInsert()
    var
        InitializeISOCodes: Codeunit "MY eInv LHDN Code Synch";
    begin
        InitializeISOCodes.InitializeSingleCountry(Rec);
    end;
}
