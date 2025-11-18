table 70000001 "MY eInv Setup"
{
    Caption = 'MY eInvoice Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        // Environment Configuration
        field(10; Environment; Enum "MY eInv Environment")
        {
            Caption = 'Environment';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateURLs();
                ClearAuthenticationCache();
            end;
        }

        // API Credentials (Encrypted)
        field(20; "Client ID"; Guid)
        {
            Caption = 'Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret';
            DataClassification = EndUserIdentifiableInformation;
        }

        // API URLs (Auto-populated based on environment)
        field(30; "API Base URL"; Text[250])
        {
            Caption = 'API Base URL';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(31; "Identity Service URL"; Text[250])
        {
            Caption = 'Identity Service URL';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // Authenticated TIN (Retrieved from Token)
        field(40; "Authenticated TIN"; Text[20])
        {
            Caption = 'Authenticated TIN';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "TIN Verified"; Boolean)
        {
            Caption = 'TIN Verified';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(42; "TIN Verification Date"; DateTime)
        {
            Caption = 'TIN Verification Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // Token Cache
        field(50; "Access Token Key"; Guid)
        {
            Caption = 'Access Token';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(51; "Token Expires At"; DateTime)
        {
            Caption = 'Token Expires At';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // Settings
        field(60; "Auto Submit on Posting"; Boolean)
        {
            Caption = 'Auto Submit on Posting';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(61; "Enable Notifications"; Boolean)
        {
            Caption = 'Enable Notifications';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(62; "Timeout (Seconds)"; Integer)
        {
            Caption = 'API Timeout (Seconds)';
            DataClassification = CustomerContent;
            InitValue = 30;
            MinValue = 10;
            MaxValue = 300;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        UpdateURLs();
    end;

    local procedure UpdateURLs()
    begin
        case Environment of
            Environment::Sandbox:
                begin
                    "API Base URL" := 'https://preprod-api.myinvois.hasil.gov.my';
                    "Identity Service URL" := 'https://preprod-api.myinvois.hasil.gov.my/connect/token';
                end;
            Environment::Production:
                begin
                    "API Base URL" := 'https://api.myinvois.hasil.gov.my';
                    "Identity Service URL" := 'https://api.myinvois.hasil.gov.my/connect/token';
                end;
        end;
    end;

    local procedure ClearAuthenticationCache()
    begin
        Clear("Access Token Key");
        Clear("Token Expires At");
        Clear("Authenticated TIN");
        "TIN Verified" := false;
        Clear("TIN Verification Date");
    end;

    /// <summary>
    /// onprem development
    /// </summary>
    /// <returns></returns>

    procedure GetClientID(): Text
    var
        ClientIDText: Text;
    begin
        if not IsNullGuid("Client ID") then
            if IsolatedStorage.Get("Client ID", DataScope::Company, ClientIDText) then
                exit(ClientIDText);
        exit('');
    end;

    procedure SetClientID(ClientIDText: Text)
    var
    begin
        "Client ID" := CreateGuid();
        IsolatedStorage.Set("Client ID", ClientIDText, DataScope::Company);
    end;

    procedure GetClientSecret(): Text
    var
        ClientSecretText: Text;
    begin
        if not IsNullGuid("Client Secret Key") then
            if IsolatedStorage.Get("Client Secret Key", DataScope::Company, ClientSecretText) then
                exit(ClientSecretText);
        exit('');
    end;

    procedure SetClientSecret(ClientSecretText: Text)
    var
    begin
        "Client Secret Key" := CreateGuid();
        IsolatedStorage.Set("Client Secret Key", ClientSecretText, DataScope::Company);
        ClearAuthenticationCache();
    end;

    procedure GetAccessToken(): Text
    var
        AccessTokenText: Text;
    begin
        if not IsNullGuid("Access Token Key") then
            if IsolatedStorage.Get("Access Token Key", DataScope::Company, AccessTokenText) then
                exit(AccessTokenText);
        exit('');
    end;

    procedure SetAccessToken(AccessTokenText: Text; ExpiresInSeconds: Integer)
    var
    begin
        "Access Token Key" := CreateGuid();
        IsolatedStorage.Set("Access Token Key", AccessTokenText, DataScope::Company);
        "Token Expires At" := CurrentDateTime + (ExpiresInSeconds * 1000);
    end;

    procedure IsTokenValid(): Boolean
    begin
        if IsNullGuid("Access Token Key") then
            exit(false);
        if "Token Expires At" <= CurrentDateTime then
            exit(false);
        exit(true);
    end;
}
