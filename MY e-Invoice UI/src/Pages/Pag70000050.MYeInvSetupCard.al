page 70000050 "MY eInv Setup Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Company Information";
    Caption = 'LHDN E-Invoice Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Status)
            {
                Caption = 'Status';

                field("Enable E-Invoice"; Rec."Enable E-Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable LHDN E-Invoice features.';
                    Style = Strong;
                    StyleExpr = Rec."Enable E-Invoice";
                }

                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StatusStyle;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Company Information");
                    end;
                }
            }

            group(CompanyDetails)
            {
                Caption = 'Company Registration Details';
                Visible = Rec."Enable E-Invoice";

                field("LHDN TIN"; Rec."LHDN TIN")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Tax Identification Number.';
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
                    ToolTip = 'Specifies the SST registration number.';
                }
                field("LHDN MSIC Code"; Rec."LHDN MSIC Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the MSIC code for your business.';
                }
            }

            group(QuickLinks)
            {
                Caption = 'Quick Links';
                Visible = Rec."Enable E-Invoice";

                field(ViewCodesLink; ViewCodesLinkTxt)
                {
                    ApplicationArea = All;
                    Caption = 'LHDN Codes';
                    Editable = false;
                    Style = StrongAccent;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"MY eInv LHDN Code List");
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncCodes)
            {
                ApplicationArea = All;
                Caption = 'Sync LHDN Codes';
                Image = Import;
                Visible = Rec."Enable E-Invoice";

                trigger OnAction()
                var
                    LHDNCodeSync: Codeunit "MY eInv LHDN Code Synch";
                begin
                    if Confirm('Download all LHDN codes from MyInvois SDK?', true) then
                        LHDNCodeSync.SyncAllCodes();
                end;
            }
            action(ViewCodes)
            {
                ApplicationArea = All;
                Caption = 'View LHDN Codes';
                Image = CodesList;
                Visible = Rec."Enable E-Invoice";

                trigger OnAction()
                begin
                    Page.Run(Page::"MY eInv LHDN Code List");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        UpdateStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateStatus();
    end;

    local procedure UpdateStatus()
    begin
        if Rec."Enable E-Invoice" then begin
            if Rec."LHDN TIN" <> '' then begin
                StatusText := 'Enabled and Configured';
                StatusStyle := 'Favorable';
            end else begin
                StatusText := 'Enabled but TIN not configured';
                StatusStyle := 'Attention';
            end;
        end else begin
            StatusText := 'Disabled';
            StatusStyle := 'Unfavorable';
        end;
    end;

    var
        StatusText: Text;
        StatusStyle: Text;
        ViewCodesLinkTxt: Label 'Click to view LHDN codes';
}
