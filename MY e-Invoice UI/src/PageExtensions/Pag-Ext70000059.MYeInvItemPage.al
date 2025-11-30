pageextension 70000059 "MY eInv Item Page" extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group(MYeInvoice)
            {
                Caption = 'MY eInvoice';
                Visible = eInvEnabled;

                field("MY eInv Sales Classification"; Rec."MY eInv Sales Classification")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Sales Classification Code field.', Comment = '%';
                }
                field("MY eInv Purch. Classification"; Rec."MY eInv Purch. Classification")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Purchase Classification Code field.', Comment = '%';
                }
                field("MY eInv Country of Origin"; Rec."MY eInv Country of Origin")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Country of Origin field.', Comment = '%';
                }
                field("MY eInv Tariff Code"; Rec."MY eInv Tariff Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Tariff Code (HS Code) field.', Comment = '%';
                }
            }
        }

    }
    trigger OnAfterGetRecord()
    begin
        eInvEnabled := MYeInvFeaMgmt.IsEInvoiceEnabled();
    end;

    var
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";
        eInvEnabled: Boolean;
}
