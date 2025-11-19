codeunit 70000004 "MY eInv Digital Signature"
{
    // Main signing function - validates and routes to appropriate signing method
    procedure SignDocument(DocumentXML: Text; var Setup: Record "MY eInv Setup"): Text
    var
        SignedXML: Text;
        AzureSigner: Codeunit "MY eInv Azure Signer";
    begin
        // Validate setup
        ValidateSetup(Setup);

        // Check certificate expiry
        CheckCertificateExpiry(Setup);

        // Route to Azure Function for signing
        SignedXML := AzureSigner.SignViaAzureFunction(DocumentXML, Setup);

        exit(SignedXML);
    end;

    local procedure ValidateSetup(Setup: Record "MY eInv Setup")
    begin
        if Setup."Document Version" <> Setup."Document Version"::"1.1" then
            Error('Digital signature is only required for version 1.1 documents.');

        if not Setup.HasCertificate() then
            Error('Digital certificate is not configured. Please upload a certificate first.');

        if Setup."Azure Function URL" = '' then
            Error('Azure Function URL is not configured. Please configure the signing service.');
    end;

    local procedure CheckCertificateExpiry(Setup: Record "MY eInv Setup")
    var
        CertMgmt: Codeunit "MY eInv Certificate Mgmt";
    begin
        CertMgmt.CheckCertificateExpiry(Setup);
    end;

    // Test certificate functionality
    procedure TestCertificate(Setup: Record "MY eInv Setup"; TestXML: Text): Boolean
    var
        SignedXML: Text;
    begin
        SignedXML := SignDocument(TestXML, Setup);
        exit(SignedXML <> '');
    end;
}
