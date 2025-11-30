page 70000055 "MY eInv Posted Invoice Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Sales Invoice Line";
    AutoSplitKey = true;
    Permissions = tabledata "Sales Invoice Line" = rm;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("MY eInv Classification Code"; Rec."MY eInv Classification Code")
                {
                    ApplicationArea = All;
                    StyleExpr = ClassificationStyleExpr;
                    Editable = true;
                }

                field("MY eInv LHDN UOM"; Rec."MY eInv LHDN UOM")
                {
                    ApplicationArea = All;
                    StyleExpr = LHDNUOMStyleExpr;
                    Editable = true;
                }

                field("MY eInv Country of Origin"; Rec."MY eInv Country of Origin")
                {
                    ApplicationArea = All;
                    Editable = true;
                }

                field("MY eInv Tariff Code"; Rec."MY eInv Tariff Code")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetFieldStyles();
    end;

    local procedure SetFieldStyles()
    begin
        // Highlight missing required fields
        if Rec."MY eInv Classification Code" = '' then
            ClassificationStyleExpr := 'Unfavorable'
        else
            ClassificationStyleExpr := 'Standard';

        if Rec."MY eInv LHDN UOM" = '' then
            LHDNUOMStyleExpr := 'Unfavorable'
        else
            LHDNUOMStyleExpr := 'Standard';
    end;

    var
        ClassificationStyleExpr: Text;
        LHDNUOMStyleExpr: Text;
}
