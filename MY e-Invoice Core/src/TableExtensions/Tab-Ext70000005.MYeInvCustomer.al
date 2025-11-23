tableextension 70000005 "MY eInv Customer" extends Customer
{
    fields
    {
        // ═════════════════════════════════════════════════════════════
        // CRITICAL: Entity Type (Determines which IDs are required)
        // ═════════════════════════════════════════════════════════════
        field(70000; "MY eInv Entity Type"; Enum "MY eInv Entity Type")
        {
            Caption = 'Entity Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                // Clear identification fields when type changes
                ClearIdentificationFields();
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // TAX IDENTIFICATION NUMBER (MANDATORY FOR ALL)
        // Format: IG + 9-11 digits (Individual) or C + 11 digits (Company)
        // ═════════════════════════════════════════════════════════════
        field(70001; "MY eInv TIN"; Text[20])
        {
            Caption = 'TIN (Tax Identification Number)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";

            begin
                "MY eInv TIN" := UpperCase(DelChr("MY eInv TIN", '=', ' '));
                if "MY eInv TIN" <> '' then
                    MYeInvTINHelper.ValidateTINFormat("MY eInv TIN");
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // BUSINESS REGISTRATION NUMBER (For Business Entities)
        // New format: 12-digit SSM number (since Jan 2023)
        // ═════════════════════════════════════════════════════════════
        field(70002; "MY eInv BRN"; Text[20])
        {
            Caption = 'BRN (Business Registration No.)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";
            begin
                "MY eInv BRN" := DelChr("MY eInv BRN", '=', ' -()');
                if "MY eInv BRN" <> '' then
                    MYeInvTINHelper.ValidateBRNFormat("MY eInv BRN");
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // MALAYSIAN INDIVIDUAL IDENTIFICATION
        // NRIC: 12 digits (YYMMDD-PB-###G format)
        // ═════════════════════════════════════════════════════════════
        field(70003; "MY eInv NRIC"; Text[14])
        {
            Caption = 'NRIC/MyKad Number';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MYeInvTINHelper: Codeunit "MY eInv TIN Helper";
            begin
                "MY eInv NRIC" := DelChr("MY eInv NRIC", '=', ' -');
                if "MY eInv NRIC" <> '' then
                    MYeInvTINHelper.ValidateNRICFormat("MY eInv NRIC");
                if "MY eInv Use General TIN" then
                    DetermineGeneralTINCode();
            end;
        }

        // ═════════════════════════════════════════════════════════════
        // NON-MALAYSIAN INDIVIDUAL IDENTIFICATION
        // ═════════════════════════════════════════════════════════════
        field(70004; "MY eInv Passport No."; Text[20])
        {
            Caption = 'Passport Number';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "MY eInv Passport No." := UpperCase(DelChr("MY eInv Passport No.", '=', ' '));
                if "MY eInv Use General TIN" then
                    DetermineGeneralTINCode();
            end;
        }

        field(70005; "MY eInv Army No."; Text[20])
        {
            Caption = 'MyTentera/Army Number';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if "MY eInv Use General TIN" then
                    DetermineGeneralTINCode();
            end;
        }

        field(70006; "TIN Verified"; Boolean)
        {
            Caption = 'TIN Verified';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70007; "TIN Verification Date"; DateTime)
        {
            Caption = 'TIN Verification Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // ═════════════════════════════════════════════════════════════
        // TAX REGISTRATION (SST, Tourism Tax)
        // ═════════════════════════════════════════════════════════════
        field(70010; "MY eInv SST No."; Text[20])
        {
            Caption = 'SST Registration Number';
            DataClassification = CustomerContent;
        }

        field(70011; "MY eInv Tourism Tax No."; Text[20])
        {
            Caption = 'Tourism Tax Registration No.';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // MSIC CODE (Malaysian Standard Industrial Classification)
        // ═════════════════════════════════════════════════════════════
        field(70020; "MY eInv MSIC Code"; Code[20])
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
                end else begin
                    "MY eInv MSIC Description" := '';
                    "MY eInv Business Activity" := '';
                end;
            end;
        }

        field(70021; "MY eInv MSIC Description"; Text[100])
        {
            Caption = 'MSIC Description';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70022; "MY eInv Business Activity"; Text[100])
        {
            Caption = 'Business Activity Description';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // STATE CODE (MANDATORY for Malaysian Entities)
        // ═════════════════════════════════════════════════════════════
        field(70030; "MY eInv State Code"; Code[20])
        {
            Caption = 'State Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("State"));

            trigger OnValidate()
            var
                LHDNCode: Record "MY eInv LHDN Code";
            begin
                if "MY eInv State Code" <> '' then begin
                    if LHDNCode.Get(LHDNCode."Code Type"::State, "MY eInv State Code") then begin
                        "MY eInv State Name" := LHDNCode.Description;
                        County := LHDNCode.Description; // Update standard BC field
                    end;
                end else
                    "MY eInv State Name" := '';
            end;
        }

        field(70031; "MY eInv State Name"; Text[50])
        {
            Caption = 'State Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // ═════════════════════════════════════════════════════════════
        // CONTACT INFORMATION (For e-Invoice Communication)
        // ═════════════════════════════════════════════════════════════
        field(70040; "MY eInv Contact Name"; Text[100])
        {
            Caption = 'e-Invoice Contact Person';
            DataClassification = CustomerContent;
        }

        field(70041; "MY eInv Contact Phone"; Text[20])
        {
            Caption = 'e-Invoice Contact Phone';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }

        field(70042; "MY eInv Contact Email"; Text[80])
        {
            Caption = 'e-Invoice Contact Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }

        // ═════════════════════════════════════════════════════════════
        // E-INVOICE SUBMISSION PREFERENCES
        // ═════════════════════════════════════════════════════════════
        field(70050; "MY eInv Auto Submit"; Boolean)
        {
            Caption = 'Auto Submit to MyInvois';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(70051; "MY eInv Send Copy"; Boolean)
        {
            Caption = 'Send e-Invoice Copy to Customer';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(70052; "MY eInv Delivery Method"; Enum "MY eInv Delivery Method")
        {
            Caption = 'e-Invoice Delivery Method';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // GENERAL TIN SCENARIOS (For Special Cases)
        // ═════════════════════════════════════════════════════════════
        field(70060; "MY eInv Use General TIN"; Boolean)
        {
            Caption = 'Use General TIN';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "MY eInv Use General TIN" then
                    DetermineGeneralTINCode()
                else
                    Clear("MY eInv General TIN Code");
            end;
        }

        field(70061; "MY eInv General TIN Code"; Code[20])
        {
            Caption = 'General TIN Code';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // ═════════════════════════════════════════════════════════════
        // TAX EXEMPTION
        // ═════════════════════════════════════════════════════════════
        field(70070; "MY eInv Tax Exemption"; Boolean)
        {
            Caption = 'Tax Exemption';
            DataClassification = CustomerContent;
        }

        field(70071; "MY eInv Exemption Cert No."; Text[50])
        {
            Caption = 'Tax Exemption Certificate No.';
            DataClassification = CustomerContent;
        }

        field(70072; "MY eInv Exemption Reason"; Text[100])
        {
            Caption = 'Exemption Reason';
            DataClassification = CustomerContent;
        }

        // ═════════════════════════════════════════════════════════════
        // SELF-BILLED INVOICE
        // ═════════════════════════════════════════════════════════════
        field(70080; "MY eInv Self-Billed"; Boolean)
        {
            Caption = 'Self-Billed Invoice Customer';
            DataClassification = CustomerContent;
        }

        field(70081; "MY eInv Self-Billed Agr. No."; Text[50])
        {
            Caption = 'Self-Billed Agreement No.';
            DataClassification = CustomerContent;
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // VALIDATION PROCEDURES
    // ═════════════════════════════════════════════════════════════════

    local procedure ClearIdentificationFields()
    begin
        // Clear all ID fields when entity type changes
        "MY eInv BRN" := '';
        "MY eInv NRIC" := '';
        "MY eInv Passport No." := '';
        "MY eInv Army No." := '';
    end;

    local procedure DetermineGeneralTINCode()
    begin
        // Determine appropriate General TIN based on entity type and available IDs
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Individual":
                if ("MY eInv TIN" = '') and (("MY eInv NRIC" <> '') or ("MY eInv Passport No." <> '')) then
                    "MY eInv General TIN Code" := 'EI00000000010'; // General Public

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                if ("MY eInv TIN" = '') and ("MY eInv Passport No." <> '') then
                    "MY eInv General TIN Code" := 'EI00000000020'; // Foreign Buyer

            "MY eInv Entity Type"::"Non-Malaysian Business":
                if "MY eInv TIN" = '' then
                    "MY eInv General TIN Code" := 'EI00000000030'; // Foreign Supplier

            "MY eInv Entity Type"::Government:
                if "MY eInv TIN" = '' then
                    "MY eInv General TIN Code" := 'EI00000000040'; // Government
        end;
    end;

    // ═════════════════════════════════════════════════════════════════
    // PUBLIC PROCEDURES FOR E-INVOICE VALIDATION
    // ═════════════════════════════════════════════════════════════════

    procedure ValidateForEInvoice(): Boolean
    var
        MissingTINErr: Label 'TIN is required for customer %1.\If customer does not have TIN, enable "Use General TIN" option.';
        MissingBRNErr: Label 'BRN is required for business entity customer %1.';
        MissingNRICErr: Label 'NRIC is required for Malaysian individual customer %1.';
        MissingPassportErr: Label 'Passport number is required for non-Malaysian individual customer %1.';
        MissingAddressErr: Label 'Address is required for customer %1.';
        MissingCityErr: Label 'City is required for customer %1.';
        MissingCountryErr: Label 'Country/Region Code is required for customer %1.';
        MissingStateErr: Label 'State Code is required for Malaysian customer %1.';
    begin
        // TIN validation (unless using General TIN)
        if not "MY eInv Use General TIN" then begin
            if "MY eInv TIN" = '' then
                Error(MissingTINErr, "No.");
        end;

        // Entity-specific validation
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business":
                if "MY eInv BRN" = '' then
                    Error(MissingBRNErr, "No.");

            "MY eInv Entity Type"::"Malaysian Individual":
                if "MY eInv NRIC" = '' then
                    Error(MissingNRICErr, "No.");

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                if "MY eInv Passport No." = '' then
                    Error(MissingPassportErr, "No.");
        end;

        // Address validation
        if Address = '' then
            Error(MissingAddressErr, "No.");

        if City = '' then
            Error(MissingCityErr, "No.");

        if "Country/Region Code" = '' then
            Error(MissingCountryErr, "No.");

        // State code required for Malaysian entities
        if IsMalaysianEntity() then
            if "MY eInv State Code" = '' then
                Error(MissingStateErr, "No.");

        exit(true);
    end;

    procedure IsMalaysianEntity(): Boolean
    begin
        exit("MY eInv Entity Type" in [
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Malaysian Individual"
        ]);
    end;

    procedure GetCustomerIdentificationNumber(): Text
    begin
        // Return TIN if available
        if "MY eInv TIN" <> '' then
            exit("MY eInv TIN");

        // Use General TIN if enabled
        if "MY eInv Use General TIN" and ("MY eInv General TIN Code" <> '') then
            exit("MY eInv General TIN Code");

        // Fallback to entity-specific IDs
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business":
                if "MY eInv BRN" <> '' then
                    exit("MY eInv BRN");

            "MY eInv Entity Type"::"Malaysian Individual":
                if "MY eInv NRIC" <> '' then
                    exit("MY eInv NRIC");

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                if "MY eInv Passport No." <> '' then
                    exit("MY eInv Passport No.");
        end;

        exit('');
    end;

    procedure GetCustomerIdentificationType(): Code[10]
    begin
        // Return appropriate ID type for UBL XML
        if "MY eInv TIN" <> '' then
            exit('TIN');

        // Use General TIN code if enabled
        if "MY eInv Use General TIN" and ("MY eInv General TIN Code" <> '') then
            exit('TIN'); // General TIN is still a TIN type

        // Entity-specific ID types
        case "MY eInv Entity Type" of
            "MY eInv Entity Type"::"Malaysian Business",
            "MY eInv Entity Type"::"Non-Malaysian Business":
                exit('BRN');

            "MY eInv Entity Type"::"Malaysian Individual":
                exit('NRIC');

            "MY eInv Entity Type"::"Non-Malaysian Individual":
                exit('PASSPORT');

            else
                exit('TIN');
        end;
    end;

    procedure GetCustomerTINForXML(): Text
    begin
        // Priority order for XML submission:
        // 1. Actual TIN if available
        // 2. General TIN if enabled
        // 3. Empty (will cause validation error)

        if "MY eInv TIN" <> '' then
            exit("MY eInv TIN");

        if "MY eInv Use General TIN" and ("MY eInv General TIN Code" <> '') then
            exit("MY eInv General TIN Code");

        exit('');
    end;

}
