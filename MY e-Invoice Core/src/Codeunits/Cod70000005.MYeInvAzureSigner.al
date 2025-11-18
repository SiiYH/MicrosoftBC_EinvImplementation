codeunit 70000005 "MY eInv External Signer"
{
    procedure SignDocumentViaAPI(DocumentXML: Text; Setup: Record "MY eInv Setup"): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        SignedXML: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        // Prepare request
        RequestBody := PrepareSigningRequest(DocumentXML, Setup);
        Content.WriteFrom(RequestBody);
        Content.GetHeaders().Remove('Content-Type');
        Content.GetHeaders().Add('Content-Type', 'application/json');

        // Call signing service (e.g., Azure Function)
        if not Client.Post('https://your-signing-service.azurewebsites.net/api/sign', Content, Response) then
            Error('Failed to connect to signing service.');

        if not Response.IsSuccessStatusCode then
            Error('Signing service returned error: %1', Response.HttpStatusCode);

        Response.Content.ReadAs(ResponseText);
        SignedXML := ParseSignedDocument(ResponseText);

        exit(SignedXML);
    end;
}
