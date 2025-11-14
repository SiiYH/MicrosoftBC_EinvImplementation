namespace MYeInvoiceCore.MYeInvoiceCore;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;

tableextension 7000000 "Company Information EINV" extends "Company Information"
{
    fields
    {
        // LHDN Registration Details
        field(50100; "TIN EINV"; Code[20])
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

        field(50101; "BRN EINV"; Code[20])
        {
            Caption = 'Business Registration Number';
            DataClassification = CustomerContent;
        }

        field(50102; "SST Registration No. EINV"; Code[20])
        {
            Caption = 'SST Registration Number';
            DataClassification = CustomerContent;
        }

        field(50103; "Tourism Tax Reg. No. EINV"; Code[20])
        {
            Caption = 'Tourism Tax Registration Number';
            DataClassification = CustomerContent;
        }

        // LHDN e-Invoice Settings
        field(50110; "LHDN Client ID EINV"; Text[100])
        {
            Caption = 'LHDN Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(50111; "LHDN Client Secret EINV"; Text[250])
        {
            Caption = 'LHDN Client Secret';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = Masked;
        }

        field(50112; "LHDN Environment EINV"; Enum "LHDN Environment EINV")
        {
            Caption = 'LHDN Environment';
            DataClassification = CustomerContent;
            InitValue = Sandbox;
        }

        field(50113; "LHDN Certificate EINV"; Blob)
        {
            Caption = 'LHDN Certificate';
            DataClassification = EndUserIdentifiableInformation;
        }

        // MSIC Code (Malaysian Standard Industrial Classification)
        field(50120; "MSIC Code EINV"; Code[10])
        {
            Caption = 'MSIC Code';
            DataClassification = CustomerContent;
            TableRelation = "LHDN MSIC Code EINV";
        }

        field(50121; "MSIC Description EINV"; Text[500])
        {
            Caption = 'MSIC Description';
            FieldClass = FlowField;
            CalcFormula = lookup("LHDN MSIC Code EINV".Description where(Code = field("MSIC Code EINV")));
            Editable = false;
        }

        // Business Activity Description
        field(50122; "Business Activity Desc. EINV"; Text[250])
        {
            Caption = 'Business Activity Description';
            DataClassification = CustomerContent;
        }

        // Address Details (LHDN requires specific format)
        field(50130; "Address Line 3 EINV"; Text[100])
        {
            Caption = 'Address Line 3';
            DataClassification = CustomerContent;
        }

        field(50131; "State Code EINV"; Code[10])
        {
            Caption = 'State Code';
            DataClassification = CustomerContent;
            TableRelation = "LHDN Lookup Code EINV".Code where("Lookup Type" = const("State Code"));
        }

        field(50132; "City EINV"; Text[50])
        {
            Caption = 'City';
            DataClassification = CustomerContent;
        }

        // Contact Details (LHDN requirement)
        field(50140; "Contact Person Name EINV"; Text[100])
        {
            Caption = 'Contact Person Name';
            DataClassification = CustomerContent;
        }

        field(50141; "Contact Person Phone EINV"; Text[20])
        {
            Caption = 'Contact Person Phone';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }

        field(50142; "Contact Person Email EINV"; Text[80])
        {
            Caption = 'Contact Person Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }

        // e-Invoice Configuration
        field(50150; "Auto Submit e-Invoice EINV"; Boolean)
        {
            Caption = 'Auto Submit e-Invoice on Post';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50151; "Batch Submit Time EINV"; Time)
        {
            Caption = 'Batch Submit Time';
            DataClassification = CustomerContent;
        }

        field(50152; "e-Invoice Nos. EINV"; Code[20])
        {
            Caption = 'e-Invoice Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }

        field(50153; "Credit Note Nos. EINV"; Code[20])
        {
            Caption = 'e-Invoice Credit Note Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }

        field(50154; "Debit Note Nos. EINV"; Code[20])
        {
            Caption = 'e-Invoice Debit Note Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }

        // Self-Billed Invoice Settings
        field(50160; "Enable Self-Billed EINV"; Boolean)
        {
            Caption = 'Enable Self-Billed e-Invoice';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50161; "Self-Billed Prefix EINV"; Code[10])
        {
            Caption = 'Self-Billed Document Prefix';
            DataClassification = CustomerContent;
        }

        // Consolidated Invoice Settings
        field(50170; "Enable Consolidated EINV"; Boolean)
        {
            Caption = 'Enable Consolidated e-Invoice';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(50171; "Consolidation Period EINV"; Enum "Consolidation Period EINV")
        {
            Caption = 'Consolidation Period';
            DataClassification = CustomerContent;
        }
    }
}
