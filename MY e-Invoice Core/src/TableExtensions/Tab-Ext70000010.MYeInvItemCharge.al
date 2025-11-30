tableextension 70000010 "MY eInv Item Charge" extends "Item Charge"
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
    }
}
