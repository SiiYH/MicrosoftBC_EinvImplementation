pageextension 70000054 "MY eInv Sales Order Submit" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            group("E-Invoice Submission")
            {
                Caption = 'E-Invoice Submission';
                Visible = ShowEInvoiceSubmitGroup;

                field("MY eInv Submit On Post"; Rec."MY eInv Submit On Post")
                {
                    ApplicationArea = All;
                    Caption = 'Submit to MyInvois on Post';
                    ToolTip = 'If enabled, the invoice will be automatically submitted to MyInvois after posting.';

                    trigger OnValidate()
                    begin
                        if Rec."MY eInv Submit On Post" then begin
                            if Rec."MY eInv Type Code" = '' then
                                Error('Please select E-Invoice Type Code before enabling auto-submission.');
                        end;
                    end;
                }

                field("E-Invoice Type Info"; EInvoiceTypeInfo)
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Type';
                    ToolTip = 'The e-invoice type that will be used when posting.';
                    Editable = false;
                    StyleExpr = EInvoiceTypeStyleExpr;
                }
            }
        }
    }

    actions
    {
        addafter("F&unctions")
        {
            group("E-Invoice")
            {
                Caption = 'E-Invoice';
                Image = ElectronicDoc;

                action(SetEInvoiceType)
                {
                    Caption = 'Set E-Invoice Type';
                    ApplicationArea = All;
                    Image = Setup;
                    ToolTip = 'Set the e-invoice type for this order (will be transferred to invoice).';

                    trigger OnAction()
                    var
                        LHDNCodeList: Page "MY eInv Code List";
                        LHDNCode: Record "MY eInv LHDN Code";
                    begin
                        LHDNCode.SetRange("Code Type", LHDNCode."Code Type"::"E-Invoice Type");
                        if Page.RunModal(Page::"MY eInv Code List", LHDNCode) = Action::LookupOK then begin
                            Rec."MY eInv Type Code" := LHDNCode.Code;
                            Rec."MY eInv Type Description" := LHDNCode.Description;
                            Rec.Modify();
                            CurrPage.Update();
                        end;
                    end;
                }

                action(EnableSubmitOnPost)
                {
                    Caption = 'Enable Submit on Post';
                    ApplicationArea = All;
                    Image = SendApprovalRequest;
                    ToolTip = 'Enable automatic submission to MyInvois when this order is posted.';

                    trigger OnAction()
                    begin
                        if Rec."MY eInv Type Code" = '' then
                            Error('Please set E-Invoice Type Code first.');

                        Rec."MY eInv Submit On Post" := true;
                        Rec.Modify();
                        CurrPage.Update();
                        Message('E-Invoice will be submitted automatically when this order is posted.');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEInvoiceInfo();
    end;

    local procedure UpdateEInvoiceInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ShowEInvoiceSubmitGroup := CompanyInfo."MY eInv Enabled" and (Rec."Document Type" = Rec."Document Type"::Order);

        if Rec."MY eInv Type Code" <> '' then begin
            EInvoiceTypeInfo := Rec."MY eInv Type Code" + ' - ' + Rec."MY eInv Type Description";
            EInvoiceTypeStyleExpr := 'Favorable';
        end else begin
            EInvoiceTypeInfo := 'Not Set (Required for e-invoicing)';
            EInvoiceTypeStyleExpr := 'Unfavorable';
        end;
    end;

    var
        ShowEInvoiceSubmitGroup: Boolean;
        EInvoiceTypeInfo: Text;
        EInvoiceTypeStyleExpr: Text;
}
