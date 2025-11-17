tableextension 70000000 "MY eInv LHDN Company Info Ext" extends "Company Information"
{
    fields
    {
        field(7000000; "Enable E-Invoice"; Boolean)
        {
            Caption = 'Enable E-Invoice';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Enable E-Invoice" then
                    ValidateEInvoiceSetup();
            end;
        }
        field(7000001; "LHDN TIN"; Text[20])
        {
            Caption = 'LHDN TIN';
            DataClassification = CustomerContent;
        }
        field(7000002; "LHDN BRN"; Text[20])
        {
            Caption = 'LHDN BRN (Business Registration Number)';
            DataClassification = CustomerContent;
        }
        field(7000003; "LHDN SST Number"; Text[20])
        {
            Caption = 'LHDN SST Number';
            DataClassification = CustomerContent;
        }
        field(7000004; "LHDN Tourism Tax No."; Text[20])
        {
            Caption = 'LHDN Tourism Tax No.';
            DataClassification = CustomerContent;
        }
        field(7000005; "LHDN MSIC Code"; Code[10])
        {
            Caption = 'LHDN MSIC Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code"."Code" where("Code Type" = const(MSIC), Active = const(true));
        }
    }

    local procedure ValidateEInvoiceSetup()
    var
        ConfirmMsg: Label 'This will enable LHDN E-Invoice features for this company. Do you want to continue?';
        SetupMsg: Label 'E-Invoice has been enabled. You can now access E-Invoice setup and related pages.';
    begin
        if not Confirm(ConfirmMsg, false) then
            Error('');

        Message(SetupMsg);
    end;
}
