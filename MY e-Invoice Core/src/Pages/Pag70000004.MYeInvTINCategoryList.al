page 70000004 "MY eInv TIN Category List"
{
    Caption = 'MY eInvoice TIN Category Reference (LHDN)';
    PageType = List;
    SourceTable = "MY eInv TIN Category";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'TIN category code prefix.';
                    StyleExpr = 'Strong';
                }

                field("Category"; Rec."Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Entity category description.';
                }

                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Detailed description of the entity type.';
                }

                field("Example TIN"; Rec."Example TIN")
                {
                    ApplicationArea = All;
                    ToolTip = 'Example TIN number for this category.';
                    StyleExpr = 'Subordinate';
                }

                field("Digit Length"; Rec."Digit Length")
                {
                    ApplicationArea = All;
                    ToolTip = 'Typical TIN length for this category.';
                }
            }
        }

        area(FactBoxes)
        {
            part(GeneralTINInfo; "MY eInv General TIN FactBox")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InitializeData)
            {
                Caption = 'Initialize TIN Categories';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Initialize the TIN category reference data from LHDN guidelines.';

                trigger OnAction()
                begin
                    Rec.InitializeTINCategoryData();
                    CurrPage.Update(false);
                    Message('TIN category reference data has been initialized.');
                end;
            }

            action(ShowGeneralTINInfo)
            {
                Caption = 'Show General TIN Codes';
                ApplicationArea = All;
                Image = Info;
                ToolTip = 'Display information about the 4 General TIN codes.';

                trigger OnAction()
                var
                    InfoMsg: Label '4 TYPES OF GENERAL TIN CODES:\\\1️⃣ EI00000000010 - General Public''s TIN\   • Local individual with NRIC only\   • Consolidated e-invoice\   • Consolidated self-billed e-invoice\\\2️⃣ EI00000000020 - Foreign Buyer/Recipient\   • Foreign individual (Passport/MyPR/MyKas)\   • Export to foreign buyer\   • Foreign shipping recipient\\\3️⃣ EI00000000030 - Foreign Supplier\   • Self-billed with foreign supplier\   • Import transactions\\\4️⃣ EI00000000040 - Government/Authorities\   • Federal/State/Local government\   • Statutory/Local authorities\   • Exempt institutions without TIN';
                begin
                    Message(InfoMsg);
                end;
            }
        }

        area(Navigation)
        {
            action(OpenLHDNWebsite)
            {
                Caption = 'LHDN MyInvois Portal';
                ApplicationArea = All;
                Image = Web;
                ToolTip = 'Open the LHDN MyInvois portal in your browser.';

                trigger OnAction()
                begin
                    Hyperlink('https://myinvois.hasil.gov.my');
                end;
            }
            action(OpenLHDNWGuidelines)
            {
                Caption = 'LHDN MyInvois Guidelines';
                ApplicationArea = All;
                Image = Web;
                ToolTip = 'Open the LHDN MyInvois Guidelines in your browser.';

                trigger OnAction()
                begin
                    Hyperlink('https://www.hasil.gov.my/en/e-invoice/reference-for-the-implementation-of-e-invoice/guidelines/');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        TINCategory: Record "MY eInv TIN Category";
    begin
        // Auto-initialize if table is empty
        if TINCategory.IsEmpty then
            Rec.InitializeTINCategoryData();
    end;
}
