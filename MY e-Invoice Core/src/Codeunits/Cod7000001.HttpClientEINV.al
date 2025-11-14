namespace MYeInvoiceCore.MYeInvoiceCore;
// ============================================================================
// HTTP CLIENT HELPER
// ============================================================================

/// <summary>
/// Simple HTTP client for downloading JSON files
/// </summary>
codeunit 7000001 "Http Client EINV"
{
    procedure GetRequest(URL: Text; var ResponseText: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
    begin
        if not HttpClient.Get(URL, HttpResponse) then
            exit(false);

        if not HttpResponse.IsSuccessStatusCode then
            exit(false);

        HttpResponse.Content.ReadAs(ResponseText);
        exit(true);
    end;
}
