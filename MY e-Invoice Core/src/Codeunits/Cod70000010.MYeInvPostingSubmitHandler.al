// ═════════════════════════════════════════════════════════════════
// Update Posting Integration to respect Submit Flag
// ═════════════════════════════════════════════════════════════════
codeunit 70000010 "MY eInv Posting Submit Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
    local procedure "Sales-Post_OnAfterPostSalesDoc"(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
        Setup: Record "MY eInv Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ShouldSubmit: Boolean;
    begin
        // Check if e-invoicing is enabled
        if not Setup.Get() then
            exit;

        // Determine if we should submit
        ShouldSubmit := false;

        if Setup."Enable Auto Submission" and Setup."Auto Submit on Posting" then
            ShouldSubmit := true
        else if SalesHeader."MY eInv Submit On Post" then
            ShouldSubmit := true;

        if not ShouldSubmit then
            exit;

        // Handle Invoice
        if SalesInvHdrNo <> '' then begin
            if SalesInvoiceHeader.Get(SalesInvHdrNo) then begin
                // Copy e-invoice type from Sales Header
                SalesInvoiceHeader."MY eInv Type Code" := SalesHeader."MY eInv Type Code";
                SalesInvoiceHeader."MY eInv Type Description" := SalesHeader."MY eInv Type Description";
                SalesInvoiceHeader.Modify();

                // Submit
                SubmitInvoice(SalesInvoiceHeader, Setup);
            end;
        end;

        // Handle Credit Memo
        if SalesCrMemoHdrNo <> '' then begin
            if SalesCrMemoHeader.Get(SalesCrMemoHdrNo) then begin
                // Copy e-invoice type
                SalesCrMemoHeader."MY eInv Type Code" := SalesHeader."MY eInv Type Code";
                SalesCrMemoHeader."MY eInv Type Description" := SalesHeader."MY eInv Type Description";
                SalesCrMemoHeader.Modify();

                // Submit
                SubmitCreditMemo(SalesCrMemoHeader, Setup);
            end;
        end;
    end;

    local procedure SubmitInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; Setup: Record "MY eInv Setup")
    var
        DocumentProcessor: Codeunit "MY eInv Document Processor";
    begin
        if not TrySubmitInvoice(SalesInvoiceHeader) then begin
            if Setup."Show Submission Errors" then
                Message('Invoice %1 was posted successfully but failed to submit to MyInvois:\%2\You can retry submission from the posted invoice.',
                    SalesInvoiceHeader."No.", GetLastErrorText());
        end else begin
            if Setup."Show Submission Success" then
                Message('✓ Invoice %1 was posted and submitted to MyInvois successfully.', SalesInvoiceHeader."No.");
        end;
    end;

    [TryFunction]
    local procedure TrySubmitInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DocumentProcessor: Codeunit "MY eInv Document Processor";
    begin
        DocumentProcessor.ProcessSalesInvoice(SalesInvoiceHeader);
    end;

    local procedure SubmitCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; Setup: Record "MY eInv Setup")
    var
        DocumentProcessor: Codeunit "MY eInv Document Processor";
    begin
        if not TrySubmitCreditMemo(SalesCrMemoHeader) then begin
            if Setup."Show Submission Errors" then
                Message('Credit Memo %1 was posted successfully but failed to submit to MyInvois:\%2\You can retry submission from the posted credit memo.',
                    SalesCrMemoHeader."No.", GetLastErrorText());
        end else begin
            if Setup."Show Submission Success" then
                Message('✓ Credit Memo %1 was posted and submitted to MyInvois successfully.', SalesCrMemoHeader."No.");
        end;
    end;

    [TryFunction]
    local procedure TrySubmitCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        DocumentProcessor: Codeunit "MY eInv Document Processor";
    begin
        DocumentProcessor.ProcessSalesCreditMemo(SalesCrMemoHeader);
    end;
}
