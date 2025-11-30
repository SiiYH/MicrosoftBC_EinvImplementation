tableextension 70000007 "MY eInv Item" extends Item
{
    fields
    {
        field(70000000; "MY eInv Sales Classification"; Code[20])
        {
            Caption = 'Sales Classification Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(Classification));
        }

        field(70000001; "MY eInv Purch. Classification"; Code[20])
        {
            Caption = 'Purchase Classification Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(Classification));
        }
        field(70000002; "MY eInv Country of Origin"; Code[10])
        {
            Caption = 'Country of Origin';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }

        field(70000003; "MY eInv Tariff Code"; Code[20])
        {
            Caption = 'Tariff Code (HS Code)';
            TableRelation = "Tariff Number";
        }
    }
}
