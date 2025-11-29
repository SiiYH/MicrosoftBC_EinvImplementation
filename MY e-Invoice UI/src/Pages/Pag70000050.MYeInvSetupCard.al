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
                group(CertifateConfiguration)
                {
                    Caption = 'Certificate Configuration';

                    field("Certificate Configured"; Rec."Certificate Configured")
                    {
                        ToolTip = 'Specifies the value of the Certificate Configured field.', Comment = '%';
                    }
                    field("Certificate Content"; Rec."Certificate Content")
                    {
                        ToolTip = 'Specifies the value of the Certificate Content field.', Comment = '%';
                    }
                    field("Certificate File Name"; Rec."Certificate File Name")
                    {
                        ToolTip = 'Name of the uploaded certificate file.';
                    }
                    field("Certificate Valid To"; Rec."Certificate Valid To")
                    {
                        ToolTip = 'Certificate expiry date.';
                    }
                    field("Certificate Issuer"; Rec."Certificate Issuer")
                    {
                        ToolTip = 'Certificate authority that issued this certificate.';
                    }
                    field("Certificate Subject"; Rec."Certificate Subject")
                    {
                        ToolTip = 'Certificate subject (organization details).';
                    }
                    field("Certificate Valid From"; Rec."Certificate Valid From")
                    {
                        ToolTip = 'Certificate validity start date.';
                    }
                    field("Certificate Password Key"; Rec."Certificate Password Key")
                    {
                        ToolTip = 'Specifies the value of the Certificate Password Key field.', Comment = '%';
                    }
                    field("Certificate Serial Number"; Rec."Certificate Serial Number")
                    {
                        ToolTip = 'Unique serial number of the certificate.';
                    }
                }

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
                    Editable = false;
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
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayFields();
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