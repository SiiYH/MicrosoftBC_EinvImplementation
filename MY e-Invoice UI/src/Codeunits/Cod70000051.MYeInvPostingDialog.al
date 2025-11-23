codeunit 70000051 "MY eInv Posting Dialog"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    var
        Setup: Record "MY eInv Setup";
        CompanyInfo: Record "Company Information";
        ConfirmManagement: Codeunit "Confirm Management";
        SubmitEInvoiceQst: Label 'Do you want to submit this document to MyInvois after posting?';
    begin
        // Skip if not invoice or credit memo
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]) then
            exit;

        // Skip in preview mode
        if PreviewMode then
            exit;

        // Check if e-invoicing is enabled
        CompanyInfo.Get();
        if not CompanyInfo."MY eInv Enabled" then
            exit;

        // Get setup
        if not Setup.Get() then
            exit;

        // Skip if auto-submission is enabled (handled by event subscriber)
        if Setup."Enable Auto Submission" and Setup."Auto Submit on Posting" then
            exit;

        // Ask user if they want to submit
        if Setup."Prompt Submit On Post" then begin
            if ConfirmManagement.GetResponseOrDefault(SubmitEInvoiceQst, true) then
                SalesHeader."MY eInv Submit On Post" := true
            else
                SalesHeader."MY eInv Submit On Post" := false;
        end;
    end;
}
