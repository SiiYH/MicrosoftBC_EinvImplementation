pageextension 70000060 "MY eInv Item Charges Page" extends "Item Charges"
{
    layout
    {
        addlast(content)
        {
            group(MYeInvoice)
            {
                Caption = 'MY eInvoice';
                Visible = eInvEnabled;

                field("MY eInv Classification Code"; Rec."MY eInv Classification Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the eInvoice Classification field.', Comment = '%';
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
