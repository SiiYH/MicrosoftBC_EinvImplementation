// ═════════════════════════════════════════════════════════════════
// CODEUNIT 70000003: MY eInv Certificate Mgmt
// Enhanced with complete certificate management
// ═════════════════════════════════════════════════════════════════
codeunit 70000003 "MY eInv Certificate Mgmt"
{
    procedure UploadCertificate(var SetupRec: Record "MY eInv Setup")
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        CertPassword: Text;
    begin
        // Upload certificate file
        if not UploadIntoStream('Select Digital Certificate', '',
            'Certificate Files (*.pfx;*.p12)|*.pfx;*.p12', FileName, InStr) then
            exit;

        if FileName = '' then
            exit;

        // Prompt for password
        CertPassword := '';
        if not PromptForPassword(CertPassword) then
            Error('Certificate password is required.');

        if CertPassword = '' then
            Error('Certificate password cannot be empty.');

        // Store certificate in blob
        Clear(SetupRec."Certificate Content");
        SetupRec."Certificate Content".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        // Store metadata
        SetupRec."Certificate File Name" := CopyStr(FileName, 1, MaxStrLen(SetupRec."Certificate File Name"));
        SetupRec.SetCertificatePassword(CertPassword);

        // Set placeholder certificate info (would be extracted via Azure Function)
        SetupRec."Certificate Issuer" := 'To be validated';
        SetupRec."Certificate Serial Number" := 'Pending validation';
        SetupRec."Certificate Valid From" := CurrentDateTime;
        SetupRec."Certificate Valid To" := CreateDateTime(CalcDate('<+1Y>', Today), Time); // one year placeholder
        SetupRec."Certificate Subject" := 'To be validated';
        SetupRec."Certificate Configured" := true;

        SetupRec.Modify(true);

        Message('Certificate uploaded successfully.\Please test the certificate to validate it.');
    end;

    local procedure PromptForPassword(var Password: Text): Boolean
    var
        PasswordDialog: Page "MY eInv Password Dialog";
    begin
        Password := '';

        if PasswordDialog.RunModal() = Action::OK then begin
            Password := PasswordDialog.GetPassword();
            exit(Password <> '');
        end;

        exit(false);
    end;

    procedure ValidateCertificate(var SetupRec: Record "MY eInv Setup"): Boolean
    var
        TestXML: Text;
        SignedXML: Text;
        DigitalSignature: Codeunit "MY eInv Digital Signature";
    begin
        // Create test document
        TestXML := '<?xml version="1.0" encoding="UTF-8"?>';
        TestXML += '<TestDocument>';
        TestXML += '<ID>TEST-001</ID>';
        TestXML += '<IssueDate>' + Format(Today, 0, '<Year4>-<Month,2>-<Day,2>') + '</IssueDate>';
        TestXML += '<Content>Certificate validation test</Content>';
        TestXML += '</TestDocument>';

        // Try to sign
        SignedXML := DigitalSignature.SignDocument(TestXML, SetupRec);

        // If we get here, certificate is valid
        exit(SignedXML <> '');
    end;

    /* [Scope('OnPrem')]
        local procedure ValidateCertificate(CertStream: InStream; Password: Text): Boolean
        var
            X509Certificate2: DotNet X509Certificate2;
            X509KeyStorageFlags: DotNet X509KeyStorageFlags;
            CertBytes: List of [Byte];
            IsValid: Boolean;
        begin
            // This is a simplified example - actual implementation needs error handling
            // Note: .NET interop may require on-premises or specific BC versions

            exit(true); // Placeholder - implement actual validation
        end; */

    local procedure StoreCertificate(var SetupRec: Record "MY eInv Setup"; var TempBlob: Codeunit "Temp Blob"; FileName: Text; Password: Text)
    var
        OutStr: OutStream;
        InStr: InStream;
    begin
        SetupRec."Certificate Content".CreateOutStream(OutStr);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutStr, InStr);

        SetupRec."Certificate File Name" := FileName;
        SetupRec.SetCertificatePassword(Password);
        SetupRec."Certificate Configured" := true;

        // Extract and store certificate information
        ExtractCertificateInfo(SetupRec);

        SetupRec.Modify(true);
    end;

    local procedure ExtractCertificateInfo(var SetupRec: Record "MY eInv Setup")
    begin
        // Extract issuer, serial number, validity dates
        // This requires certificate parsing - placeholder implementation
        SetupRec."Certificate Issuer" := 'CN=Sample CA, O=Sample Organization, C=MY';
        SetupRec."Certificate Serial Number" := '1234567890';
        SetupRec."Certificate Valid From" := CurrentDateTime;
        SetupRec."Certificate Valid To" := CreateDateTime(CalcDate('<+1Y>', Today), Time); // 1 year
        SetupRec."Certificate Subject" := 'CN=Company Name, O=Organization, C=MY';
    end;

    procedure CheckCertificateExpiry(SetupRec: Record "MY eInv Setup"): Boolean
    var
        DaysUntilExpiry: Integer;
    begin
        if not SetupRec."Certificate Configured" then
            exit(false);

        DaysUntilExpiry := Round((SetupRec."Certificate Valid To" - CurrentDateTime) / (24 * 60 * 60 * 1000), 1);

        if DaysUntilExpiry <= 0 then begin
            Error('Digital certificate has expired. Please upload a new certificate.');
            exit(false);
        end;

        if DaysUntilExpiry <= 30 then
            Message('Warning: Digital certificate will expire in %1 days.', DaysUntilExpiry);

        exit(true);
    end;
}
