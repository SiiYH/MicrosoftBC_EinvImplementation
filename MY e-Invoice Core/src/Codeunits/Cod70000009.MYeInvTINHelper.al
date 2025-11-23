codeunit 70000009 "MY eInv TIN Helper"
{
    procedure ValidateTINStructure(TIN: Text): Boolean
    var
        TINCategory: Record "MY eInv TIN Category";
        Prefix: Code[10];
        InvalidTINErr: Label 'Invalid TIN structure. TIN must start with a valid category code:\• IG for Individuals\• C for Companies\• D for Partnerships\• F for Associations\Etc. See TIN Category list for all codes.';
    begin
        if TIN = '' then
            exit(false);

        // Extract prefix (first 1-2 characters)
        if StrLen(TIN) >= 2 then begin
            Prefix := CopyStr(TIN, 1, 2);
            if TINCategory.Get(Prefix) then
                exit(true);
        end;

        if StrLen(TIN) >= 1 then begin
            Prefix := CopyStr(TIN, 1, 1);
            if TINCategory.Get(Prefix) then
                exit(true);
        end;

        Error(InvalidTINErr);
    end;

    procedure GetTINCategoryDescription(TIN: Text): Text
    var
        TINCategory: Record "MY eInv TIN Category";
        Prefix: Code[10];
    begin
        if TIN = '' then
            exit('');

        // Try 2-character prefix first
        if StrLen(TIN) >= 2 then begin
            Prefix := CopyStr(TIN, 1, 2);
            if TINCategory.Get(Prefix) then
                exit(TINCategory.Category);
        end;

        // Try 1-character prefix
        if StrLen(TIN) >= 1 then begin
            Prefix := CopyStr(TIN, 1, 1);
            if TINCategory.Get(Prefix) then
                exit(TINCategory.Category);
        end;

        exit('Unknown Category');
    end;

    procedure IsGeneralTIN(TIN: Text): Boolean
    begin
        // Check if TIN is one of the 4 General TIN codes
        exit(TIN in ['EI00000000010', 'EI00000000020', 'EI00000000030', 'EI00000000040']);
    end;

    procedure GetGeneralTINDescription(GeneralTIN: Text): Text
    begin
        case GeneralTIN of
            'EI00000000010':
                exit('General Public (Local Individual with NRIC)');
            'EI00000000020':
                exit('Foreign Buyer/Shipping Recipient');
            'EI00000000030':
                exit('Foreign Supplier (Self-billed/Import)');
            'EI00000000040':
                exit('Government/Authorities');
            else
                exit('');
        end;
    end;

    procedure FormatTINForDisplay(TIN: Text): Text
    var
        Category: Text;
    begin
        if IsGeneralTIN(TIN) then
            exit(TIN + ' (' + GetGeneralTINDescription(TIN) + ')');

        Category := GetTINCategoryDescription(TIN);
        if Category <> 'Unknown Category' then
            exit(TIN + ' (' + Category + ')');

        exit(TIN);
    end;

    procedure ValidateTINFormat(Tin: Text[20])
    var
        InvalidTINErr: Label 'Invalid TIN format.\Expected format:\• Individuals: IG + 9-11 digits (e.g., IG115002000)\• Companies: C + 11 digits (e.g., C20880050010)\• See TIN Category reference for other entity types.';
    begin
        if Tin = '' then
            exit;

        // TIN format: 13 characters
        // New format (from Jan 2023): IG + 11 digits for individuals, C + 12 digits for companies
        if StrLen(Tin) < 10 then
            Error(InvalidTINErr);

        // TIN validation can be enhanced based on prefix
        // IG = Individual, C = Company, D = Partnership, etc.
    end;

    procedure ValidateBRNFormat("MY eInv BRN": Text[20])
    var
        InvalidBRNErr: Label 'Invalid BRN format. Expected 12-digit new SSM format (e.g., 202001012345) or old format with check digit.';
    begin
        if "MY eInv BRN" = '' then
            exit;

        // New SSM BRN: 12 digits (Effective since Jan 2023)
        // Old BRN: Variable length with check digit in brackets
        if StrLen("MY eInv BRN") < 10 then
            Error(InvalidBRNErr);
    end;

    procedure ValidateNRICFormat("MY eInv NRIC": Text[14])
    var
        InvalidNRICErr: Label 'Invalid NRIC format. Expected 12 digits (YYMMDD-PB-###G format without dashes).';
    begin
        if "MY eInv NRIC" = '' then
            exit;

        // NRIC format: 12 digits (YYMMDD-PB-###G)
        // Remove any dashes for storage
        if StrLen("MY eInv NRIC") <> 12 then
            Error(InvalidNRICErr);
    end;
}
