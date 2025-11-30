pageextension 70000051 "MY eInv Post Code Page" extends "Post Codes"
{
    layout
    {
        addafter(City)
        {
            field("MY eInv State Code"; Rec."MY eInv State Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the MY eInv State Code field.', Comment = '%';
                Visible = eInvEnabled;

            }
            field("MY eInv State Description"; Rec."MY eInv State Description")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the MY eInv State Description field.', Comment = '%';
                Visible = eInvEnabled;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(UpdateMYeInvStateCode)
            {
                Visible = eInvEnabled;
                Caption = 'Update MY e-Inv State Code';
                ApplicationArea = all;
                Image = Refresh;
                trigger OnAction()
                var
                    MYeInvLHDNCodeSynch: Codeunit "MY eInv LHDN Code Synch";
                begin
                    MYeInvLHDNCodeSynch.UpdateAllStateCodesFromPostCode();
                end;
            }
        }
        addafter(Category_Process)
        {
            actionref(UpdateMYeInvStateCodeRef; UpdateMYeInvStateCode) { }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        eInvEnabled := MYeInvFeaMgmt.IsEInvoiceEnabled();
    end;

    var
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";
        eInvEnabled: Boolean;

}
