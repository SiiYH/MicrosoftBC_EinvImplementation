pageextension 70000055 "MY eInv Sales Order List" extends "Sales Order List"
{
    layout
    {
        addafter("No.")
        {
            field("MY eInv Type Code"; Rec."MY eInv Type Code")
            {
                ApplicationArea = All;
                ToolTip = 'E-Invoice type code.';
                Visible = false;
            }

            field("MY eInv Submit On Post"; Rec."MY eInv Submit On Post")
            {
                ApplicationArea = All;
                ToolTip = 'Will be submitted to MyInvois when posted.';
                StyleExpr = SubmitStyleExpr;
            }
        }
    }

    actions
    {
        addfirst(processing)
        {
            group("E-Invoice Batch")
            {
                Caption = 'E-Invoice Batch';
                Image = ElectronicDoc;

                action(EnableSubmitOnPostBatch)
                {
                    Caption = 'Enable Submit on Post';
                    ApplicationArea = All;
                    Image = SendApprovalRequest;
                    ToolTip = 'Enable automatic e-invoice submission for selected orders.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        UpdateCount: Integer;
                    begin
                        CurrPage.SetSelectionFilter(SalesHeader);
                        if SalesHeader.FindSet() then
                            repeat
                                if (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) and
                                   (SalesHeader."MY eInv Type Code" <> '') then begin
                                    SalesHeader."MY eInv Submit On Post" := true;
                                    SalesHeader.Modify();
                                    UpdateCount += 1;
                                end;
                            until SalesHeader.Next() = 0;

                        Message('Enabled submit on post for %1 order(s).', UpdateCount);
                        CurrPage.Update(false);
                    end;
                }

                action(SetEInvoiceTypeBatch)
                {
                    Caption = 'Set E-Invoice Type';
                    ApplicationArea = All;
                    Image = Setup;
                    ToolTip = 'Set e-invoice type for selected orders.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        LHDNCode: Record "MY eInv LHDN Code";
                        UpdateCount: Integer;
                    begin
                        // Prompt for e-invoice type
                        LHDNCode.SetRange("Code Type", LHDNCode."Code Type"::"E-Invoice Type");
                        if Page.RunModal(Page::"MY eInv Code List", LHDNCode) <> Action::LookupOK then
                            exit;

                        // Update selected orders
                        CurrPage.SetSelectionFilter(SalesHeader);
                        if SalesHeader.FindSet() then
                            repeat
                                if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                                    SalesHeader."MY eInv Type Code" := LHDNCode.Code;
                                    SalesHeader."MY eInv Type Description" := LHDNCode.Description;
                                    SalesHeader.Modify();
                                    UpdateCount += 1;
                                end;
                            until SalesHeader.Next() = 0;

                        Message('Set e-invoice type for %1 order(s).', UpdateCount);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."MY eInv Submit On Post" then
            SubmitStyleExpr := 'Favorable'
        else
            SubmitStyleExpr := 'Standard';
    end;

    var
        SubmitStyleExpr: Text;
}
