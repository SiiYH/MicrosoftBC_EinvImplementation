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
}
