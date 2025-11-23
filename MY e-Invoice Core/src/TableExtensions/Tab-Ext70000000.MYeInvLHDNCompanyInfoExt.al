tableextension 70000000 "MY eInv LHDN Company Info Ext" extends "Company Information"
{
    fields
    {
        // ═════════════════════════════════════════════════════════════
        // E-Invoice Configuration
        // ═════════════════════════════════════════════════════════════
        field(70000100; "MY eInv Enabled"; Boolean)
        {
            Caption = 'E-Invoice Enabled';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "MY eInv Enabled" then
                    ValidateEInvoiceSetup();
            end;
        }

        field(70000101; "MY eInv Entity Type"; Enum "MY eInv Entity Type")
        {
            Caption = 'Entity Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateRequiredFieldsVisibility();
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // Tax Identification Number (MANDATORY FOR ALL)
        // Format: 13 digits (e.g., IG12345678901)
        // ═════════════════════════════════════════════════════════════
        field(70000102; "MY eInv TIN"; Text[20])
        {
            Caption = 'TIN (Tax Identification Number)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";
            begin
                "MY eInv TIN" := UpperCase(DelChr("MY eInv TIN", '=', ' '));
                MYeInvTINHelper.ValidateTINFormat("MY eInv TIN");
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // Business Registration Number (For Business Entities)
        // NEW FORMAT: 12-digit SSM number (Effective Jan 2023)
        // OLD FORMAT: 6-8 digits with check digit
        // ═════════════════════════════════════════════════════════════
        field(70000103; "MY eInv BRN"; Text[20])
        {
            Caption = 'BRN (Business Registration No.)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";
            begin
                "MY eInv BRN" := DelChr("MY eInv BRN", '=', ' -()');
                MYeInvTINHelper.ValidateBRNFormat("MY eInv BRN");
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // NRIC/MyKad (For Malaysian Individuals)
        // Format: 12 digits (YYMMDD-PB-###G)
        // ═════════════════════════════════════════════════════════════
        field(70000104; "MY eInv NRIC"; Text[14])
        {
            Caption = 'NRIC/MyKad Number';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";
            begin
                "MY eInv NRIC" := DelChr("MY eInv NRIC", '=', ' -');
                MYeInvTINHelper.ValidateNRICFormat("MY eInv NRIC");
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // Passport Number (For Non-Malaysian Individuals)
        // ═════════════════════════════════════════════════════════════
        field(70000105; "MY eInv Passport No."; Text[20])
        {
            Caption = 'Passport Number';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "MY eInv Passport No." := UpperCase(DelChr("MY eInv Passport No.", '=', ' '));
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // MyTentera/Army Number (For Malaysian Military Personnel)
        // ═════════════════════════════════════════════════════════════
        field(70000106; "MY eInv Army No."; Text[20])
        {
            Caption = 'MyTentera/Army Number';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // Sales & Service Tax (SST) Registration
        // ═════════════════════════════════════════════════════════════
        field(70000107; "MY eInv SST No."; Text[20])
        {
            Caption = 'SST Registration Number';
            DataClassification = CustomerContent;
        }

        field(70000108; "MY eInv Tourism Tax No."; Text[20])
        {
            Caption = 'Tourism Tax Registration No.';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // Business Classification (MSIC Code)
        // Malaysian Standard Industrial Classification
        // ═════════════════════════════════════════════════════════════
        field(70000109; "MY eInv MSIC Code"; Code[20])
        {
            Caption = 'MSIC Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(MSIC));

            trigger OnValidate()
            var
                LHDNCode: Record "MY eInv LHDN Code";
            begin
                if "MY eInv MSIC Code" <> '' then begin
                    if LHDNCode.Get(LHDNCode."Code Type"::MSIC, "MY eInv MSIC Code") then begin
                        "MY eInv MSIC Description" := LHDNCode.Description;
                        "MY eInv Business Activity" := LHDNCode.Description;
                    end;
                end else
                    "MY eInv MSIC Description" := '';
            end;
        }

        field(70000110; "MY eInv MSIC Description"; Text[100])
        {
            Caption = 'MSIC Description';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000111; "MY eInv Business Activity"; Text[100])
        {
            Caption = 'Business Activity Description';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // State Code (Required for Malaysian Entities)
        // ═════════════════════════════════════════════════════════════
        field(70000112; "MY eInv State Code"; Code[20])
        {
            Caption = 'State Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("State"));

            trigger OnValidate()
            var
                LHDNCode: Record "MY eInv LHDN Code";
            begin
                if "MY eInv State Code" <> '' then begin
                    if LHDNCode.Get(LHDNCode."Code Type"::State, "MY eInv State Code") then
                        "MY eInv State Name" := LHDNCode.Description;
                end else
                    "MY eInv State Name" := '';
            end;
        }

        field(70000113; "MY eInv State Name"; Text[50])
        {
            Caption = 'State Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // ═════════════════════════════════════════════════════════════
        // Contact Information (For E-Invoice Communication)
        // ═════════════════════════════════════════════════════════════
        field(70000114; "MY eInv Contact Name"; Text[100])
        {
            Caption = 'Contact Person Name';
            DataClassification = CustomerContent;
        }

        field(70000115; "MY eInv Contact Phone"; Text[20])
        {
            Caption = 'Contact Phone Number';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }

        field(70000116; "MY eInv Contact Email"; Text[80])
        {
            Caption = 'Contact Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }


    }

    // ═════════════════════════════════════════════════════════════════
    // Validation Procedures
    // ═════════════════════════════════════════════════════════════════

    local procedure ValidateEInvoiceSetup()
    var
        ConfirmQst: Label 'This will enable Malaysian E-Invoice features for this company.\Do you want to continue?';
        SuccessMsg: Label 'E-Invoice has been enabled.\Please complete the required fields based on your entity type:\• TIN (Mandatory for all)\• BRN (For business entities)\• NRIC (For Malaysian individuals)\• Passport (For non-Malaysian individuals)';
    begin
        if not Confirm(ConfirmQst, false) then begin
            "MY eInv Enabled" := false;
            exit;
        end;

        Message(SuccessMsg);
    end;





    local procedure UpdateRequiredFieldsVisibility()
    begin
        // This would be used in page extensions to show/hide fields
    end;

    // ═════════════════════════════════════════════════════════════════
    // Validation for E-Invoice Submission
    // ═════════════════════════════════════════════════════════════════

    procedure ValidateForEInvoice(): Boolean
    var
        MissingTINErr: Label 'TIN is required for e-invoicing. All taxpayers must have a valid TIN.';
        MissingPhoneErr: Label 'Contact Phone is required for e-invoicing. All taxpayers must have a phone number.';
        MissingBRNErr: Label 'BRN is required for business entities.';
        MissingNRICErr: Label 'NRIC/MyKad is required for Malaysian individuals.';
        MissingPassportErr: Label 'Passport number is required for non-Malaysian individuals.';
        MissingAddressErr: Label 'Company address is required for e-invoicing.';
        MissingCityErr: Label 'City is required for e-invoicing.';
        MissingCountryErr: Label 'Country/Region Code is required for e-invoicing.';
        MissingStateErr: Label 'State Code is required for Malaysian entities.';
        MissingMSICErr: Label 'MSIC Code is required for business entities.';
    begin
        // TIN is MANDATORY for all taxpayers
        if "MY eInv TIN" = '' then
            Error(MissingTINErr);

        if "MY eInv Contact Phone" = '' then
            Error(MissingPhoneErr);

        // Validate based on entity type
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business":
                begin
                    if "MY eInv BRN" = '' then
                        Error(MissingBRNErr);

                    // MSIC code recommended but not mandatory
                    if "MY eInv MSIC Code" = '' then
                        // if not Confirm(MissingMSICErr + '\Do you want to continue without MSIC Code?', false) then
                            Error(MissingMSICErr);
                end;

            "MY eInv Entity Type"::"Malaysian Individual":
                if "MY eInv NRIC" = '' then
                    Error(MissingNRICErr);

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                if "MY eInv Passport No." = '' then
                    Error(MissingPassportErr);

            "MY eInv Entity Type"::Government:
                if "MY eInv BRN" = '' then
                    Error(MissingBRNErr);
        end;

        // Validate address (required for all)
        if Address = '' then
            Error(MissingAddressErr);

        if City = '' then
            Error(MissingCityErr);

        if "Country/Region Code" = '' then
            Error(MissingCountryErr);

        // State code REQUIRED for Malaysian entities
        if IsMalaysianEntity() then
            if "MY eInv State Code" = '' then
                Error(MissingStateErr);

        exit(true);
    end;

    procedure IsMalaysianEntity(): Boolean
    begin
        exit("MY eInv Entity Type" in [
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Malaysian Individual"
        ]);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Get Identification Number for UBL XML
    // ═════════════════════════════════════════════════════════════════

    procedure GetSupplierIdentificationNumber(): Text
    begin
        // Return the appropriate ID based on entity type
        // Priority: TIN → BRN/NRIC/Passport

        // Always return TIN if available
        if "MY eInv TIN" <> '' then
            exit("MY eInv TIN");

        // Fallback to entity-specific IDs
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business",
            "MY eInv Entity Type"::Government:
                if "MY eInv BRN" <> '' then
                    exit("MY eInv BRN");

            "MY eInv Entity Type"::"Malaysian Individual":
                if "MY eInv NRIC" <> '' then
                    exit("MY eInv NRIC");

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                if "MY eInv Passport No." <> '' then
                    exit("MY eInv Passport No.");
        end;

        exit("MY eInv TIN");
    end;

    procedure GetSupplierIdentificationType(): Code[10]
    begin
        // Return the ID type code for UBL XML SchemeID attribute
        // Based on LHDN e-Invoice specifications

        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business",
            "MY eInv Entity Type"::Government:
                exit('BRN'); // Business Registration Number

            "MY eInv Entity Type"::"Malaysian Individual":
                exit('NRIC'); // National Registration Identity Card

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                exit('PASSPORT'); // Passport Number

            else
                exit('TIN'); // Tax Identification Number (default)
        end;
    end;

    // ═════════════════════════════════════════════════════════════════
    // General TIN Codes (Based on LHDN Official Guidelines)
    // ═════════════════════════════════════════════════════════════════

    procedure GetGeneralTINCode(ScenarioCode: Code[20]): Code[20]
    begin
        // General TIN codes for specific scenarios (LHDN Official):
        // EI00000000010 - General Public's TIN
        // EI00000000020 - Foreign Buyer's/Foreign Shipping Recipient's TIN
        // EI00000000030 - Foreign Supplier's TIN
        // EI00000000040 - Government/Government Authorities TIN

        case ScenarioCode of
            'GENERALPUBLIC':
                exit('EI00000000010'); // Local individual with NRIC only, or consolidated e-invoice
            'FOREIGNBUYER':
                exit('EI00000000020'); // Foreign buyer with Passport/MyPR/MyKas, or export transactions
            'FOREIGNSUPPLIER':
                exit('EI00000000030'); // Foreign supplier in self-billed e-invoice or import
            'GOVERNMENT':
                exit('EI00000000040'); // Government entities or exempt institutions without TIN
            else
                exit('');
        end;
    end;

    procedure ShouldUseGeneralTIN(CustomerTIN: Text): Boolean
    begin
        // Determine if General TIN should be used
        // Return TRUE if customer only provided NRIC/Passport without TIN
        exit(CustomerTIN = '');
    end;
}
