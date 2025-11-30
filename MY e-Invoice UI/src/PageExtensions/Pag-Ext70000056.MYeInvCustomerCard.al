pageextension 70000056 "MY eInv Customer Card" extends "Customer Card"
{
    layout
    {
        addafter(General)
        {
            group("MY E-Invoice")
            {
                Caption = 'Malaysian E-Invoice';
                Visible = ShowEInvoiceGroup;

                field("MY eInv Entity Type"; Rec."MY eInv Entity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the customer''s entity type as per LHDN classification.';
                    Importance = Promoted;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        UpdateFieldVisibility();
                    end;
                }

                group("Tax Identification")
                {
                    Caption = 'Tax Identification';
                    Visible = ShowEInvoiceGroup;

                    field("MY eInv TIN"; Rec."MY eInv TIN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Tax Identification Number (TIN). Format: IG + 9-11 digits (Individual) or C + 11 digits (Company). MANDATORY unless using General TIN.';
                        ShowMandatory = not Rec."MY eInv Use General TIN";
                        StyleExpr = TINStyleExpr;
                    }

                    field("MY eInv Use General TIN"; Rec."MY eInv Use General TIN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Enable this if customer does not have TIN (will use General TIN codes based on entity type).';

                        trigger OnValidate()
                        begin
                            UpdateFieldVisibility();
                        end;
                    }

                    field("MY eInv General TIN Code"; Rec."MY eInv General TIN Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Auto-determined General TIN code based on entity type.';
                        StyleExpr = 'Subordinate';
                    }
                }

                group("Business Registration")
                {
                    Caption = 'Business Registration';

                    field("MY eInv BRN"; Rec."MY eInv BRN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Business Registration Number - 12-digit new SSM format (e.g., 202001012345).';
                        ShowMandatory = ShowBusinessFields;
                    }

                    field("MY eInv SST No."; Rec."MY eInv SST No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Sales and Service Tax Registration Number (if applicable).';
                    }

                    field("MY eInv Tourism Tax No."; Rec."MY eInv Tourism Tax No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Tourism Tax Registration Number (for tourism-related businesses).';
                    }

                    field("MY eInv MSIC Code"; Rec."MY eInv MSIC Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Malaysian Standard Industrial Classification Code.';
                    }

                    field("MY eInv MSIC Description"; Rec."MY eInv MSIC Description")
                    {
                        ApplicationArea = All;
                        ToolTip = 'MSIC Code Description.';
                    }

                    field("MY eInv Business Activity"; Rec."MY eInv Business Activity")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Brief description of business activity.';
                    }
                }

                group("Individual Identification")
                {
                    Caption = 'Individual Identification';

                    field("MY eInv NRIC"; Rec."MY eInv NRIC")
                    {
                        ApplicationArea = All;
                        ToolTip = 'NRIC/MyKad Number - 12 digits (YYMMDD-PB-###G format without dashes).';
                        ShowMandatory = ShowMalaysianIndividualFields;
                    }

                    field("MY eInv Passport No."; Rec."MY eInv Passport No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Passport Number (for non-Malaysian individuals).';
                        ShowMandatory = ShowNonMalaysianIndividualFields;
                    }

                    field("MY eInv Army No."; Rec."MY eInv Army No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'MyTentera/Army Number (if applicable).';
                    }
                }

                group("Location Details")
                {
                    Caption = 'Location Details';
                    Visible = ShowEInvoiceGroup;

                    field("MY eInv State Code"; Rec."MY eInv State Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Malaysian State Code (MANDATORY for Malaysian entities).';
                        ShowMandatory = ShowMalaysianLocationFields;
                    }

                    field("MY eInv State Name"; Rec."MY eInv State Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'State Name (auto-filled).';
                    }
                }

                group("E-Invoice Contact")
                {
                    Caption = 'E-Invoice Contact Information';
                    Visible = ShowEInvoiceGroup;

                    field("MY eInv Contact Name"; Rec."MY eInv Contact Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact person name for e-invoice matters.';
                    }

                    field("MY eInv Contact Phone"; Rec."MY eInv Contact Phone")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact phone number.';
                    }

                    field("MY eInv Contact Email"; Rec."MY eInv Contact Email")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact email address (will receive e-invoice copies).';
                    }
                }

                group("Submission Preferences")
                {
                    Caption = 'Submission Preferences';
                    Visible = ShowEInvoiceGroup;

                    field("MY eInv Auto Submit"; Rec."MY eInv Auto Submit")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Automatically submit invoices to MyInvois for this customer.';
                    }

                    field("MY eInv Send Copy"; Rec."MY eInv Send Copy")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Send e-invoice copy to customer after validation.';
                    }

                    field("MY eInv Delivery Method"; Rec."MY eInv Delivery Method")
                    {
                        ApplicationArea = All;
                        ToolTip = 'How the customer prefers to receive e-invoices.';
                    }
                }

                /// <summary>
                /// tax related comeback later on
                /// need to make changes on the vat posting setup
                /// </summary>
                group("Special Cases")
                {
                    Caption = 'Special Cases';
                    Visible = ShowEInvoiceGroup;

                    field("MY eInv Tax Exemption"; Rec."MY eInv Tax Exemption")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Customer has tax exemption.';
                    }

                    field("MY eInv Exemption Cert No."; Rec."MY eInv Exemption Cert No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Tax exemption certificate number.';
                    }

                    field("MY eInv Exemption Reason"; Rec."MY eInv Exemption Reason")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Reason for tax exemption.';
                    }

                    /// <summary>
                    /// will investigate later
                    /// </summary>

                    field("MY eInv Self-Billed"; Rec."MY eInv Self-Billed")
                    {
                        ApplicationArea = All;
                        ToolTip = 'This customer uses self-billed invoices.';
                    }

                    field("MY eInv Self-Billed Agr. No."; Rec."MY eInv Self-Billed Agr. No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Self-billed agreement number.';
                    }
                }
            }
        }
    }

    actions
    {
        addafter(ApprovalEntries)
        {
            group("E-Invoice Actions")
            {
                Caption = 'E-Invoice';
                Image = ElectronicDoc;

                action(ValidateEInvoiceSetup)
                {
                    Caption = 'Validate E-Invoice Setup';
                    ApplicationArea = All;
                    Image = Validate;
                    ToolTip = 'Validate that customer is properly configured for e-invoicing.';

                    trigger OnAction()
                    begin
                        if Rec.ValidateForEInvoice() then
                            Message('✓ Customer %1 is properly configured for e-invoicing!', Rec."No.");
                    end;
                }

                action(ShowGeneralTINInfo)
                {
                    Caption = 'General TIN Information';
                    ApplicationArea = All;
                    Image = Info;
                    ToolTip = 'Show information about General TIN codes.';

                    trigger OnAction()
                    var
                        InfoMsg: Label '4 TYPES OF GENERAL TIN CODES:\\\EI00000000010 - General Public\Use when: Malaysian individual provides only NRIC\\\EI00000000020 - Foreign Buyer/Recipient\Use when: Foreign individual with Passport/MyPR/MyKas\\\EI00000000030 - Foreign Supplier\Use when: Self-billed or import transactions\\\EI00000000040 - Government/Authorities\Use when: Government entity without specific TIN\\\If your customer fits these scenarios, enable "Use General TIN"';
                    begin
                        Message(InfoMsg);
                    end;
                }

                action(ViewTINCategoryReference)
                {
                    Caption = 'TIN Category Reference';
                    ApplicationArea = All;
                    Image = List;
                    ToolTip = 'View complete TIN category reference table.';
                    RunObject = page "MY eInv TIN Category List";
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        eInvEnabled := MYeInvFeaMgmt.IsEInvoiceEnabled();
        UpdateFieldVisibility();
        SetStyles();
    end;

    trigger OnOpenPage()
    begin
        ShowEInvoiceGroup := eInvEnabled;

        UpdateFieldVisibility();
        SetStyles();
    end;

    local procedure UpdateFieldVisibility()
    begin
        ShowGeneralTinField := Rec."MY eInv Use General TIN";

        // Business entities
        ShowBusinessFields := Rec."MY eInv Entity Type" in [
            Rec."MY eInv Entity Type"::"Malaysian Business",
            Rec."MY eInv Entity Type"::"Non-Malaysian Business",
            Rec."MY eInv Entity Type"::Government
        ];

        // Individual entities
        ShowIndividualFields := Rec."MY eInv Entity Type" in [
            Rec."MY eInv Entity Type"::"Malaysian Individual",
            Rec."MY eInv Entity Type"::"Non-Malaysian Individual"
        ];

        // Malaysian specific
        ShowMalaysianIndividualFields := Rec."MY eInv Entity Type" = Rec."MY eInv Entity Type"::"Malaysian Individual";
        ShowNonMalaysianIndividualFields := Rec."MY eInv Entity Type" = Rec."MY eInv Entity Type"::"Non-Malaysian Individual";
        ShowMalaysianLocationFields := Rec.IsMalaysianEntity();
    end;

    local procedure SetStyles()
    begin
        if Rec."MY eInv TIN" <> '' then
            TINStyleExpr := 'Favorable'
        else if Rec."MY eInv Use General TIN" then
            TINStyleExpr := 'Standard'
        else
            TINStyleExpr := 'Unfavorable';
    end;


    var
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";
        eInvEnabled: Boolean;
        ShowEInvoiceGroup: Boolean;
        ShowBusinessFields: Boolean;
        ShowIndividualFields: Boolean;
        ShowMalaysianIndividualFields: Boolean;
        ShowNonMalaysianIndividualFields: Boolean;
        ShowMalaysianLocationFields: Boolean;
        ShowGeneralTinField: Boolean;
        TINStyleExpr: Text;
}
