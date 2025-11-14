namespace MYeInvoiceCore.MYeInvoiceCore;

codeunit 7000001 "MY e-Invoice TIN Mgt."
{
    /// <summary>
    /// Validates TIN format for Malaysian e-Invoice (MyInvois)
    /// Based on LHDN/IRBM specifications
    /// </summary>
    procedure ValidateTINFormat(TINNo: Code[20]): Boolean
    var
        TINWithoutSpaces: Text;
        TINType: Text[3];
        TINDigits: Text;
    begin
        if TINNo = '' then
            exit(true); // Empty TIN is allowed for certain scenarios

        TINWithoutSpaces := DelChr(TINNo, '=', ' -');

        // Malaysian TIN formats for e-Invoice:
        // 1. Company/Business: C 2345678901 (C + 10 digits) - Income Tax Number
        // 2. Individual: IG 1234567890 (IG + 10 digits) - Income Tax Number
        // 3. Government: SG 1234567890 (SG + 10 digits) - Income Tax Number
        // 4. SST Registration: A01-2345-67891234 (SST format)
        // 5. MyKad/MyPR: 12 digits (for individuals without TIN)
        // 6. Passport: Variable length
        // 7. Army/Police: Variable length

        // Check minimum length
        if StrLen(TINWithoutSpaces) < 10 then
            Error('TIN must be at least 10 characters');

        // Identify TIN type
        TINType := UpperCase(CopyStr(TINWithoutSpaces, 1, 2));

        case TINType of
            'C ', 'C':
                exit(ValidateCompanyTIN(TINWithoutSpaces));
            'IG':
                exit(ValidateIndividualTIN(TINWithoutSpaces));
            'SG':
                exit(ValidateGovernmentTIN(TINWithoutSpaces));
            'A0', 'A1', 'A2':
                exit(ValidateSSTNumber(TINWithoutSpaces));
            else
                exit(ValidateOtherID(TINWithoutSpaces));
        end;
    end;

    local procedure ValidateCompanyTIN(TINNo: Text): Boolean
    var
        TINDigits: Text;
    begin
        // Format: C + 10 digits
        if StrLen(TINNo) < 11 then
            Error('Company TIN format: C + 10 digits (e.g., C2345678901)');

        if UpperCase(CopyStr(TINNo, 1, 1)) <> 'C' then
            Error('Company TIN must start with C');

        TINDigits := CopyStr(TINNo, 2);
        if not IsNumeric(TINDigits) or (StrLen(TINDigits) <> 10) then
            Error('Company TIN must have exactly 10 digits after C');

        exit(true);
    end;

    local procedure ValidateIndividualTIN(TINNo: Text): Boolean
    var
        TINDigits: Text;
    begin
        // Format: IG + 10 digits
        if StrLen(TINNo) < 12 then
            Error('Individual TIN format: IG + 10 digits (e.g., IG1234567890)');

        if UpperCase(CopyStr(TINNo, 1, 2)) <> 'IG' then
            Error('Individual TIN must start with IG');

        TINDigits := CopyStr(TINNo, 3);
        if not IsNumeric(TINDigits) or (StrLen(TINDigits) <> 10) then
            Error('Individual TIN must have exactly 10 digits after IG');

        exit(true);
    end;

    local procedure ValidateGovernmentTIN(TINNo: Text): Boolean
    var
        TINDigits: Text;
    begin
        // Format: SG + 10 digits
        if StrLen(TINNo) < 12 then
            Error('Government TIN format: SG + 10 digits (e.g., SG1234567890)');

        if UpperCase(CopyStr(TINNo, 1, 2)) <> 'SG' then
            Error('Government TIN must start with SG');

        TINDigits := CopyStr(TINNo, 3);
        if not IsNumeric(TINDigits) or (StrLen(TINDigits) <> 10) then
            Error('Government TIN must have exactly 10 digits after SG');

        exit(true);
    end;

    local procedure ValidateSSTNumber(TINNo: Text): Boolean
    var
        CleanSST: Text;
    begin
        // SST Format: A01-2345-67891234 (Group-Code-RegistrationNumber)
        CleanSST := DelChr(TINNo, '=', ' -');

        if not (StrLen(CleanSST) in [16 .. 18]) then
            Error('SST number format: A01-2345-67891234');

        if not (UpperCase(CopyStr(CleanSST, 1, 1)) = 'A') then
            Error('SST number must start with A');

        if not IsNumeric(CopyStr(CleanSST, 2)) then
            Error('SST number contains invalid characters');

        exit(true);
    end;

    local procedure ValidateOtherID(IDNo: Text): Boolean
    begin
        // MyKad/MyPR: 12 digits (YYMMDD-PB-###G)
        // Passport: Variable
        // Army/Police: Variable

        if IsNumeric(IDNo) and (StrLen(IDNo) = 12) then
            exit(true); // Valid MyKad/MyPR format

        // For passport, army, police - just check reasonable length
        if StrLen(IDNo) >= 6 then
            exit(true);

        Error('Invalid identification number format');
    end;

    local procedure IsNumeric(Value: Text): Boolean
    var
        i: Integer;
        Char: Char;
    begin
        if Value = '' then
            exit(false);

        for i := 1 to StrLen(Value) do begin
            Char := Value[i];
            if not (Char in ['0' .. '9']) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates TIN and returns result with message (for manual validation action)
    /// </summary>
    procedure ValidateTINWithMessage(TINNo: Code[20]; var IsValid: Boolean; var ValidationMessage: Text)
    begin
        IsValid := false;
        ValidationMessage := '';

        if TINNo = '' then begin
            ValidationMessage := 'TIN/ID is empty. This may be acceptable for certain transaction types.';
            exit;
        end;

        if not ValidateTINFormat(TINNo) then begin
            ValidationMessage := GetLastErrorText();
            ClearLastError();
            exit;
        end;

        // Format is valid
        IsValid := true;
        ValidationMessage := StrSubstNo('TIN/ID "%1" format is valid for e-Invoice submission.', TINNo);
    end;

    /// <summary>
    /// Formats TIN with proper spacing for display
    /// </summary>
    procedure FormatTIN(TINNo: Code[20]): Code[20]
    var
        CleanTIN: Text;
        FormattedTIN: Text;
        TINType: Text[2];
    begin
        if TINNo = '' then
            exit('');

        CleanTIN := DelChr(TINNo, '=', ' -');
        TINType := UpperCase(CopyStr(CleanTIN, 1, 2));

        case TINType of
            'IG', 'SG':
                // Format: IG 1234567890 or SG 1234567890
                FormattedTIN := CopyStr(CleanTIN, 1, 2) + ' ' + CopyStr(CleanTIN, 3);
            else begin
                if UpperCase(CopyStr(CleanTIN, 1, 1)) = 'C' then
                    // Format: C 2345678901
                    FormattedTIN := 'C ' + CopyStr(CleanTIN, 2)
                else if UpperCase(CopyStr(CleanTIN, 1, 1)) = 'A' then begin
                    // Format SST: A01-2345-67891234
                    if StrLen(CleanTIN) >= 16 then
                        FormattedTIN := CopyStr(CleanTIN, 1, 3) + '-' + CopyStr(CleanTIN, 4, 4) + '-' + CopyStr(CleanTIN, 8)
                    else
                        FormattedTIN := CleanTIN;
                end else
                    FormattedTIN := CleanTIN;
            end;
        end;

        exit(CopyStr(FormattedTIN, 1, 20));
    end;

    /// <summary>
    /// Determines TIN type for e-Invoice XML generation
    /// </summary>
    procedure GetTINType(TINNo: Code[20]): Text[10]
    var
        CleanTIN: Text;
    begin
        if TINNo = '' then
            exit('');

        CleanTIN := DelChr(TINNo, '=', ' -');

        case UpperCase(CopyStr(CleanTIN, 1, 2)) of
            'C ', 'C':
                exit('TIN'); // Tax Identification Number
            'IG':
                exit('TIN'); // Individual Income Tax Number
            'SG':
                exit('TIN'); // Government Tax Number
            'A0', 'A1', 'A2':
                exit('SST'); // SST Registration Number
            else begin
                if IsNumeric(CleanTIN) and (StrLen(CleanTIN) = 12) then
                    exit('NRIC') // MyKad/MyPR
                else
                    exit('PASSPORT'); // Passport or other
            end;
        end;
    end;
}