tableextension 70000012 "MY eInv Unit of Measure" extends "Unit of Measure"
{
    fields
    {
        field(70000000; "MY eInv LHDN UOM"; Code[10])
        {
            Caption = 'eInvoice LHDN UOM';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("Unit of Measurement"));
        }
    }
}
