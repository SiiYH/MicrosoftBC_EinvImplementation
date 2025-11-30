tableextension 70000010 "MY eInv Item Charge" extends "Item Charge"
{
    fields
    {
        field(70000000; "MY eInv Classification Code"; Code[20])
        {
            Caption = 'eInvoice Classification';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(Classification));
        }
    }
}
