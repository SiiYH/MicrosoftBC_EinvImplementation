page 70000000 "MY eInv Code List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MY eInv LHDN Code";
    Caption = 'eInvoice Codes';
    CardPageId = "LHDN Code Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code Type"; Rec."Code Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of code.';
                }
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code value.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field("Tax Rate %"; Rec."Tax Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax rate (applicable for tax types).';
                    Visible = ShowTaxRate;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the code is active.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = All; }
            systempart(Notes; Notes) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncFromSDK)
            {
                ApplicationArea = All;
                Caption = 'Sync from MyInvois SDK';
                Image = Import;
                ToolTip = 'Download and synchronize codes from MyInvois SDK.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    LHDNCodeSync: Codeunit "MY eInv LHDN Code Synch";
                begin
                    LHDNCodeSync.SyncAllCodes();
                    CurrPage.Update(false);
                end;
            }
            action(SyncSpecific)
            {
                ApplicationArea = All;
                Caption = 'Sync Current Type';
                Image = ImportExcel;
                ToolTip = 'Synchronize only the currently filtered code type.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LHDNCodeSync: Codeunit "MY eInv LHDN Code Synch";
                    CodeTypeToSync: Enum "MY eInv LHDN Code Type";
                begin
                    if Rec."Code Type" <> Rec."Code Type"::" " then
                        CodeTypeToSync := Rec."Code Type"
                    else
                        Error('Please filter to a specific code type first.');

                    if Confirm('Sync %1 codes from MyInvois SDK?', true, CodeTypeToSync) then begin
                        LHDNCodeSync.SyncCodeType(CodeTypeToSync);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                ToolTip = 'Export codes to Excel.';

                trigger OnAction()
                begin
                    // Implement Excel export
                end;
            }
        }
        area(Navigation)
        {
            group(Filters)
            {
                Caption = 'Quick Filters';
                action(FilterByState)
                {
                    ApplicationArea = All;
                    Caption = 'State Codes';
                    Image = FilterLines;

                    trigger OnAction()
                    begin
                        Rec.SetRange("Code Type", Rec."Code Type"::State);
                        CurrPage.Update(false);
                    end;
                }
                action(FilterByTaxType)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Types';
                    Image = FilterLines;

                    trigger OnAction()
                    begin
                        Rec.SetRange("Code Type", Rec."Code Type"::"Tax Type");
                        CurrPage.Update(false);
                    end;
                }
                action(FilterByInvoiceType)
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Types';
                    Image = FilterLines;

                    trigger OnAction()
                    begin
                        Rec.SetRange("Code Type", Rec."Code Type"::"E-Invoice Type");
                        CurrPage.Update(false);
                    end;
                }
                action(ShowAll)
                {
                    ApplicationArea = All;
                    Caption = 'Show All';
                    Image = ClearFilter;

                    trigger OnAction()
                    begin
                        Rec.Reset();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        LHDNFeature: Codeunit "MY eInv Feature Management";
    begin
        UpdateVisibility();

        if not LHDNFeature.IsEInvoiceEnabled() then
            Error('E-Invoice is not enabled. Please enable it in Company Information first.');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateVisibility();
    end;

    local procedure UpdateVisibility()
    begin
        ShowTaxRate := (Rec.GetFilter("Code Type") = Format(Rec."Code Type"::"Tax Type"));
    end;

    var
        ShowTaxRate: Boolean;
}
