page 70000001 "LHDN Code Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "MY eInv LHDN Code";
    Caption = 'LHDN Code Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                field("Description (Malay)"; Rec."Description (Malay)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Malay description.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the code is active.';
                }
            }
            group(Additional)
            {
                Caption = 'Additional Information';
                Visible = ShowAdditionalFields;

                field("Parent Code"; Rec."Parent Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent code (for hierarchical codes like MSIC).';
                }
                field("Tax Rate %"; Rec."Tax Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax rate (for tax types).';
                    Visible = ShowTaxRate;
                }
                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sort order.';
                }
            }
            group(Metadata)
            {
                Caption = 'Metadata';

                field("Last Updated"; Rec."Last Updated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("Source"; Rec."Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source of the data.';
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        LHDNFeature: Codeunit "MY eInv Feature Management";
    begin
        if not LHDNFeature.IsEInvoiceEnabled() then
            Error('E-Invoice is not enabled. Please enable it in Company Information first.');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateVisibility();
    end;

    local procedure UpdateVisibility()
    begin
        ShowTaxRate := (Rec."Code Type" = Rec."Code Type"::"Tax Type");
        ShowAdditionalFields := (Rec."Code Type" in [Rec."Code Type"::MSIC, Rec."Code Type"::"Tax Type"]);
    end;

    var
        ShowTaxRate: Boolean;
        ShowAdditionalFields: Boolean;
}
