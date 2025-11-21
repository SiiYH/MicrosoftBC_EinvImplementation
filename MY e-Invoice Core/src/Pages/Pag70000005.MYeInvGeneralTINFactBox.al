page 70000005 "MY eInv General TIN FactBox"
{
    Caption = 'General TIN Codes';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            group(GeneralTINs)
            {
                Caption = 'General TIN Codes';
                ShowCaption = false;

                label(GeneralPublic)
                {
                    ApplicationArea = All;
                    Caption = 'EI00000000010';
                    ToolTip = 'General Public''s TIN - For local individuals with NRIC only';
                    StyleExpr = 'Strong';
                }

                label(GeneralPublicDesc)
                {
                    ApplicationArea = All;
                    Caption = 'General Public (NRIC only)';
                }

                label(Spacer1)
                {
                    ApplicationArea = All;
                    Caption = '';
                }

                label(ForeignBuyer)
                {
                    ApplicationArea = All;
                    Caption = 'EI00000000020';
                    ToolTip = 'Foreign Buyer/Recipient - For foreign individuals or exports';
                    StyleExpr = 'Strong';
                }

                label(ForeignBuyerDesc)
                {
                    ApplicationArea = All;
                    Caption = 'Foreign Buyer/Recipient';
                }

                label(Spacer2)
                {
                    ApplicationArea = All;
                    Caption = '';
                }

                label(ForeignSupplier)
                {
                    ApplicationArea = All;
                    Caption = 'EI00000000030';
                    ToolTip = 'Foreign Supplier - For self-billed or import transactions';
                    StyleExpr = 'Strong';
                }

                label(ForeignSupplierDesc)
                {
                    ApplicationArea = All;
                    Caption = 'Foreign Supplier/Import';
                }

                label(Spacer3)
                {
                    ApplicationArea = All;
                    Caption = '';
                }

                label(Government)
                {
                    ApplicationArea = All;
                    Caption = 'EI00000000040';
                    ToolTip = 'Government/Authorities - For government entities without TIN';
                    StyleExpr = 'Strong';
                }

                label(GovernmentDesc)
                {
                    ApplicationArea = All;
                    Caption = 'Government/Authorities';
                }
            }
        }
    }
}
