pageextension 70000063 "MY eInv Posted S.Inv Subform" extends "Posted Sales Invoice Subform"
{
    layout
    {
        addafter("Shortcut Dimension 2 Code")
        {
            field("MY eInv LHDN UOM"; Rec."MY eInv LHDN UOM")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the eInvoice LHDN UOM field.', Comment = '%';
            }
            field("MY eInv Classification Code"; Rec."MY eInv Classification Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the eInvoice Classification field.', Comment = '%';
            }
            field("MY eInv Country of Origin"; Rec."MY eInv Country of Origin")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Country of Origin field.', Comment = '%';
            }
            field("MY eInv Tariff Code"; Rec."MY eInv Tariff Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Tariff Code field.', Comment = '%';
            }
        }
    }
}
