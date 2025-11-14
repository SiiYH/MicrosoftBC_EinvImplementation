/// <summary>
/// Main setup table - one record per company
/// </summary>
/// 
table 7000000 "e-Invoice Setup EINV"
{
    Caption = 'e-Invoice Setup';
    DataClassification = CustomerContent;


    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        // === Environment Settings ===
        field(10; "Environment"; Enum "LHDN Environment EINV")
        {
            Caption = 'Environment';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateAPIEndpoints();
            end;
        }

        field(11; "API Base URL"; Text[250])
        {
            Caption = 'API Base URL';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "API Base URL" <> '' then
                    if not ("API Base URL".StartsWith('https://')) then
                        Error('API URL must start with https://');
            end;
        }

        // === Authentication Settings ===
        field(20; "Client ID"; Text[100])
        {
            Caption = 'Client ID';
            DataClassification = CustomerContent;
        }

        field(21; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            DataClassification = SystemMetadata;
            // Actual secret stored in Isolated Storage
        }

        field(22; "Token Expires At"; DateTime)
        {
            Caption = 'Token Expires At';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(23; "Last Token Refresh"; DateTime)
        {
            Caption = 'Last Token Refresh';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(24; "Client Secret Encrypted"; Blob)
        {
            Caption = 'Client Secret (Encrypted)';
            DataClassification = EndUserPseudonymousIdentifiers;
        }

        // === Processing Settings ===
        field(30; "Enable e-Invoice"; Boolean)
        {
            Caption = 'Enable e-Invoice';
            DataClassification = CustomerContent;
        }

        field(31; "Default Schema Version"; Code[10])
        {
            Caption = 'Default Schema Version';
            DataClassification = CustomerContent;
            InitValue = '1.0';
        }

        field(32; "Batch Size"; Integer)
        {
            Caption = 'Batch Size';
            DataClassification = CustomerContent;
            InitValue = 50;
            MinValue = 1;
            MaxValue = 100;

            trigger OnValidate()
            begin
                if "Batch Size" > 100 then
                    Error('Batch size cannot exceed 100 due to LHDN rate limits');
            end;
        }

        field(33; "Validation Wait Seconds"; Integer)
        {
            Caption = 'Validation Wait Duration (Seconds)';
            DataClassification = CustomerContent;
            InitValue = 5;
            MinValue = 0;
            MaxValue = 300;
        }

        field(34; "Auto Submit on Posting"; Boolean)
        {
            Caption = 'Auto Submit on Posting';
            DataClassification = CustomerContent;
        }

        field(35; "Use Batch Queue"; Boolean)
        {
            Caption = 'Use Batch Queue';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        // === Testing & Debug ===
        field(40; "Use Mock API"; Boolean)
        {
            Caption = 'Use Mock API (Testing)';
            DataClassification = CustomerContent;
        }

        field(41; "Enable Debug Logging"; Boolean)
        {
            Caption = 'Enable Debug Logging';
            DataClassification = CustomerContent;
        }

        field(42; "Export API Payloads"; Boolean)
        {
            Caption = 'Export API Payloads';
            DataClassification = CustomerContent;
        }
        field(50; "TIN Validation Mode"; Enum "TIN Validation Mode EINV")
        {
            Caption = 'TIN Validation Mode';
            DataClassification = CustomerContent;
            InitValue = "Format Only";
            ToolTip = 'Controls how TIN validation is performed:\Format Only: Validate format immediately (no API call)\Auto API: Validate format + call LHDN API automatically\Manual: Validate format only, use button for API validation';
        }

        field(51; "Auto-Normalize TIN"; Boolean)
        {
            Caption = 'Auto-Normalize TIN';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Automatically normalize TINs according to LHDN rules (IG prefix, remove leading zeros, etc.)';
        }

        field(52; "TIN Validation Timeout"; Integer)
        {
            Caption = 'TIN Validation Timeout (seconds)';
            DataClassification = CustomerContent;
            InitValue = 10;
            MinValue = 5;
            MaxValue = 60;
            ToolTip = 'Maximum time to wait for LHDN API response';
        }

        field(53; "Skip Validation on Import"; Boolean)
        {
            Caption = 'Skip API Validation on Bulk Import';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'When enabled, API validation is skipped during bulk imports (RapidStart, Excel). Use batch validation after import.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetClientSecret(): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        InStr: InStream;
        Secret: Text;
    begin
        Rec.CalcFields("Client Secret Encrypted");

        if not Rec."Client Secret Encrypted".HasValue then
            exit('');

        Rec."Client Secret Encrypted".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Secret);

        if Secret = '' then
            exit('');

        // Decrypt if encryption is enabled
        if CryptographyMgt.IsEncryptionEnabled() then begin
            if CryptographyMgt.IsEncryptionPossible() then
                exit(CryptographyMgt.Decrypt(Secret))
            else
                Error('Encryption is enabled but not possible in this environment');
        end else
            exit(Secret);
    end;

    procedure SetClientSecret(NewSecret: Text)
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        OutStr: OutStream;
        EncryptedSecret: Text;
    begin
        if NewSecret = '' then
            Error('Client Secret cannot be empty');

        // Encrypt if possible
        if CryptographyMgt.IsEncryptionEnabled() then begin
            if not CryptographyMgt.IsEncryptionPossible() then
                Error('Encryption is enabled but not possible. Please enable encryption in Business Central.');
            EncryptedSecret := CryptographyMgt.EncryptText(NewSecret);
        end else begin
            Message('Warning: Encryption is not enabled. Secret will be stored in plain text.');
            EncryptedSecret := NewSecret;
        end;

        Clear(Rec."Client Secret Encrypted");
        Rec."Client Secret Encrypted".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(EncryptedSecret);

        if IsNullGuid("Client Secret Key") then
            "Client Secret Key" := CreateGuid();
    end;

    procedure HasClientSecret(): Boolean
    begin
        Rec.CalcFields("Client Secret Encrypted");
        exit(Rec."Client Secret Encrypted".HasValue);
    end;

    procedure DeleteClientSecret()
    begin
        Clear(Rec."Client Secret Encrypted");
        Clear(Rec."Client Secret Key");
    end;

    local procedure UpdateAPIEndpoints()
    begin
        case Environment of
            Environment::Sandbox:
                "API Base URL" := 'https://preprod-api.myinvois.hasil.gov.my';
            Environment::Production:
                "API Base URL" := 'https://api.myinvois.hasil.gov.my';
        end;
    end;
}
