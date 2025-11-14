namespace MYeInvoiceCore.MYeInvoiceCore;

using Microsoft.Purchases.Vendor;

tableextension 7000002 VendorEINV extends Vendor
{
    fields
    {
        // LHDN Vendor Classification
        field(50100; "Vendor Type EINV"; Enum "Entity Type EINV")
        {
            Caption = 'Vendor Type';
            DataClassification = CustomerContent;
            InitValue = ' ';

            trigger OnValidate()
            begin
                ValidateVendorTypeFields();
            end;
        }

        // TIN (Tax Identification Number)
        field(50101; "TIN EINV"; Code[20])
        {
            Caption = 'Tax Identification Number (TIN)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                TINValidator: Codeunit "TIN Validator EINV";
            begin
                if "TIN EINV" <> '' then
                    TINValidator.ValidateTIN("TIN EINV");
            end;
        }

        field(50102; "TIN Type EINV"; Enum "TIN Type EINV")
        {
            Caption = 'TIN Type';
            DataClassification = CustomerContent;
        }

        // Business Registration Number
        field(50103; "BRN EINV"; Code[20])
        {
            Caption = 'Business Registration Number';
            DataClassification = CustomerContent;
        }

        // SST Registration
        field(50104; "SST Registration No. EINV"; Code[20])
        {
            Caption = 'SST Registration Number';
            DataClassification = CustomerContent;
        }

        // NRIC/Passport (for individuals)
        field(50105; "ID Type EINV"; Enum "ID Type EINV")
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
        }

        field(50106; "ID No. EINV"; Code[30])
        {
            Caption = 'ID Number (NRIC/Passport)';
            DataClassification = CustomerContent;
        }

        // Address Details (LHDN specific)
        field(50110; "Address Line 3 EINV"; Text[100])
        {
            Caption = 'Address Line 3';
            DataClassification = CustomerContent;
        }

        field(50111; "State Code EINV"; Code[10])
        {
            Caption = 'State Code';
            DataClassification = CustomerContent;
            TableRelation = "LHDN Lookup Code EINV".Code where("Lookup Type" = const("State Code"));
        }

        field(50112; "City EINV"; Text[50])
        {
            Caption = 'City';
            DataClassification = CustomerContent;
        }

        // Contact Details
        field(50120; "Contact Person Name EINV"; Text[100])
        {
            Caption = 'Contact Person Name';
            DataClassification = CustomerContent;
        }

        field(50121; "Contact Person Phone EINV"; Text[20])
        {
            Caption = 'Contact Person Phone';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }

        field(50122; "Contact Person Email EINV"; Text[80])
        {
            Caption = 'Contact Person Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }

        // MSIC Code (for business customers)
        field(50130; "MSIC Code EINV"; Code[10])
        {
            Caption = 'MSIC Code';
            DataClassification = CustomerContent;
            TableRelation = "LHDN MSIC Code EINV";
        }

        field(50131; "MSIC Description EINV"; Text[500])
        {
            Caption = 'MSIC Description';
            FieldClass = FlowField;
            CalcFormula = lookup("LHDN MSIC Code EINV".Description where(Code = field("MSIC Code EINV")));
            Editable = false;
        }

        // Business Activity (for business customers)
        field(50132; "Business Activity Desc. EINV"; Text[250])
        {
            Caption = 'Business Activity Description';
            DataClassification = CustomerContent;
        }

        // e-Invoice Settings
        field(50140; "Exempt from e-Invoice EINV"; Boolean)
        {
            Caption = 'Exempt from e-Invoice';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50141; "Exemption Reason EINV"; Text[250])
        {
            Caption = 'Exemption Reason';
            DataClassification = CustomerContent;
        }

        field(50142; "Self-Billed Customer EINV"; Boolean)
        {
            Caption = 'Self-Billed Customer';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        // Consolidated Invoice
        field(50150; "Consolidate e-Invoice EINV"; Boolean)
        {
            Caption = 'Consolidate e-Invoice';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50151; "Consolidation Period EINV"; Enum "Consolidation Period EINV")
        {
            Caption = 'Consolidation Period';
            DataClassification = CustomerContent;
        }

        // Foreign Customer
        field(50160; "Foreign Vendor EINV"; Boolean)
        {
            Caption = 'Foreign Vendor';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50161; "Foreign Tax ID EINV"; Code[30])
        {
            Caption = 'Foreign Tax ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key50100; "Vendor Type EINV")
        {
        }
        key(Key50101; "TIN EINV")
        {
        }
    }

    local procedure ValidateVendorTypeFields()
    begin
        case "Vendor Type EINV" of
            "Vendor Type EINV"::"Foreign Individual",
            "Vendor Type EINV"::"Malaysian Individual":
                begin
                    // Individual: NRIC/Passport mandatory
                    if "ID No. EINV" = '' then
                        Error('ID Number is required for Individual Vendors');
                end;
            "Vendor Type EINV"::"Foreign Business",
            "Vendor Type EINV"::"Malaysian Business":
                begin
                    // Business: TIN mandatory
                    if "TIN EINV" = '' then
                        Error('TIN is required for Business Vendors');
                end;
        end;
    end;
}