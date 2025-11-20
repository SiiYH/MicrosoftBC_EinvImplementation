tableextension 70000000 "MY eInv LHDN Company Info Ext" extends "Company Information"
{
    fields
    {
        // === Core Company Identification for E-Invoice ===
        field(70000001; "E-Invoice TIN"; Text[20])
        {
            Caption = 'Tax Identification Number (TIN)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "E-Invoice TIN" <> '' then
                    ValidateTIN();
            end;
        }

        field(70000002; "E-Invoice ID Type"; Enum "MY eInv ID Type")
        {
            Caption = 'Identification Type';
            DataClassification = CustomerContent;
            InitValue = TIN;
        }

        field(70000003; "E-Invoice ID Value"; Text[50])
        {
            Caption = 'Identification Value';
            DataClassification = CustomerContent;
        }

        field(70000004; "E-Invoice BRN"; Text[20])
        {
            Caption = 'Business Registration Number (BRN)';
            DataClassification = CustomerContent;
        }

        field(70000005; "E-Invoice SST No."; Text[20])
        {
            Caption = 'SST Registration Number';
            DataClassification = CustomerContent;
        }

        field(70000006; "E-Invoice TTx No."; Text[20])
        {
            Caption = 'Tourism Tax Registration Number';
            DataClassification = CustomerContent;
        }

        // === Business Classification ===
        field(70000010; "E-Invoice MSIC Code"; Code[10])
        {
            Caption = 'MSIC Code';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code"."Code" where("Code Type" = const(MSIC), Active = const(true));

            trigger OnValidate()
            var
                LHDNCode: Record "MY eInv LHDN Code";
            begin
                if "E-Invoice MSIC Code" <> '' then begin
                    LHDNCode.Get("E-Invoice MSIC Code", LHDNCode."Code Type"::MSIC);
                    "E-Invoice MSIC Description" := LHDNCode.Description;
                end else
                    "E-Invoice MSIC Description" := '';
            end;
        }

        field(70000011; "E-Invoice MSIC Description"; Text[100])
        {
            Caption = 'MSIC Description';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000012; "E-Invoice Business Activity"; Text[100])
        {
            Caption = 'Business Activity Description';
            DataClassification = CustomerContent;
        }

        // === Address for E-Invoice (May differ from standard address) ===
        field(70000020; "E-Invoice Address"; Text[100])
        {
            Caption = 'E-Invoice Address Line 1';
            DataClassification = CustomerContent;
        }

        field(70000021; "E-Invoice Address 2"; Text[100])
        {
            Caption = 'E-Invoice Address Line 2';
            DataClassification = CustomerContent;
        }

        field(70000022; "E-Invoice Address 3"; Text[100])
        {
            Caption = 'E-Invoice Address Line 3';
            DataClassification = CustomerContent;
        }

        field(70000023; "E-Invoice City"; Text[50])
        {
            Caption = 'E-Invoice City';
            DataClassification = CustomerContent;
        }

        field(70000024; "E-Invoice State"; Code[20])
        {
            Caption = 'E-Invoice State';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code"."Code" where("Code Type" = const(State), Active = const(true));
        }

        field(70000025; "E-Invoice Post Code"; Code[20])
        {
            Caption = 'E-Invoice Post Code';
            DataClassification = CustomerContent;
        }

        field(70000026; "E-Invoice Country/Region"; Code[10])
        {
            Caption = 'E-Invoice Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }

        // === Contact Information ===
        field(70000030; "E-Invoice Contact Number"; Text[20])
        {
            Caption = 'E-Invoice Contact Number';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }

        field(70000031; "E-Invoice Email"; Text[80])
        {
            Caption = 'E-Invoice Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }

        // === Default Settings ===
        field(70000040; "E-Invoice Default Currency"; Code[10])
        {
            Caption = 'Default Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
            InitValue = 'MYR';
        }

        field(70000041; "E-Invoice Default Doc Type"; Enum "MY eInv Document Type")
        {
            Caption = 'Default Document Type';
            DataClassification = CustomerContent;
        }

        field(70000042; "E-Invoice Default Class"; Enum "MY eInv Classification")
        {
            Caption = 'Default Classification';
            DataClassification = CustomerContent;
        }

        // === Validation Flags ===
        field(70000050; "E-Invoice Setup Complete"; Boolean)
        {
            Caption = 'E-Invoice Setup Complete';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70000051; "E-Invoice Last Validated"; DateTime)
        {
            Caption = 'Last Configuration Validation';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    local procedure ValidateTIN()
    var
        InvalidTINErr: Label 'Invalid TIN format. TIN must be in format:\- C + 14 digits (e.g., C12345678901234) for Malaysian companies\- IG + 14 digits (e.g., IG12345678901234) for non-residents';
        Char1: Text[1];
    begin
        // TIN should be 15 characters
        if StrLen("E-Invoice TIN") <> 15 then
            Error(InvalidTINErr);

        Char1 := CopyStr("E-Invoice TIN", 1, 1);

        // First character must be 'C' for companies or 'I' for individuals/non-residents
        if not (Char1 in ['C', 'I']) then
            Error(InvalidTINErr);

        // If starts with 'I', second character should be 'G'
        if (Char1 = 'I') and (CopyStr("E-Invoice TIN", 2, 1) <> 'G') then
            Error(InvalidTINErr);
    end;

    procedure ValidateEInvoiceSetup(): Boolean
    var
        EInvSetup: Record "MY eInv Setup";
        CompanyInfo: Record "Company Information";
        ValidationMsg: Text;
        IsValid: Boolean;
    begin
        IsValid := true;
        ValidationMsg := '';

        CompanyInfo.Get();

        // Check TIN
        if CompanyInfo."E-Invoice TIN" = '' then begin
            ValidationMsg += '- Tax Identification Number (TIN) is required\';
            IsValid := false;
        end;

        // Check BRN
        if CompanyInfo."E-Invoice BRN" = '' then begin
            ValidationMsg += '- Business Registration Number (BRN) is required\';
            IsValid := false;
        end;

        // Check MSIC Code
        if CompanyInfo."E-Invoice MSIC Code" = '' then begin
            ValidationMsg += '- MSIC Code is required\';
            IsValid := false;
        end;

        // Check Address
        if (CompanyInfo."E-Invoice Address" = '') and (CompanyInfo.Address = '') then begin
            ValidationMsg += '- Business address is required\';
            IsValid := false;
        end;

        // Check Setup Table
        if not EInvSetup.Get() then begin
            ValidationMsg += '- E-Invoice Setup record is missing. Please run E-Invoice Setup.\';
            IsValid := false;
        end else begin
            // Check API Credentials
            if (EInvSetup.GetClientID() = '') or (EInvSetup.GetClientSecret() = '') then begin
                ValidationMsg += '- MyInvois API credentials are not configured\';
                IsValid := false;
            end;

            // Check Certificate for Document Version 1.1
            if (EInvSetup."Document Version" = EInvSetup."Document Version"::"1.1") and
               (not EInvSetup.HasCertificate())
            then begin
                ValidationMsg += '- Digital certificate is required for Document Version 1.1\';
                IsValid := false;
            end;

            // Check Azure Function for signing
            if (EInvSetup."Document Version" = EInvSetup."Document Version"::"1.1") and
               ((EInvSetup."Azure Function URL" = '') or (EInvSetup.GetAzureFunctionKey() = ''))
            then begin
                ValidationMsg += '- Azure Function signing service is not configured\';
                IsValid := false;
            end;
        end;

        CompanyInfo."E-Invoice Setup Complete" := IsValid;
        CompanyInfo."E-Invoice Last Validated" := CurrentDateTime;
        CompanyInfo.Modify();

        if not IsValid then
            Message('E-Invoice setup is incomplete:\%1\Please complete the setup before submitting invoices.', ValidationMsg)
        else
            Message('E-Invoice setup validation passed successfully!');

        exit(IsValid);
    end;

    procedure CopyStandardAddressToEInvoice()
    var
        CompanyInfo: Record "Company Information";
        ConfirmQst: Label 'This will copy the standard company address to E-Invoice address fields. Continue?';
    begin
        if not Confirm(ConfirmQst, false) then
            exit;

        CompanyInfo.Get();
        CompanyInfo."E-Invoice Address" := CompanyInfo.Address;
        CompanyInfo."E-Invoice Address 2" := CompanyInfo."Address 2";
        CompanyInfo."E-Invoice City" := CompanyInfo.City;
        CompanyInfo."E-Invoice Post Code" := CompanyInfo."Post Code";
        CompanyInfo."E-Invoice Country/Region" := CompanyInfo."Country/Region Code";

        if CompanyInfo."Phone No." <> '' then
            CompanyInfo."E-Invoice Contact Number" := CompanyInfo."Phone No.";

        if CompanyInfo."E-Mail" <> '' then
            CompanyInfo."E-Invoice Email" := CompanyInfo."E-Mail";

        CompanyInfo.Modify(true);
        Message('Company address has been copied to E-Invoice fields.');
    end;

    procedure GetEInvoiceAddress(var Address1: Text[100]; var Address2: Text[100]; var Address3: Text[100]; var City: Text[50]; var PostCode: Code[20]; var StateCode: Code[20]; var CountryCode: Code[10])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        // Use E-Invoice specific address if filled, otherwise fall back to standard address
        if CompanyInfo."E-Invoice Address" <> '' then
            Address1 := CompanyInfo."E-Invoice Address"
        else
            Address1 := CompanyInfo.Address;

        if CompanyInfo."E-Invoice Address 2" <> '' then
            Address2 := CompanyInfo."E-Invoice Address 2"
        else
            Address2 := CompanyInfo."Address 2";

        Address3 := CompanyInfo."E-Invoice Address 3";

        if CompanyInfo."E-Invoice City" <> '' then
            City := CompanyInfo."E-Invoice City"
        else
            City := CompanyInfo.City;

        if CompanyInfo."E-Invoice Post Code" <> '' then
            PostCode := CompanyInfo."E-Invoice Post Code"
        else
            PostCode := CompanyInfo."Post Code";

        StateCode := CompanyInfo."E-Invoice State";

        if CompanyInfo."E-Invoice Country/Region" <> '' then
            CountryCode := CompanyInfo."E-Invoice Country/Region"
        else
            CountryCode := CompanyInfo."Country/Region Code";
    end;

    procedure ShowSetupStatus()
    var
        EInvSetup: Record "MY eInv Setup";
        StatusMsg: Text;
        TINStatus: Text;
        CertStatus: Text;
        APIStatus: Text;
        AzureStatus: Text;
    begin
        // TIN Status
        if "E-Invoice TIN" <> '' then
            TINStatus := '✓ Configured'
        else
            TINStatus := '✗ Missing';

        // Certificate Status
        if EInvSetup.Get() and EInvSetup.HasCertificate() then
            CertStatus := StrSubstNo('✓ Valid until %1', Format(EInvSetup."Certificate Valid To"))
        else
            CertStatus := '✗ Not configured';

        // API Status
        if EInvSetup.Get() and (EInvSetup.GetClientID() <> '') then begin
            if EInvSetup.IsTokenValid() then
                APIStatus := '✓ Connected'
            else
                APIStatus := '⚠ Token expired';
        end else
            APIStatus := '✗ Not configured';

        // Azure Function Status
        if EInvSetup.Get() and (EInvSetup."Azure Function URL" <> '') then
            AzureStatus := '✓ Configured'
        else
            AzureStatus := '✗ Not configured';

        StatusMsg := StrSubstNo(
            'E-Invoice Setup Status:\' +
            'TIN: %1\' +
            'Digital Certificate: %2\' +
            'MyInvois API: %3\' +
            'Azure Signing Service: %4\' +
            '\Setup Complete: %5',
            TINStatus, CertStatus, APIStatus, AzureStatus,
            Format("E-Invoice Setup Complete"));

        Message(StatusMsg);
    end;
}
