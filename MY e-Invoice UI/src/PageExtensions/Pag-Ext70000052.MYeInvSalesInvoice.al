pageextension 70000052 "MY eInv Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addafter("No.")
        {
            field("MY eInv Type Code"; Rec."MY eInv Type Code")
            {
                ApplicationArea = All;
                ToolTip = 'Select the e-invoice type code from LHDN reference table.';
                Importance = Promoted;
                ShowMandatory = true;

                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }

            field("MY eInv Type Description"; Rec."MY eInv Type Description")
            {
                ApplicationArea = All;
                ToolTip = 'E-Invoice type description (auto-filled).';
                Editable = false;
            }
        }

        addlast(General)
        {
            group("E-Invoice Information")
            {
                Caption = 'E-Invoice Information';
                Visible = ShowEInvoiceGroup;

                field("E-Invoice Format"; EInvoiceFormat)
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Format';
                    ToolTip = 'Format used for e-invoice submission (XML or JSON).';
                    Editable = false;
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    var
                        InfoMsg: Label 'This document will be submitted in XML format (UBL 2.1).\Both XML and JSON are supported by MyInvois, but XML is recommended for:\• Better digital signature support\• Mature ERP integration\• Strict validation rules';
                    begin
                        Message(InfoMsg);
                    end;
                }

                field("E-Invoice Version"; EInvoiceVersion)
                {
                    ApplicationArea = All;
                    Caption = 'Document Version';
                    ToolTip = 'E-Invoice document version (1.0 = no signature, 1.1 = with signature).';
                    Editable = false;
                }
            }
            group("E-Invoice Submission Options")
            {
                Caption = 'Submission Options';
                Visible = ShowEInvoiceGroup;

                field("MY eInv Submit On Post"; Rec."MY eInv Submit On Post")
                {
                    ApplicationArea = All;
                    Caption = 'Submit to MyInvois on Post';
                    ToolTip = 'If enabled, the invoice will be automatically submitted to MyInvois after posting.';
                    StyleExpr = SubmitOnPostStyleExpr;
                }

                field("Submit Status Info"; SubmitStatusInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Submission Status';
                    ToolTip = 'Shows whether e-invoice will be submitted automatically.';
                    Editable = false;
                    StyleExpr = SubmitStatusStyleExpr;
                }
            }
        }
    }

    actions
    {
        addafter(Post)
        {
            group("E-Invoice")
            {
                Caption = 'E-Invoice';
                Image = ElectronicDoc;

                action(ValidateEInvoiceRequirements)
                {
                    Caption = 'Validate E-Invoice Requirements';
                    ApplicationArea = All;
                    Image = Validate;
                    ToolTip = 'Validate that all required fields are filled before posting.';
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        ValidateEInvoiceRequirements();
                        Message('✓ E-Invoice validation passed!\All required fields are properly configured.');
                    end;
                }

                action(PreviewEInvoiceXML)
                {
                    Caption = 'Preview E-Invoice XML';
                    ApplicationArea = All;
                    Image = XMLFile;
                    ToolTip = 'Generate and preview the UBL 2.1 XML that will be submitted to MyInvois.';

                    trigger OnAction()
                    begin
                        PreviewEInvoiceXML();
                    end;
                }

                action(TestDigitalSignature)
                {
                    Caption = 'Test Digital Signature';
                    ApplicationArea = All;
                    Image = Certificate;
                    ToolTip = 'Test the digital signature with sample XML.';

                    trigger OnAction()
                    begin
                        TestDigitalSignature();
                    end;
                }

                action(OpenEInvoiceSetup)
                {
                    Caption = 'E-Invoice Setup';
                    ApplicationArea = All;
                    Image = Setup;
                    ToolTip = 'Open E-Invoice setup page.';
                    RunObject = page "MY eInv Setup Card";
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEInvoiceInfo();
        UpdateSubmitStatus();
    end;

    local procedure UpdateEInvoiceInfo()
    var
        Setup: Record "MY eInv Setup";
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ShowEInvoiceGroup := CompanyInfo."MY eInv Enabled";

        if Setup.Get() then begin
            EInvoiceFormat := 'XML (UBL 2.1)';

            case Setup."Document Version" of
                Setup."Document Version"::"1.0":
                    EInvoiceVersion := 'v1.0 (No Digital Signature)';
                Setup."Document Version"::"1.1":
                    EInvoiceVersion := 'v1.1 (With Digital Signature)';
            end;
        end else begin
            EInvoiceFormat := 'Not Configured';
            EInvoiceVersion := 'Not Configured';
        end;
    end;

    local procedure ValidateEInvoiceRequirements()
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        MissingTypeCodeErr: Label 'E-Invoice Type Code is required. Please select a type code before posting.';
        InvalidCustomerErr: Label 'Customer %1 is not properly configured for e-invoicing:\%2';
        ErrorList: Text;
    begin
        // Validate e-invoice type code
        if Rec."MY eInv Type Code" = '' then
            Error(MissingTypeCodeErr);

        // Validate company info
        CompanyInfo.Get();
        CompanyInfo.ValidateForEInvoice();

        // Validate customer
        if not Customer.Get(Rec."Bill-to Customer No.") then
            exit;

        ErrorList := ValidateCustomerForEInvoice(Customer);
        if ErrorList <> '' then
            Error(InvalidCustomerErr, Customer."No.", ErrorList);
    end;

    local procedure ValidateCustomerForEInvoice(Customer: Record Customer): Text
    var
        ErrorMsg: Text;
    begin
        if Customer."MY eInv TIN" = '' then
            ErrorMsg += '• TIN is required\';

        if Customer.Address = '' then
            ErrorMsg += '• Address is required\';

        if Customer.City = '' then
            ErrorMsg += '• City is required\';

        if Customer."Country/Region Code" = '' then
            ErrorMsg += '• Country/Region Code is required\';

        // State required for Malaysian customers
        if (Customer."Country/Region Code" = 'MY') and (Customer."MY eInv State Code" = '') then
            ErrorMsg += '• State Code is required for Malaysian customers\';

        exit(ErrorMsg);
    end;

    local procedure PreviewEInvoiceXML()
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        XMLGenerator: Codeunit "MY eInv XML Generator";
        XMLText: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        ToFile: Text;
    begin
        // Create temporary posted invoice for preview
        TempSalesInvoiceHeader.TransferFields(Rec);
        TempSalesInvoiceHeader."No." := 'PREVIEW-' + Rec."No.";
        TempSalesInvoiceHeader."MY eInv Type Code" := Rec."MY eInv Type Code";
        TempSalesInvoiceHeader.Insert();

        // Generate XML
        XMLText := XMLGenerator.GenerateInvoiceXML(TempSalesInvoiceHeader);

        // Save to temp file and download
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        ToFile := 'Preview_' + Rec."No." + '.xml';

        DownloadFromStream(InStream, 'Preview XML', '', 'XML Files (*.xml)|*.xml', ToFile);
    end;

    local procedure TestDigitalSignature()
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        XMLGenerator: Codeunit "MY eInv XML Generator";

        Setup: Record "MY eInv Setup";
        DigitalSignature: Codeunit "MY eInv Digital Signature";
        XMLText: Text;
    begin
        // Create temporary posted invoice for preview
        TempSalesInvoiceHeader.TransferFields(Rec);
        TempSalesInvoiceHeader."No." := 'PREVIEW-' + Rec."No.";
        TempSalesInvoiceHeader."MY eInv Type Code" := Rec."MY eInv Type Code";
        TempSalesInvoiceHeader.Insert();

        // Generate XML
        XMLText := XMLGenerator.GenerateInvoiceXML(TempSalesInvoiceHeader);
        Setup.Get();
        DigitalSignature.TestCertificate(Setup, XMLText);
    end;

    local procedure UpdateSubmitStatus()
    var
        Setup: Record "MY eInv Setup";
    begin
        if not Setup.Get() then
            exit;

        if Setup."Enable Auto Submission" and Setup."Auto Submit on Posting" then begin
            SubmitStatusInfo := '✓ Auto-submission enabled (from setup)';
            SubmitStatusStyleExpr := 'Favorable';
        end else if Rec."MY eInv Submit On Post" then begin
            SubmitStatusInfo := '✓ Will submit to MyInvois on post';
            SubmitStatusStyleExpr := 'Favorable';
        end else begin
            SubmitStatusInfo := '⚠ Manual submission required after post';
            SubmitStatusStyleExpr := 'Ambiguous';
        end;

        if Rec."MY eInv Submit On Post" then
            SubmitOnPostStyleExpr := 'Favorable'
        else
            SubmitOnPostStyleExpr := 'Standard';
    end;

    var
        ShowEInvoiceGroup: Boolean;
        EInvoiceFormat: Text;
        EInvoiceVersion: Text;
        SubmitStatusInfo: Text;
        SubmitStatusStyleExpr: Text;
        SubmitOnPostStyleExpr: Text;
}
