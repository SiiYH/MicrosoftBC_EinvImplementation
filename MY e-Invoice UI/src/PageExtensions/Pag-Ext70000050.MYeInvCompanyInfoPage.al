pageextension 70000050 "MY eInv Company Info Page" extends "Company Information"
{
    layout
    {
        addafter(General)
        {
            group("MY E-Invoice")
            {
                Caption = 'Malaysian E-Invoice (LHDN MyInvois)';

                field("MY eInv Enabled"; Rec."MY eInv Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable Malaysian E-Invoice features for this company.';
                    StyleExpr = EInvoiceStyleExpr;
                }

                field("MY eInv Entity Type"; Rec."MY eInv Entity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select your entity type as registered with LHDN.';
                    Importance = Promoted;
                    Enabled = Rec."MY eInv Enabled";
                    ShowMandatory = Rec."MY eInv Enabled";

                    trigger OnValidate()
                    begin
                        UpdateFieldVisibility();
                    end;
                }

                group("Tax Identification")
                {
                    Caption = 'Tax Identification (MANDATORY)';
                    Visible = Rec."MY eInv Enabled";

                    field("MY eInv TIN"; Rec."MY eInv TIN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Tax Identification Number (TIN) - 13 digits. Format: IG12345678901 (Individual) or C123456789012 (Company). MANDATORY for all taxpayers.';
                        Importance = Promoted;
                        ShowMandatory = true;
                    }
                }

                group("Business Registration")
                {
                    Caption = 'Business Registration (For Companies)';
                    Visible = ShowBusinessFields;

                    field("MY eInv BRN"; Rec."MY eInv BRN")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Business Registration Number - New 12-digit SSM format (e.g., 202001012345) or old format with check digit.';
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
                        ToolTip = 'Tourism Tax Registration Number (for hotels and tourism-related businesses).';
                    }

                    field("MY eInv MSIC Code"; Rec."MY eInv MSIC Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Malaysian Standard Industrial Classification Code (recommended for business classification).';
                    }

                    field("MY eInv MSIC Description"; Rec."MY eInv MSIC Description")
                    {
                        ApplicationArea = All;
                        ToolTip = 'MSIC Code Description.';
                    }

                    field("MY eInv Business Activity"; Rec."MY eInv Business Activity")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Brief description of your business activity.';
                    }
                }

                group("Individual Identification")
                {
                    Caption = 'Individual Identification';
                    Visible = ShowIndividualFields;

                    field("MY eInv NRIC"; Rec."MY eInv NRIC")
                    {
                        ApplicationArea = All;
                        ToolTip = 'NRIC/MyKad Number - 12 digits (format: YYMMDD-PB-###G without dashes).';
                        Visible = ShowMalaysianIndividualFields;
                        ShowMandatory = ShowMalaysianIndividualFields;
                    }

                    field("MY eInv Passport No."; Rec."MY eInv Passport No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Passport Number (for non-Malaysian individuals).';
                        Visible = ShowNonMalaysianIndividualFields;
                        ShowMandatory = ShowNonMalaysianIndividualFields;
                    }

                    field("MY eInv Army No."; Rec."MY eInv Army No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'MyTentera/Army Number (for Malaysian military personnel).';
                        Visible = ShowMalaysianIndividualFields;
                    }
                }

                group("Location Details")
                {
                    Caption = 'Location Details';
                    Visible = Rec."MY eInv Enabled";

                    field("MY eInv State Code"; Rec."MY eInv State Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Malaysian State Code (MANDATORY for Malaysian entities). Select from LHDN Code table.';
                        Visible = ShowMalaysianLocationFields;
                        ShowMandatory = ShowMalaysianLocationFields;
                    }

                    field("MY eInv State Name"; Rec."MY eInv State Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'State Name (auto-filled based on State Code).';
                        Visible = ShowMalaysianLocationFields;
                    }
                }

                group("Contact Information")
                {
                    Caption = 'Contact Information (For E-Invoice)';
                    Visible = Rec."MY eInv Enabled";

                    field("MY eInv Contact Name"; Rec."MY eInv Contact Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact person name for e-invoice related matters.';
                    }

                    field("MY eInv Contact Phone"; Rec."MY eInv Contact Phone")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact phone number.';
                    }

                    field("MY eInv Contact Email"; Rec."MY eInv Contact Email")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Contact email address (will receive e-invoice notifications).';
                    }
                }
            }
        }
    }

    actions
    {
        addafter(Codes)
        {
            group("MY E-Invoice Actions")
            {
                Caption = 'E-Invoice';
                Image = ElectronicDoc;

                action(ValidateEInvoiceSetup)
                {
                    Caption = 'Validate E-Invoice Setup';
                    ApplicationArea = All;
                    Image = Validate;
                    ToolTip = 'Validate that all required fields are correctly filled according to LHDN requirements.';

                    trigger OnAction()
                    begin
                        if Rec.ValidateForEInvoice() then
                            Message('✓ E-Invoice setup is valid and complete!\All required fields are properly configured for MyInvois submission.');
                    end;
                }

                action(OpenEInvoiceSetup)
                {
                    Caption = 'E-Invoice Setup';
                    ApplicationArea = All;
                    Image = Setup;
                    ToolTip = 'Open E-Invoice setup page to configure MyInvois integration.';
                    RunObject = page "MY eInv Setup Card";
                }

                action(ShowGeneralTINInfo)
                {
                    Caption = 'General TIN Codes Info';
                    ApplicationArea = All;
                    Image = Info;
                    ToolTip = 'Show information about General TIN codes for special scenarios.';

                    trigger OnAction()
                    var
                        InfoMsg: Label 'GENERAL TIN CODES (For Special Scenarios):\\\EI00000000010\Use for: Malaysian individual providing only MyKad/MyTentera\Example: Buyer provides NRIC without TIN\\\EI00000000020\Use for: Non-Malaysian individual (Passport/MyPR/MyKAS)\Example: Foreign buyer/export transactions\\\EI00000000030\Use for: Non-Malaysian supplier (Self-billed e-invoice)\Example: Import from foreign supplier\\\EI00000000040\Use for: Government entity without specific TIN\Example: Sales to government agencies';
                    begin
                        Message(InfoMsg);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateFieldVisibility();
        SetStyles();
    end;

    local procedure UpdateFieldVisibility()
    begin
        // Business entities (Malaysian/Foreign/Government)
        ShowBusinessFields := Rec."MY eInv Entity Type" in [
            Rec."MY eInv Entity Type"::"Malaysian Business",
            Rec."MY eInv Entity Type"::"Non-Malaysian Business",
            Rec."MY eInv Entity Type"::Government
        ];

        // Individual entities (Malaysian/Foreign)
        ShowIndividualFields := Rec."MY eInv Entity Type" in [
            Rec."MY eInv Entity Type"::"Malaysian Individual",
            Rec."MY eInv Entity Type"::"Non-Malaysian Individual"
        ];

        // Malaysian specific fields
        ShowMalaysianIndividualFields := Rec."MY eInv Entity Type" = Rec."MY eInv Entity Type"::"Malaysian Individual";
        ShowNonMalaysianIndividualFields := Rec."MY eInv Entity Type" = Rec."MY eInv Entity Type"::"Non-Malaysian Individual";
        ShowMalaysianLocationFields := Rec.IsMalaysianEntity();
    end;

    local procedure SetStyles()
    begin
        if Rec."MY eInv Enabled" then
            EInvoiceStyleExpr := 'Favorable'
        else
            EInvoiceStyleExpr := 'Standard';
    end;

    var
        ShowBusinessFields: Boolean;
        ShowIndividualFields: Boolean;
        ShowMalaysianIndividualFields: Boolean;
        ShowNonMalaysianIndividualFields: Boolean;
        ShowMalaysianLocationFields: Boolean;
        EInvoiceStyleExpr: Text;
}
