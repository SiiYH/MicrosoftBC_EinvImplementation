page 70000051 "MY eInv Certificate Card"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "MY eInv Setup";
    Caption = 'MY eInvoice Digital Certificate';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Version)
            {
                Caption = 'Document Version';

                field("Document Version"; Rec."Document Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select document version. Version 1.1 requires digital signature.';
                    ShowMandatory = true;
                    Style = StrongAccent;
                    StyleExpr = VersionStyle;

                    trigger OnValidate()
                    begin
                        UpdateDisplayFields();
                        CurrPage.Update(false);
                    end;
                }

                field(VersionInfo; VersionInfoText)
                {
                    ApplicationArea = All;
                    Caption = 'Version Info';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Information about the selected document version.';
                }
            }

            group(Certificate)
            {
                Caption = 'Certificate Information';
                Visible = Rec."Document Version" = Rec."Document Version"::"1.1";

                field(CertificateStatus; CertificateStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Certificate Status';
                    Editable = false;
                    Style = StrongAccent;
                    StyleExpr = CertificateStatusStyle;
                    ToolTip = 'Current status of digital certificate configuration.';
                }
                field("Certificate ID"; Rec."Certificate ID")
                {
                    ApplicationArea = All;
                    Caption = 'Certificate ID';
                    Editable = false;
                    Style = StrongAccent;
                    StyleExpr = CertificateStatusStyle;
                    ToolTip = 'Specifies the value of the Certificate Name.', Comment = '%';
                }

                field("Certificate File Name"; Rec."Certificate File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Name of the uploaded certificate file.';
                    Editable = false;
                }

                field("Certificate Subject"; Rec."Certificate Subject")
                {
                    ApplicationArea = All;
                    ToolTip = 'Certificate subject (organization details).';
                    Editable = false;
                }

                field("Certificate Issuer"; Rec."Certificate Issuer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Certificate authority that issued this certificate.';
                    Editable = false;
                }

                field("Certificate Serial Number"; Rec."Certificate Serial Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique serial number of the certificate.';
                    Editable = false;
                }
            }

            group(Validity)
            {
                Caption = 'Certificate Validity';
                Visible = Rec."Certificate Configured";

                field("Certificate Valid From"; Rec."Certificate Valid From")
                {
                    ApplicationArea = All;
                    Caption = 'Valid From';
                    ToolTip = 'Certificate validity start date.';
                    Editable = false;
                }

                field("Certificate Valid To"; Rec."Certificate Valid To")
                {
                    ApplicationArea = All;
                    Caption = 'Valid Until';
                    ToolTip = 'Certificate expiry date.';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ExpiryStyle;
                }

                field(DaysUntilExpiry; DaysUntilExpiryText)
                {
                    ApplicationArea = All;
                    Caption = 'Days Until Expiry';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ExpiryStyle;
                    ToolTip = 'Number of days until certificate expires.';
                }
            }

            group(Requirements)
            {
                Caption = 'Certificate Requirements';
                Visible = (Rec."Document Version" = Rec."Document Version"::"1.1") and (not Rec."Certificate Configured");

                field(Requirement1; Requirement1Txt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadCertificate)
            {
                ApplicationArea = All;
                Caption = 'Upload Certificate';
                Image = Certificate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec."Document Version" = Rec."Document Version"::"1.1";
                ToolTip = 'Upload digital certificate file (.pfx or .p12).';

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Certificate Mgmt";
                begin
                    CertMgmt.UploadCertificate(Rec);
                    UpdateDisplayFields();
                    CurrPage.Update(true);
                end;
            }

            /* action(TestCertificate)
            {
                ApplicationArea = All;
                Caption = 'Test Certificate';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec."Certificate Configured";
                ToolTip = 'Test the digital certificate by signing a sample document.';

                trigger OnAction()
                var
                    DigitalSignature: Codeunit "MY eInv Digital Signature";
                    TestXML: Text;
                    SignedXML: Text;
                begin
                    if not Confirm('This will test the certificate by signing a sample document. Continue?', true) then
                        exit;

                    // Create a simple test XML
                    TestXML := '<?xml version="1.0" encoding="UTF-8"?>';
                    TestXML += '<TestDocument><Content>Test</Content></TestDocument>';

                    if DigitalSignature.TestCertificate(Rec, TestXML) then
                        Message('Certificate test successful! The certificate is valid and can be used for signing.')
                    else
                        Error('Certificate test failed. Please check the certificate and try again.');
                end;
            } */

            action(RemoveCertificate_)
            {
                ApplicationArea = All;
                Caption = 'Remove Certificate';
                Image = Delete;
                Enabled = Rec."Certificate Configured";
                ToolTip = 'Remove the uploaded certificate.';

                trigger OnAction()
                begin
                    if not Confirm('Are you sure you want to remove the certificate?', false) then
                        exit;

                    RemoveCertificate();
                    Message('Certificate removed successfully.');
                    UpdateDisplayFields();
                    CurrPage.Update(true);
                end;
            }

            action(ViewCAList)
            {
                ApplicationArea = All;
                Caption = 'View Approved CAs';
                Image = Info;
                ToolTip = 'View list of approved Certificate Authorities in Malaysia.';

                trigger OnAction()
                begin
                    ShowApprovedCAs();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayFields();
    end;

    local procedure UpdateDisplayFields()
    var
        DaysRemaining: Integer;
    begin
        // Update version info
        case Rec."Document Version" of
            Rec."Document Version"::"1.0":
                begin
                    VersionInfoText := 'Version 1.0: No digital signature required.' +
                                      '\Note: This version will be deprecated. ' +
                                      'Version 1.1 is recommended.';
                    VersionStyle := 'Attention';
                end;
            Rec."Document Version"::"1.1":
                begin
                    VersionInfoText := 'Version 1.1: Digital signature required.' +
                                      '\This is the current recommended version.';
                    VersionStyle := 'Favorable';
                end;
        end;

        // Update certificate status
        if Rec."Document Version" = Rec."Document Version"::"1.0" then begin
            CertificateStatusText := 'Not Required';
            CertificateStatusStyle := 'Subordinate';
        end else if not Rec."Certificate Configured" then begin
            CertificateStatusText := '✗ Not Configured - Upload Required';
            CertificateStatusStyle := 'Unfavorable';
        end else begin
            // Check expiry
            DaysRemaining := CalculateDaysUntilExpiry();

            if DaysRemaining <= 0 then begin
                CertificateStatusText := '✗ Expired - Upload New Certificate';
                CertificateStatusStyle := 'Unfavorable';
            end else if DaysRemaining <= 30 then begin
                CertificateStatusText := '⚠ Expiring Soon - Renew Certificate';
                CertificateStatusStyle := 'Attention';
            end else begin
                CertificateStatusText := '✓ Valid & Ready';
                CertificateStatusStyle := 'Favorable';
            end;
        end;

        // Update expiry info
        if Rec."Certificate Configured" then begin
            DaysRemaining := CalculateDaysUntilExpiry();
            DaysUntilExpiryText := Format(DaysRemaining) + ' days';

            if DaysRemaining <= 0 then
                ExpiryStyle := 'Unfavorable'
            else if DaysRemaining <= 30 then
                ExpiryStyle := 'Attention'
            else
                ExpiryStyle := 'Favorable';
        end else begin
            DaysUntilExpiryText := 'N/A';
            ExpiryStyle := 'Subordinate';
        end;
    end;

    local procedure CalculateDaysUntilExpiry(): Integer
    begin
        if not Rec."Certificate Configured" then
            exit(0);

        exit(Round((Rec."Certificate Valid To" - CurrentDateTime) / (24 * 60 * 60 * 1000), 1, '<'));
    end;

    /* [Scope('OnPrem')]
        local procedure RemoveCertificate()
        var
            IsolatedStorageMgt: Codeunit "Isolated Storage Management";
        begin
            Clear(Rec."Certificate Content");
            Clear(Rec."Certificate File Name");

            if not IsNullGuid(Rec."Certificate Password Key") then
                IsolatedStorageMgt.Delete(Rec."Certificate Password Key", DataScope::Company);

            Clear(Rec."Certificate Password Key");
            Clear(Rec."Certificate Issuer");
            Clear(Rec."Certificate Serial Number");
            Clear(Rec."Certificate Valid From");
            Clear(Rec."Certificate Valid To");
            Clear(Rec."Certificate Subject");
            Rec."Certificate Configured" := false;

            Rec.Modify(true);
        end; */

    local procedure RemoveCertificate()
    begin
        Clear(Rec."Certificate Content");
        Clear(Rec."Certificate File Name");

        if not IsNullGuid(Rec."Certificate Password Key") then
            IsolatedStorage.Delete(Rec."Certificate Password Key", DataScope::Company);

        Clear(Rec."Certificate Password Key");
        Clear(Rec."Certificate Issuer");
        Clear(Rec."Certificate Serial Number");
        Clear(Rec."Certificate Valid From");
        Clear(Rec."Certificate Valid To");
        Clear(Rec."Certificate Subject");
        Rec."Certificate Configured" := false;

        Rec.Modify(true);
    end;

    local procedure ShowApprovedCAs()
    var
        CAListText: Text;
    begin
        CAListText := 'Approved Certificate Authorities in Malaysia:\' +
                     '=========================================\\' +
                     '1. Pos Digicert Sdn Bhd (Recommended for MyInvois)\' +
                     '   Website: www.posdigicert.com.my\\' +
                     '2. MSC Trustgate.com Sdn Bhd\' +
                     '   Website: www.trustgate.com\\' +
                     '3. DigiCert Malaysia\' +
                     '   Website: www.digicert.com\\' +
                     '4. GlobalSign\' +
                     '   Website: www.globalsign.com\\' +
                     'Certificate Requirements:\' +
                     '- Valid X.509 certificate\' +
                     '- Key Usage: Non-Repudiation (40)\' +
                     '- Enhanced Key Usage: Document Signing (1.3.6.1.4.1.311.10.3.12)\' +
                     '- RSA key pair\' +
                     '- SHA-256 hashing\\' +
                     'For more information, visit:\' +
                     'https://sdk.myinvois.hasil.gov.my/signature/';

        Message(CAListText);
    end;

    var
        VersionInfoText: Text;
        VersionStyle: Text;
        CertificateStatusText: Text;
        CertificateStatusStyle: Text;
        DaysUntilExpiryText: Text;
        ExpiryStyle: Text;
        Requirement1Txt: Label '✓ Certificate must be in .pfx or .p12 format\✓ Issued by approved Malaysian CA\✓ Contains private key for signing\✓ Key Usage: Non-Repudiation\✓ Enhanced Key Usage: Document Signing';
}
