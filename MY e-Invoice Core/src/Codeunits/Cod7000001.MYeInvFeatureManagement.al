codeunit 70000001 "MY eInv Feature Management"
{
    procedure IsEInvoiceEnabled(): Boolean
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Enable E-Invoice");
        exit(false);
    end;

    procedure CheckEInvoiceEnabled()
    var
        NotEnabledErr: Label 'E-Invoice is not enabled. Please enable it in Company Information.';
    begin
        if not IsEInvoiceEnabled() then
            Error(NotEnabledErr);
    end;

    procedure GetCompanyTIN(): Text[20]
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."LHDN TIN");
        exit('');
    end;

    procedure ValidateSetup()
    var
        MYeInvSetup: Record "MY eInv Setup";
        CompanyTIN: Text[20];
        SetupErrors: Text;
    begin
        // Check if enabled
        CheckEInvoiceEnabled();

        // Check Company TIN
        CompanyTIN := GetCompanyTIN();
        if CompanyTIN = '' then
            SetupErrors += '- Company TIN is not configured.\';

        // Check Setup
        if not MYeInvSetup.Get() then
            Error('MY eInv Setup record does not exist.');

        if MYeInvSetup.GetClientID() = '' then
            SetupErrors += '- Client ID is not configured.\';

        if MYeInvSetup.GetClientSecret() = '' then
            SetupErrors += '- Client Secret is not configured.\';

        if not MYeInvSetup."TIN Verified" then
            SetupErrors += '- TIN has not been verified. Please test connection.\';

        if MYeInvSetup."Authenticated TIN" <> CompanyTIN then
            SetupErrors += StrSubstNo('- TIN mismatch: Company TIN (%1) does not match Authenticated TIN (%2).\',
                CompanyTIN, MYeInvSetup."Authenticated TIN");

        if SetupErrors <> '' then
            Error('MY eInv Setup is incomplete:\%1\Please complete the setup in MY eInv Setup Card.', SetupErrors);
    end;
}
