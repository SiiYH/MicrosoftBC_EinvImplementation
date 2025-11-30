pageextension 70000062 "MY eInv Resource Page" extends "Resource Card"
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
