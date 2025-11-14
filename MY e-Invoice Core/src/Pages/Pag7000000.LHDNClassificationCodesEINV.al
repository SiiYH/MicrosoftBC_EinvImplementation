namespace MYeInvoiceCore.MYeInvoiceCore;

page 7000000 "LHDN Classification Codes EINV"
{
    ApplicationArea = All;
    Caption = 'LHDN Classification Codes EINV';
    PageType = List;
    SourceTable = "LHDN Classification Code EINV";
    UsageCategory = Administration;
    
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Category; Rec.Category)
                {
                    ToolTip = 'Specifies the value of the Category field.', Comment = '%';
                }
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.', Comment = '%';
                }
                field("Default Tax Code"; Rec."Default Tax Code")
                {
                    ToolTip = 'Specifies the value of the Default Tax Code field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Description (Malay)"; Rec."Description (Malay)")
                {
                    ToolTip = 'Specifies the value of the Description (Malay) field.', Comment = '%';
                }
                field("Effective From"; Rec."Effective From")
                {
                    ToolTip = 'Specifies the value of the Effective From field.', Comment = '%';
                }
                field("Effective To"; Rec."Effective To")
                {
                    ToolTip = 'Specifies the value of the Effective To field.', Comment = '%';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ToolTip = 'Specifies the value of the Is Active field.', Comment = '%';
                }
            }
        }
    }
}
