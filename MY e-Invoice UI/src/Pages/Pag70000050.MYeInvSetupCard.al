page 70000050 "MY eInv Setup Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "MY eInv Setup";
    Caption = 'MY eInv Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Status)
            {
                Caption = 'Status';

                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Configuration Status';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Shows the current configuration status.';
                }

                field("TIN Verified"; Rec."TIN Verified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates if the TIN has been verified against API credentials.';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TINVerifiedStyle;
                }

                field("Authenticated TIN"; Rec."Authenticated TIN")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the TIN associated with the API credentials (from JWT token).';
                    Editable = false;
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

                field("API Base URL"; Rec."API Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Automatically set based on selected environment.';
                }

                field("Identity Service URL"; Rec."Identity Service URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Authentication endpoint for the selected environment.';
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
                        end;
                    end;
                }

                field(ShowClientID; ShowClientID)
                {
                    ApplicationArea = All;
                    Caption = 'Show Client ID';
                    ToolTip = 'Toggle to show/hide the Client ID value.';

                    trigger OnValidate()
                    begin
                        if ShowClientID then
                            ClientIDDisplay := Rec.GetClientID()
                        else
                            ClientIDDisplay := '********************************';
                        CurrPage.Update(false);
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
                        end;
                    end;
                }

                /* field(ShowClientSecret; ShowClientSecret)
                {
                    ApplicationArea = All;
                    Caption = 'Show Client Secret';
                    ToolTip = 'Toggle to show/hide the Client Secret value.';

                    trigger OnValidate()
                    begin
                        if ShowClientSecret then
                            ClientSecretDisplay := Rec.GetClientSecret()
                        else
                            ClientSecretDisplay := '********************************';
                        CurrPage.Update(false);
                    end;
                } */


                group(CredentialStatus)
                {
                    ShowCaption = false;
                    Visible = HasClientID and HasClientSecret;

                    field(CredentialsConfigured; CredentialsConfiguredTxt)
                    {
                        ApplicationArea = All;
                        Caption = 'Credentials Status';
                        Editable = false;
                        Style = Favorable;
                        StyleExpr = true;
                    }
                }
            }
            group(Verification)
            {
                Caption = 'TIN Verification';
                Visible = HasClientID and HasClientSecret;

                field("TIN Verification Date"; Rec."TIN Verification Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when TIN was last verified.';
                    Editable = false;
                }

                field(CompanyTIN; CompanyTIN)
                {
                    ApplicationArea = All;
                    Caption = 'Company TIN (from Company Information)';
                    ToolTip = 'The TIN configured in Company Information.';
                    Editable = false;
                }

                field(TINMatchStatus; TINMatchStatus)
                {
                    ApplicationArea = All;
                    Caption = 'TIN Match Status';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TINMatchStyle;
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

                    if MYeInvAuth.TestConnectionAndVerifyTIN(Rec) then
                        Message('Connection successful!\Authenticated TIN: %1\Company TIN: %2\Status: %3',
                            Rec."Authenticated TIN", CompanyTIN,
                            TINMatchStatus);
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
                    CurrPage.Update(true);
                end;
            }

            action(ViewLogs)
            {
                ApplicationArea = All;
                Caption = 'View API Logs';
                Image = Log;
                ToolTip = 'View authentication and API call logs.';

                trigger OnAction()
                begin
                    // Open log page (to be created)
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
                ToolTip = 'View and sync LHDN master data codes.';

                trigger OnAction()
                begin
                    Page.Run(Page::"MY eInv Code List");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
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

        // Update status
        UpdateStatus();
        UpdateTINMatchStatus();
    end;

    local procedure UpdateStatus()
    begin
        if not HasClientID or not HasClientSecret then begin
            StatusText := 'Not Configured';
            StatusStyle := 'Unfavorable';
        end else if not Rec."TIN Verified" then begin
            StatusText := 'Configured (TIN Not Verified)';
            StatusStyle := 'Attention';
        end else if Rec."Authenticated TIN" = CompanyTIN then begin
            StatusText := 'Ready';
            StatusStyle := 'Favorable';
        end else begin
            StatusText := 'TIN Mismatch - Check Configuration';
            StatusStyle := 'Unfavorable';
        end;

        if Rec."TIN Verified" then
            TINVerifiedStyle := 'Favorable'
        else
            TINVerifiedStyle := 'Unfavorable';
    end;

    local procedure UpdateTINMatchStatus()
    begin
        if not Rec."TIN Verified" then begin
            TINMatchStatus := 'Not Verified';
            TINMatchStyle := 'Subordinate';
        end else if Rec."Authenticated TIN" = '' then begin
            TINMatchStatus := 'Unknown';
            TINMatchStyle := 'Attention';
        end else if Rec."Authenticated TIN" = CompanyTIN then begin
            TINMatchStatus := '✓ Match - Ready to Use';
            TINMatchStyle := 'Favorable';
        end else begin
            TINMatchStatus := '✗ Mismatch - Please Check';
            TINMatchStyle := 'Unfavorable';
        end;
    end;

    var
        ClientIDDisplay: Text;
        ClientSecretDisplay: Text;
        ShowClientID: Boolean;
        ShowClientSecret: Boolean;
        HasClientID: Boolean;
        HasClientSecret: Boolean;
        StatusText: Text;
        StatusStyle: Text;
        TINVerifiedStyle: Text;
        CompanyTIN: Text[20];
        TINMatchStatus: Text;
        TINMatchStyle: Text;
        CredentialsConfiguredTxt: Label '✓ Credentials are configured';
}
