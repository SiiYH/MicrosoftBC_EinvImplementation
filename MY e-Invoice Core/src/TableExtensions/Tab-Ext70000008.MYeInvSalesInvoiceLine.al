tableextension 70000008 "MY eInv Sales Invoice Line" extends "Sales Invoice Line"
{
    fields
    {
        field(70000000; "MY eInv Classification Code"; Code[20])
        {
            Caption = 'eInvoice Classification';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(Classification));
        }

        field(70000001; "MY eInv LHDN UOM"; Code[10])
        {
            Caption = 'eInvoice LHDN UOM';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("Unit of Measurement"));
        }
        field(70000002; "MY eInv Country of Origin"; Code[10])
        {
            Caption = 'Country of Origin';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region"."MY eInv ISO Code";
        }

        field(70000003; "MY eInv Tariff Code"; Code[20])
        {
            Caption = 'Tariff Code';
            DataClassification = CustomerContent;
            TableRelation = "Tariff Number";
        }
    }
}
