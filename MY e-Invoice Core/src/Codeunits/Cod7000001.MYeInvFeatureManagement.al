codeunit 70000001 "MY eInv Feature Management"
{
    // Check if E-Invoice is enabled for current company
    procedure IsEInvoiceEnabled(): Boolean
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Enable E-Invoice");
        exit(false);
    end;

    // Validate that E-Invoice is enabled before allowing operations
    procedure CheckEInvoiceEnabled()
    var
        NotEnabledErr: Label 'E-Invoice is not enabled for this company. Please enable it in Company Information.';
    begin
        if not IsEInvoiceEnabled() then
            Error(NotEnabledErr);
    end;

    // Get company TIN
    procedure GetCompanyTIN(): Text[20]
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."LHDN TIN");
        exit('');
    end;

    // Validate TIN format (basic check - 12 digits)
    procedure ValidateTIN(TIN: Text[20]): Boolean
    var
        i: Integer;
    begin
        if StrLen(TIN) <> 12 then
            exit(false);

        // Check if all characters are digits
        for i := 1 to 12 do
            if not (TIN[i] in ['0' .. '9']) then
                exit(false);

        exit(true);
    end;
}
