pageextension 70000050 "MY eInv Company Info Page" extends "Company Information"
{
    layout
    {
        addafter(General)
        {
            group("LHDN E-Invoice")
            {
                Caption = 'LHDN E-Invoice';

                field("Enable E-Invoice"; Rec."Enable E-Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable LHDN E-Invoice features for this company.';
                    Style = Strong;
                    StyleExpr = Rec."Enable E-Invoice";

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }

                group(EInvoiceDetails)
                {
                    Caption = 'E-Invoice Registration Details';
                    Visible = Rec."Enable E-Invoice";

                    field("LHDN TIN"; Rec."LHDN TIN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Tax Identification Number (TIN) registered with LHDN.';
                        ShowMandatory = true;
                    }
                    field("LHDN BRN"; Rec."LHDN BRN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Business Registration Number.';
                    }
                    field("LHDN SST Number"; Rec."LHDN SST Number")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Sales and Service Tax (SST) registration number.';
                    }
                    field("LHDN Tourism Tax No."; Rec."LHDN Tourism Tax No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Tourism Tax registration number (if applicable).';
                    }
                    field("LHDN MSIC Code"; Rec."LHDN MSIC Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Malaysian Standard Industrial Classification (MSIC) code for your business.';
                    }
                }
            }
        }
    }

    actions
    {
        addafter(Codes)
        {
            group(EInvoiceActions)
            {
                Caption = 'E-Invoice';
                Visible = Rec."Enable E-Invoice";
                Image = ElectronicPayment;

                action(LHDNSetup)
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Setup';
                    Image = Setup;
                    ToolTip = 'Open LHDN E-Invoice setup page.';

                    trigger OnAction()
                    var
                        LHDNSetup: Page "MY eInv Setup Card";
                    begin
                        LHDNSetup.Run();
                    end;
                }
                action(LHDNCodes)
                {
                    ApplicationArea = All;
                    Caption = 'LHDN Codes';
                    Image = CodesList;
                    ToolTip = 'View and sync LHDN master data codes.';

                    trigger OnAction()
                    var
                        LHDNCodeList: Page "MY eInv LHDN Code List";
                    begin
                        LHDNCodeList.Run();
                    end;
                }
            }
        }
    }
}
