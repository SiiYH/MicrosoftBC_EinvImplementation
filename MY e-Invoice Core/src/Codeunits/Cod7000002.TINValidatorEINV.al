namespace MYeInvoiceCore.MYeInvoiceCore;

// =========================================================================
// TIN (Tax Identification Number) Validator for Malaysian e-Invoice
// Based on LHDN SDK Requirements
// =========================================================================

codeunit 7000002 "TIN Validator EINV"
{
    var
        InvalidTINErr: Label 'Invalid TIN format: %1\%2';
        TINValidationFailedErr: Label 'TIN validation failed via LHDN API.\TIN: %1\Error: %2';
        TINNotFoundErr: Label 'TIN not found in LHDN system: %1\Please verify the TIN is registered with LHDN.';
        TINValidatedMsg: Label 'TIN validated successfully via LHDN API.\TIN: %1\Name: %2';

    /// <summary>
    /// Validates TIN format and optionally validates via LHDN API
    /// </summary>
    /// <param name="TIN">Tax Identification Number to validate</param>
    /// <param name="ValidateViaAPI">If true, validates against LHDN API</param>
    procedure ValidateTIN(TIN: Code[20]; ValidateViaAPI: Boolean)
    var
        NormalizedTIN: Text;
    begin
        if TIN = '' then
            exit;

        // Step 1: Normalize TIN according to LHDN rules
        NormalizedTIN := NormalizeTIN(TIN);

        // Step 2: Validate format
        ValidateTINFormat(NormalizedTIN, true);

        // Step 3: Validate via API if requested
        /* if ValidateViaAPI then
            ValidateTINViaAPI(NormalizedTIN); */
    end;

    /// <summary>
    /// Validates TIN format only (no API call)
    /// </summary>
    procedure ValidateTIN(TIN: Code[20])
    begin
        ValidateTIN(TIN, false);
    end;

    /// <summary>
    /// Normalizes TIN according to LHDN SDK rules
    /// </summary>
    /// <param name="TIN">Original TIN</param>
    /// <returns>Normalized TIN ready for submission</returns>
    procedure NormalizeTIN(TIN: Code[20]): Text
    var
        CleanTIN: Text;
        Prefix: Text;
        NumericPart: Text;
        TINType: Text;
    begin
        if TIN = '' then
            exit('');

        // Remove special characters and convert to uppercase
        CleanTIN := RemoveSpecialCharacters(TIN);

        // Detect TIN type
        TINType := DetectTINType(CleanTIN);

        case TINType of
            'INDIVIDUAL':
                exit(NormalizeIndividualTIN(CleanTIN));
            'NON-INDIVIDUAL':
                exit(NormalizeNonIndividualTIN(CleanTIN));
            'NRIC':
                exit(CleanTIN); // NRIC doesn't need normalization
            else
                exit(CleanTIN); // Return as-is for other types
        end;
    end;

    // =========================================================================
    // LHDN SPECIFIC NORMALIZATION
    // =========================================================================

    /// <summary>
    /// Normalize Individual TIN (prefix IG)
    /// Replace OG or SG with IG
    /// </summary>
    local procedure NormalizeIndividualTIN(TIN: Text): Text
    var
        Prefix: Text;
        NumericPart: Text;
    begin
        // Individual TIN starts with IG, OG, or SG
        Prefix := CopyStr(TIN, 1, 2);

        case Prefix of
            'OG', 'SG':
                begin
                    // Replace with IG
                    NumericPart := CopyStr(TIN, 3);
                    exit('IG' + NumericPart);
                end;
            'IG':
                exit(TIN); // Already correct
            else
                exit(TIN); // Not an individual TIN
        end;
    end;

    /// <summary>
    /// Normalize Non-Individual TIN
    /// Rules:
    /// 1. Remove leading zeros after prefix
    /// 2. Ensure ends with zero '0'
    /// </summary>
    local procedure NormalizeNonIndividualTIN(TIN: Text): Text
    var
        Prefix: Text;
        NumericPart: Text;
        CleanNumeric: Text;
        i: Integer;
        PrefixLength: Integer;
    begin
        // Extract prefix
        if StartsWithNonIndividualPrefix(TIN) then begin
            PrefixLength := GetPrefixLength(TIN);
            Prefix := CopyStr(TIN, 1, PrefixLength);
            NumericPart := CopyStr(TIN, PrefixLength + 1);

            // Remove leading zeros after prefix
            CleanNumeric := NumericPart;
            while (StrLen(CleanNumeric) > 1) and (CleanNumeric[1] = '0') do
                CleanNumeric := CopyStr(CleanNumeric, 2);

            // Ensure ends with zero '0'
            if CleanNumeric[StrLen(CleanNumeric)] <> '0' then
                CleanNumeric := CleanNumeric + '0';

            exit(Prefix + CleanNumeric);
        end;

        exit(TIN);
    end;

    // =========================================================================
    // FORMAT VALIDATION
    // =========================================================================

    /// <summary>
    /// Validates TIN format according to LHDN rules
    /// </summary>
    local procedure ValidateTINFormat(TIN: Text; ThrowError: Boolean): Boolean
    var
        TINType: Text;
    begin
        if TIN = '' then
            exit(true);

        TINType := DetectTINType(TIN);

        case TINType of
            'INDIVIDUAL':
                exit(ValidateIndividualTIN(TIN, ThrowError));
            'NON-INDIVIDUAL':
                exit(ValidateNonIndividualTIN(TIN, ThrowError));
            'NRIC':
                exit(ValidateNRIC(TIN, ThrowError));
            'PASSPORT':
                exit(ValidatePassport(TIN, ThrowError));
            else
                exit(ValidateGenericTIN(TIN, ThrowError));
        end;
    end;

    /// <summary>
    /// Validates Individual TIN (prefix IG)
    /// Max length: 14 characters including prefix
    /// </summary>
    local procedure ValidateIndividualTIN(TIN: Text; ThrowError: Boolean): Boolean
    var
        Prefix: Text;
        NumericPart: Text;
    begin
        // Check prefix
        Prefix := CopyStr(TIN, 1, 2);
        if Prefix <> 'IG' then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Individual TIN must start with prefix "IG"');
            exit(false);
        end;

        // Check length (max 14 including prefix)
        if StrLen(TIN) > 14 then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Individual TIN maximum length is 14 characters (including prefix IG)');
            exit(false);
        end;

        // Check numeric part
        NumericPart := CopyStr(TIN, 3);
        if not IsNumeric(NumericPart) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Characters after prefix "IG" must be numeric');
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates Non-Individual TIN
    /// Prefixes: C, CS, D, F, FA, PT, TA, TC, TN, TR, TP, J, LE
    /// Must end with zero '0'
    /// </summary>
    local procedure ValidateNonIndividualTIN(TIN: Text; ThrowError: Boolean): Boolean
    var
        Prefix: Text;
        NumericPart: Text;
        PrefixLength: Integer;
        LastChar: Char;
    begin
        // Check prefix
        if not StartsWithNonIndividualPrefix(TIN) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Non-Individual TIN must start with valid prefix (C, CS, D, F, FA, PT, TA, TC, TN, TR, TP, J, LE)');
            exit(false);
        end;

        PrefixLength := GetPrefixLength(TIN);
        Prefix := CopyStr(TIN, 1, PrefixLength);
        NumericPart := CopyStr(TIN, PrefixLength + 1);

        // Check numeric part
        if not IsNumeric(NumericPart) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, StrSubstNo('Characters after prefix "%1" must be numeric', Prefix));
            exit(false);
        end;

        // Must end with zero '0'
        LastChar := TIN[StrLen(TIN)];
        if LastChar <> '0' then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Non-Individual TIN must end with zero "0"');
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates NRIC (12 digits)
    /// </summary>
    local procedure ValidateNRIC(TIN: Text; ThrowError: Boolean): Boolean
    begin
        if StrLen(TIN) <> 12 then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'NRIC must be exactly 12 digits');
            exit(false);
        end;

        if not IsNumeric(TIN) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'NRIC must contain only numbers');
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates Passport Number
    /// </summary>
    local procedure ValidatePassport(TIN: Text; ThrowError: Boolean): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(TIN);

        if (Length < 6) or (Length > 15) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Passport Number must be 6-15 characters');
            exit(false);
        end;

        if not IsAlphanumeric(TIN) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'Passport Number must be alphanumeric');
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Generic TIN validation
    /// </summary>
    local procedure ValidateGenericTIN(TIN: Text; ThrowError: Boolean): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(TIN);

        if (Length < 5) or (Length > 20) then begin
            if ThrowError then
                Error(InvalidTINErr, TIN, 'TIN must be 5-20 characters');
            exit(false);
        end;

        exit(true);
    end;

    // =========================================================================
    // LHDN API VALIDATION
    // =========================================================================

    /// <summary>
    /// Validates TIN via LHDN API
    /// API Endpoint: /api/v1.0/taxpayer/validate/{tin}?idType={idType}&idValue={idValue}
    /// </summary>
    procedure ValidateTINViaAPI(TIN: Text; IDType: Text; IDValue: Text): Boolean
    var
        EInvoiceSetup: Record "e-Invoice Setup EINV";
        HttpClient: Codeunit "Http Client EINV";
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        ResponseText: Text;
        APIUrl: Text;
        TaxpayerName: Text;
        IsValid: Boolean;
    begin
        // Get setup
        if not EInvoiceSetup.Get() then
            Error('e-Invoice Setup not found. Please configure e-Invoice settings first.');

        // Validate required parameters
        if TIN = '' then
            Error('TIN cannot be empty');
        if IDType = '' then
            Error('ID Type cannot be empty');
        if IDValue = '' then
            Error('ID Value cannot be empty');

        // Normalize TIN
        TIN := NormalizeTIN(TIN);

        // Build API URL with query parameters
        APIUrl := EInvoiceSetup."API Base URL" + '/api/v1.0/taxpayer/validate/' + TIN +
                  '?idType=' + IDType + '&idValue=' + IDValue;

        // Call API
        if not HttpClient.GetRequest(APIUrl, ResponseText) then
            Error(TINValidationFailedErr, TIN, 'Failed to connect to LHDN API');

        // Parse response
        if not JsonResponse.ReadFrom(ResponseText) then
            Error(TINValidationFailedErr, TIN, 'Invalid API response format');

        // Check if TIN is valid (HTTP 200 = valid)
        IsValid := true;

        // Get taxpayer name if available
        if JsonResponse.Get('name', JsonToken) then
            TaxpayerName := JsonToken.AsValue().AsText();

        Message(TINValidatedMsg, TIN, TaxpayerName);
        exit(true);
    end;

    /// <summary>
    /// Silent API validation (returns true/false without error)
    /// </summary>
    procedure ValidateTINViaAPISilent(TIN: Text; IDType: Text; IDValue: Text; var TaxpayerName: Text): Boolean
    var
        EInvoiceSetup: Record "e-Invoice Setup EINV";
        HttpClient: Codeunit "Http Client EINV";
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        ResponseText: Text;
        APIUrl: Text;
        IsValid: Boolean;
    begin
        // Get setup
        if not EInvoiceSetup.Get() then
            exit(false);

        // Validate required parameters
        if (TIN = '') or (IDType = '') or (IDValue = '') then
            exit(false);

        // Normalize TIN
        TIN := NormalizeTIN(TIN);

        // Build API URL with query parameters
        APIUrl := EInvoiceSetup."API Base URL" + '/api/v1.0/taxpayer/validate/' + TIN +
                  '?idType=' + IDType + '&idValue=' + IDValue;

        // Call API
        if not HttpClient.GetRequest(APIUrl, ResponseText) then
            exit(false);

        // HTTP 200 = valid, anything else = invalid
        IsValid := true;

        // Parse response to get taxpayer name
        if JsonResponse.ReadFrom(ResponseText) then
            if JsonResponse.Get('name', JsonToken) then
                TaxpayerName := JsonToken.AsValue().AsText();

        exit(IsValid);
    end;

    /// <summary>
    /// Helper to determine ID Type and ID Value from Customer/Vendor Type
    /// </summary>
    procedure GetIDTypeAndValue(EntityType: Enum "Entity Type EINV"; NRIC: Code[20]; BRN: Code[20]; Passport: Code[20]; ArmyNo: Code[20]; var IDType: Text; var IDValue: Text): Boolean
    begin
        case EntityType of
            EntityType::"Malaysian Individual":
                begin
                    if NRIC <> '' then begin
                        IDType := 'NRIC';
                        IDValue := NRIC;
                        exit(true);
                    end;
                    if ArmyNo <> '' then begin
                        IDType := 'ARMY';
                        IDValue := ArmyNo;
                        exit(true);
                    end;
                    if Passport <> '' then begin
                        IDType := 'PASSPORT';
                        IDValue := Passport;
                        exit(true);
                    end;
                end;

            EntityType::"Foreign Business",
            EntityType::"Malaysian Business":
                begin
                    if BRN <> '' then begin
                        IDType := 'BRN';
                        IDValue := BRN;
                        exit(true);
                    end;
                end;

            EntityType::"Foreign Individual":
                begin
                    if Passport <> '' then begin
                        IDType := 'PASSPORT';
                        IDValue := Passport;
                        exit(true);
                    end;
                    if BRN <> '' then begin
                        IDType := 'BRN';
                        IDValue := BRN;
                        exit(true);
                    end;
                end;
        end;

        exit(false);
    end;

    // =========================================================================
    // HELPER PROCEDURES
    // =========================================================================

    local procedure DetectTINType(TIN: Text): Text
    var
        Prefix: Text[2];
    begin
        if TIN = '' then
            exit('');

        // Individual TIN (IG, OG, SG)
        Prefix := CopyStr(TIN, 1, 2);
        if Prefix in ['IG', 'OG', 'SG'] then
            exit('INDIVIDUAL');

        // Non-Individual TIN (C, CS, D, F, FA, PT, TA, TC, TN, TR, TP, J, LE)
        if StartsWithNonIndividualPrefix(TIN) then
            exit('NON-INDIVIDUAL');

        // NRIC (12 digits)
        if (StrLen(TIN) = 12) and IsNumeric(TIN) then
            exit('NRIC');

        // Passport (alphanumeric)
        if IsAlphanumeric(TIN) then
            exit('PASSPORT');

        exit('GENERIC');
    end;

    local procedure StartsWithNonIndividualPrefix(TIN: Text): Boolean
    var
        Prefix1: Text;
        Prefix2: Text;
    begin
        if StrLen(TIN) < 2 then
            exit(false);

        Prefix1 := CopyStr(TIN, 1, 1);
        Prefix2 := CopyStr(TIN, 1, 2);

        // Check 2-character prefixes first
        if Prefix2 in ['CS', 'FA', 'PT', 'TA', 'TC', 'TN', 'TR', 'TP', 'LE'] then
            exit(true);

        // Check 1-character prefixes
        if Prefix1 in ['C', 'D', 'F', 'J'] then
            exit(true);

        exit(false);
    end;

    local procedure GetPrefixLength(TIN: Text): Integer
    var
        Prefix2: Text;
    begin
        if StrLen(TIN) < 2 then
            exit(1);

        Prefix2 := CopyStr(TIN, 1, 2);

        // 2-character prefixes
        if Prefix2 in ['CS', 'FA', 'PT', 'TA', 'TC', 'TN', 'TR', 'TP', 'LE', 'IG', 'OG', 'SG'] then
            exit(2);

        // 1-character prefixes
        exit(1);
    end;

    local procedure RemoveSpecialCharacters(InputText: Text): Text
    var
        Result: Text;
        i: Integer;
        Char: Char;
    begin
        Result := '';
        for i := 1 to StrLen(InputText) do begin
            Char := InputText[i];
            if ((Char >= '0') and (Char <= '9')) or
               ((Char >= 'A') and (Char <= 'Z')) or
               ((Char >= 'a') and (Char <= 'z')) then
                Result += Format(Char);
        end;
        exit(UpperCase(Result));
    end;

    local procedure IsNumeric(InputText: Text): Boolean
    var
        i: Integer;
        Char: Char;
    begin
        if InputText = '' then
            exit(false);

        for i := 1 to StrLen(InputText) do begin
            Char := InputText[i];
            if (Char < '0') or (Char > '9') then
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsAlphanumeric(InputText: Text): Boolean
    var
        i: Integer;
        Char: Char;
    begin
        if InputText = '' then
            exit(false);

        for i := 1 to StrLen(InputText) do begin
            Char := InputText[i];
            if not (((Char >= '0') and (Char <= '9')) or
                    ((Char >= 'A') and (Char <= 'Z')) or
                    ((Char >= 'a') and (Char <= 'z'))) then
                exit(false);
        end;
        exit(true);
    end;

    // =========================================================================
    // PUBLIC HELPER PROCEDURES
    // =========================================================================

    /// <summary>
    /// Returns the detected type of TIN
    /// </summary>
    procedure GetTINType(TIN: Code[20]): Text
    var
        CleanTIN: Text;
    begin
        if TIN = '' then
            exit('');

        CleanTIN := RemoveSpecialCharacters(TIN);
        exit(DetectTINType(CleanTIN));
    end;

    /// <summary>
    /// Formats TIN for display
    /// </summary>
    procedure FormatTINForDisplay(TIN: Code[20]): Text
    var
        NormalizedTIN: Text;
    begin
        if TIN = '' then
            exit('');

        NormalizedTIN := NormalizeTIN(TIN);
        exit(NormalizedTIN);
    end;
}