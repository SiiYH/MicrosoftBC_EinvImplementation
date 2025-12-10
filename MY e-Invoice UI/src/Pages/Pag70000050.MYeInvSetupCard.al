page 70000050 "MY eInv Setup Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "MY eInv Setup";
    Caption = 'MY eInvoice Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            // Status Overview at the top
            group(StatusOverview)
            {
                Caption = 'Status Overview';

                field(OverallStatusText; OverallStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    Editable = false;
                    Style = StrongAccent;
                    StyleExpr = OverallStatusStyle;
                    ToolTip = 'Overall configuration and verification status.';

                    trigger OnDrillDown()
                    begin
                        Message(GetStatusDetails());
                    end;
                }
            }

            group(Environment)
            {
                Caption = 'Environment Configuration';

                field(Environment_; Rec.Environment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Select Sandbox for testing or Production for live e-invoicing.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Portal Base URL"; Rec."Portal Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'MyInvois portal base URL for viewing submitted documents';
                }

                field("API Base URL"; Rec."API Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Automatically set based on selected environment.';
                    Editable = false;
                }

                field("Identity Service URL"; Rec."Identity Service URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Authentication endpoint for the selected environment.';
                    Editable = false;
                }
            }

            group(Credentials)
            {
                Caption = 'API Credentials';

                field(ClientIDDisplay; ClientIDDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Client ID';
                    ToolTip = 'Enter your Client ID from LHDN MyInvois portal.';
                    ExtendedDatatype = Masked;
                    ShowMandatory = not HasClientID;

                    trigger OnValidate()
                    begin
                        if ClientIDDisplay <> '' then begin
                            Rec.SetClientID(ClientIDDisplay);
                            Rec.Modify(true);
                            ClientIDDisplay := '********************************';
                            HasClientID := true;
                            UpdateDisplayFields();
                        end;
                    end;
                }

                field(ClientSecretDisplay; ClientSecretDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret';
                    ToolTip = 'Enter your Client Secret from LHDN MyInvois portal.';
                    ExtendedDatatype = Masked;
                    ShowMandatory = not HasClientSecret;

                    trigger OnValidate()
                    begin
                        if ClientSecretDisplay <> '' then begin
                            Rec.SetClientSecret(ClientSecretDisplay);
                            Rec.Modify(true);
                            ClientSecretDisplay := '********************************';
                            HasClientSecret := true;
                            UpdateDisplayFields();
                        end;
                    end;
                }

                group(CredentialStatus)
                {
                    ShowCaption = false;
                    Visible = HasClientID and HasClientSecret;

                    field(CredentialsConfigured; CredentialsConfiguredTxt)
                    {
                        ApplicationArea = All;
                        Caption = 'Status';
                        Editable = false;
                        Style = Favorable;
                        StyleExpr = true;
                    }
                }
            }

            group(DocumentVersion)
            {
                Caption = 'Document Version Selection';
                field("Document Version"; Rec."Document Version")
                {
                    ApplicationArea = All;
                }
                group(AzureConfiguration)
                {
                    Caption = 'Azure Configuration';

                    field("Azure Function URL"; Rec."Azure Function URL")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Azure Function endpoint for certificate upload and XML signing';
                        MultiLine = true;
                    }
                }
                group(CertificateUpload)
                {
                    Caption = 'Certificate Upload';

                    field("Certificate File Name"; Rec."Certificate File Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Name of the uploaded certificate file';
                        Editable = false;
                    }

                    field("Certificate Configured"; Rec."Certificate Configured")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Indicates if certificate is uploaded to Azure Key Vault';
                        Style = Favorable;
                        StyleExpr = Rec."Certificate Configured";
                    }
                }

                group(CertificateDetails)
                {
                    Caption = 'Certificate Details';
                    Visible = Rec."Certificate Configured";
                    field("Certificate ID"; Rec."Certificate ID")
                    {
                        ToolTip = 'Specifies the value of the Certificate ID field.', Comment = '%';
                    }

                    field("Certificate Issuer"; Rec."Certificate Issuer")
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                    }

                    field("Certificate Subject"; Rec."Certificate Subject")
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                    }

                    field("Certificate Serial Number"; Rec."Certificate Serial Number")
                    {
                        ApplicationArea = All;
                    }

                    field("Certificate Valid From"; Rec."Certificate Valid From")
                    {
                        ApplicationArea = All;
                    }

                    field("Certificate Valid To"; Rec."Certificate Valid To")
                    {
                        ApplicationArea = All;
                        Style = Unfavorable;
                        StyleExpr = ValidStyleExpr;
                    }
                }
                part(MYeInvCertCard; "MY eInv Certificate Card") { ApplicationArea = All; }

            }

            group(TINVerification)
            {
                Caption = 'TIN Verification';
                Visible = HasClientID and HasClientSecret;

                field(CompanyTIN; CompanyTIN)
                {
                    ApplicationArea = All;
                    Caption = 'Company TIN';
                    ToolTip = 'The TIN configured in Company Information.';
                    Style = Strong;
                    StyleExpr = true;
                }

                field("Authenticated TIN"; Rec."Authenticated TIN")
                {
                    ApplicationArea = All;
                    Caption = 'Authenticated TIN';
                    ToolTip = 'The TIN associated with your API credentials (from JWT token).';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = AuthTINStyle;
                }

                field(TINStatusField; TINStatusField)
                {
                    ApplicationArea = All;
                    Caption = 'Verification Status';
                    Editable = false;
                    Style = StrongAccent;
                    StyleExpr = TINStatusStyle;
                    ToolTip = 'Shows whether your company TIN matches the authenticated TIN.';
                }

                field("TIN Verification Date"; Rec."TIN Verification Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Verified';
                    ToolTip = 'Date and time when TIN was last verified.';
                    Editable = false;
                }
            }

            group(Settings)
            {
                Caption = 'Settings';

                field("Auto Submit on Posting"; Rec."Auto Submit on Posting")
                {
                    ApplicationArea = All;
                    ToolTip = 'Automatically submit e-invoices when sales invoices are posted.';
                }

                field("Enable Notifications"; Rec."Enable Notifications")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable receiving notifications from LHDN MyInvois.';
                }

                field("Timeout (Seconds)"; Rec."Timeout (Seconds)")
                {
                    ApplicationArea = All;
                    ToolTip = 'API request timeout in seconds.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection & Verify TIN';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Test API connection and verify that the authenticated TIN matches your company TIN.';

                trigger OnAction()
                var
                    MYeInvAuth: Codeunit "MY eInv Authentication";
                begin
                    if not Confirm('This will authenticate with LHDN MyInvois and verify your TIN. Continue?', true) then
                        exit;

                    if MYeInvAuth.TestConnectionAndVerifyTIN(Rec) then begin
                        UpdateDisplayFields();
                        Message('Connection successful!\Authenticated TIN: %1\Company TIN: %2\Status: %3',
                            Rec."Authenticated TIN", CompanyTIN, TINStatusField);
                    end;
                end;
            }

            action(ClearCredentials)
            {
                ApplicationArea = All;
                Caption = 'Clear Credentials';
                Image = Delete;
                ToolTip = 'Clear stored API credentials.';

                trigger OnAction()
                begin
                    if not Confirm('Are you sure you want to clear all credentials?', false) then
                        exit;

                    Clear(Rec."Client ID");
                    Clear(Rec."Client Secret Key");
                    Clear(Rec."Access Token Key");
                    Clear(Rec."Token Expires At");
                    Clear(Rec."Authenticated TIN");
                    Rec."TIN Verified" := false;
                    Rec.Modify(true);

                    ClientIDDisplay := '';
                    ClientSecretDisplay := '';
                    HasClientID := false;
                    HasClientSecret := false;

                    Message('Credentials cleared successfully.');
                    UpdateDisplayFields();
                    CurrPage.Update(true);
                end;
            }

            action(ViewLogs)
            {
                ApplicationArea = All;
                Caption = 'View API Logs';
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View authentication and API call logs.';

                trigger OnAction()
                begin
                    Message('Log viewer coming soon.');
                end;
            }
            action(SetAzureFunctionKey)
            {
                ApplicationArea = All;
                Caption = 'Set Azure Function Key';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Authentication";
                begin
                    CertMgmt.SetAzureFunctionKey(Rec);
                end;
            }
            action(UploadCertificate)
            {
                ApplicationArea = All;
                Caption = 'Upload Certificate to Azure';
                Image = Certificate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Upload certificate file and send to Azure Key Vault';

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Authentication";
                begin
                    CertMgmt.UploadAndSendCertificateToAzure(Rec);
                end;
            }

            action(TestAzureConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Azure Connection';
                Image = TestReport;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Test connection to Azure Function';

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Authentication";
                begin
                    CertMgmt.TestAzureConnection(Rec);
                end;
            }

            action(RemoveCertificate)
            {
                ApplicationArea = All;
                Caption = 'Remove Certificate';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Remove certificate from Azure Key Vault';

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Authentication";
                begin
                    if Confirm('Are you sure you want to remove the certificate from Azure Key Vault?', false) then
                        CertMgmt.RemoveCertificateFromAzure(Rec);
                end;
            }
            // ============================================
            // 3. HELPER: Set Azure Function Key Action
            // ============================================
            // Add this action to your page
            /*
            action(SetAzureFunctionKey)
            {
                ApplicationArea = All;
                Caption = 'Set Azure Function Key';
                Image = Setup;

                trigger OnAction()
                var
                    CertMgmt: Codeunit "MY eInv Authentication";
                    FunctionKey: Text;
                begin
                    FunctionKey := '';
                    if InputQuery('Azure Function Key', 'Enter your Azure Function Key:', FunctionKey) then
                        CertMgmt.SetAzureFunctionKey(Rec, FunctionKey);
                end;
            }
            */
        }

        area(Navigation)
        {
            action(CompanyInfo)
            {
                ApplicationArea = All;
                Caption = 'Company Information';
                Image = Company;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open Company Information to configure TIN and other details.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Company Information");
                end;
            }

            action(LHDNCodes)
            {
                ApplicationArea = All;
                Caption = 'LHDN Codes';
                Image = CodesList;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View and sync LHDN master data codes.';

                trigger OnAction()
                begin
                    Page.Run(Page::"MY eInv Code List");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        LHDNFeature: Codeunit "MY eInv Feature Management";

    begin
        if not LHDNFeature.IsEInvoiceEnabled() then
            Error('E-Invoice is not enabled. Please enable it in Company Information first.');

        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Environment := Rec.Environment::Sandbox;
            Rec.Insert(true);
        end;

        UpdateDisplayFields();
        ValidStyleExpr := IsExpiringSoon();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayFields();
        ValidStyleExpr := IsExpiringSoon();
    end;

    local procedure IsExpiringSoon(): Boolean
    begin
        if Rec."Certificate Valid To" = 0DT then
            exit(false);
        exit(Rec."Certificate Valid To" < CreateDateTime(CalcDate('<+30D>', Today), 0T));
    end;

    local procedure UpdateDisplayFields()
    var
        CompanyInfo: Record "Company Information";
        MYeInvFeature: Codeunit "MY eInv Feature Management";
    begin
        // Check credentials
        HasClientID := Rec.GetClientID() <> '';
        HasClientSecret := Rec.GetClientSecret() <> '';

        if HasClientID then
            ClientIDDisplay := '********************************';

        if HasClientSecret then
            ClientSecretDisplay := '********************************';

        // Get Company TIN
        CompanyTIN := MYeInvFeature.GetCompanyTIN();

        // Update all status fields
        UpdateOverallStatus();
        UpdateTINStatus();
    end;

    local procedure UpdateOverallStatus()
    begin
        if not HasClientID or not HasClientSecret then begin
            OverallStatusText := '⚠ Not Configured - Enter API Credentials';
            OverallStatusStyle := 'Unfavorable';
        end else if not Rec."TIN Verified" then begin
            OverallStatusText := '⚠ Credentials Entered - Test Connection to Verify TIN';
            OverallStatusStyle := 'Attention';
        end else if Rec."Authenticated TIN" = CompanyTIN then begin
            OverallStatusText := '✓ Ready - All checks passed';
            OverallStatusStyle := 'Favorable';
        end else begin
            OverallStatusText := '✗ TIN Mismatch - Check Configuration';
            OverallStatusStyle := 'Unfavorable';
        end;
    end;

    local procedure UpdateTINStatus()
    begin
        if not Rec."TIN Verified" then begin
            TINStatusField := 'Not Verified - Click "Test Connection"';
            TINStatusStyle := 'Subordinate';
            AuthTINStyle := 'Subordinate';
        end else if Rec."Authenticated TIN" = '' then begin
            TINStatusField := 'Unknown - Re-test Connection';
            TINStatusStyle := 'Attention';
            AuthTINStyle := 'Attention';
        end else if Rec."Authenticated TIN" = CompanyTIN then begin
            TINStatusField := '✓ Verified & Matched';
            TINStatusStyle := 'Favorable';
            AuthTINStyle := 'Favorable';
        end else begin
            TINStatusField := '✗ Mismatch Detected';
            TINStatusStyle := 'Unfavorable';
            AuthTINStyle := 'Unfavorable';
        end;
    end;

    local procedure GetStatusDetails(): Text
    var
        Details: Text;
    begin
        Details := 'Configuration Status Details:\';
        Details += '================================\';
        Details += StrSubstNo('Client ID: %1\', GetCheckMark(HasClientID));
        Details += StrSubstNo('Client Secret: %1\', GetCheckMark(HasClientSecret));
        Details += StrSubstNo('TIN Verified: %1\', GetCheckMark(Rec."TIN Verified"));
        if Rec."TIN Verified" then
            Details += StrSubstNo('TIN Match: %1\', GetCheckMark(Rec."Authenticated TIN" = CompanyTIN));
        exit(Details);
    end;

    local procedure GetCheckMark(Condition: Boolean): Text
    begin
        if Condition then
            exit('✓ Yes')
        else
            exit('✗ No');
    end;

    var
        ValidStyleExpr: Boolean;
        ClientIDDisplay: Text;
        ClientSecretDisplay: Text;
        ShowClientID: Boolean;
        HasClientID: Boolean;
        HasClientSecret: Boolean;
        OverallStatusText: Text;
        OverallStatusStyle: Text;
        CompanyTIN: Text[20];
        TINStatusField: Text;
        TINStatusStyle: Text;
        AuthTINStyle: Text;
        CredentialsConfiguredTxt: Label '✓ Credentials configured';
}