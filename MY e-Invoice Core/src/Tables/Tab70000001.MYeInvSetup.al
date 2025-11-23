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
        field(63; "Prompt Submit On Post"; Boolean)
        {
            Caption = 'Prompt Submit on Post';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(64; "Enable Auto Submission"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(65; "Show Submission Errors"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(66; "Show Submission Success"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(100; "Document Version"; Option)
        {
            Caption = 'Document Version';
            OptionMembers = "1.0","1.1";
            OptionCaption = '1.0 (No Signature),1.1 (With Signature)';

            trigger OnValidate()
            begin
                /* if "Document Version" = "Document Version"::"1.1" then
                    TestField("Certificate Configured", true); */
            end;
        }

        field(101; "Certificate File Name"; Text[250])
        {
            Caption = 'Certificate File Name';
        }

        field(102; "Certificate Content"; Blob)
        {
            Caption = 'Certificate Content';
            Subtype = Bitmap;
        }

        field(103; "Certificate Password Key"; Guid)
        {
            Caption = 'Certificate Password Key';
        }

        field(104; "Certificate Configured"; Boolean)
        {
            Caption = 'Certificate Configured';
            Editable = false;
        }

        field(105; "Certificate Issuer"; Text[250])
        {
            Caption = 'Certificate Issuer';
            Editable = false;
        }

        field(106; "Certificate Serial Number"; Text[50])
        {
            Caption = 'Certificate Serial Number';
            Editable = false;
        }

        field(107; "Certificate Valid From"; DateTime)
        {
            Caption = 'Certificate Valid From';
            Editable = false;
        }

        field(108; "Certificate Valid To"; DateTime)
        {
            Caption = 'Certificate Valid To';
            Editable = false;
        }

        field(109; "Certificate Subject"; Text[250])
        {
            Caption = 'Certificate Subject';
            Editable = false;
        }
        field(110; "Azure Function URL"; Text[250])
        {
            Caption = 'Azure Function URL';
            ToolTip = 'URL of your Azure Function for document signing (e.g., https://your-app.azurewebsites.net/api/SignDocument)';
        }

        field(111; "Azure Function Key"; Guid)
        {
            Caption = 'Azure Function Key';
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

    // Methods for secure certificate storage
    procedure SetCertificatePassword(Password: Text)
    begin
        if not IsNullGuid("Certificate Password Key") then
            IsolatedStorage.Delete("Certificate Password Key", DataScope::Company);

        "Certificate Password Key" := CreateGuid();
        IsolatedStorage.Set("Certificate Password Key", Password, DataScope::Company);
    end;

    procedure GetCertificatePassword(): Text
    var
        Password: Text;
    begin
        if IsNullGuid("Certificate Password Key") then
            exit('');

        if IsolatedStorage.Get("Certificate Password Key", DataScope::Company, Password) then
            exit(Password);

        exit('');
    end;

    procedure HasCertificate(): Boolean
    begin
        exit("Certificate Configured" and (not IsNullGuid("Certificate Password Key")));
    end;

    // Methods for secure certificate storage
    /* [Scope('OnPrem')]
    procedure SetCertificatePassword(Password: Text)
    var
        IsolatedStorageMgt: Codeunit "Isolated Storage Management";
    begin
        if not IsNullGuid("Certificate Password Key") then
            IsolatedStorageMgt.Delete("Certificate Password Key", DataScope::Company);

        "Certificate Password Key" := CreateGuid();
        IsolatedStorageMgt.Set("Certificate Password Key", Password, DataScope::Company);
    end;

    procedure GetCertificatePassword(): Text
    var
        IsolatedStorageMgt: Codeunit "Isolated Storage Management";
        Password: Text;
    begin
        if IsNullGuid("Certificate Password Key") then
            exit('');

        if IsolatedStorageMgt.Get("Certificate Password Key", DataScope::Company, Password) then
            exit(Password);

        exit('');
    end;

    procedure HasCertificate(): Boolean
    begin
        exit("Certificate Configured" and (not IsNullGuid("Certificate Password Key")));
    end; */

    procedure SetAzureFunctionKey(KeyValue: Text)
    begin
        if not IsNullGuid("Azure Function Key") then
            IsolatedStorage.Delete("Azure Function Key", DataScope::Company);

        "Azure Function Key" := CreateGuid();
        IsolatedStorage.Set("Azure Function Key", KeyValue, DataScope::Company);
    end;

    procedure GetAzureFunctionKey(): Text
    var
        KeyValue: Text;
    begin
        if IsNullGuid("Azure Function Key") then
            exit('');

        if IsolatedStorage.Get("Azure Function Key", DataScope::Company, KeyValue) then
            exit(KeyValue);

        exit('');
    end;
}
