codeunit 70000002 "MY eInv Authentication"
{
    procedure TestConnectionAndVerifyTIN(var MYeInvSetup: Record "MY eInv Setup"): Boolean
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
        AccessToken: Text;
        ExpiresIn: Integer;
    begin
        // Validate setup
        if MYeInvSetup.GetClientID() = '' then
            Error('Client ID is not configured.');
        if MYeInvSetup.GetClientSecret() = '' then
            Error('Client Secret is not configured.');
        if MYeInvSetup."Identity Service URL" = '' then
            Error('Identity Service URL is not configured.');

        // Build authentication request
        RequestBody := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&scope=InvoicingAPI',
            MYeInvSetup.GetClientID(),
            MYeInvSetup.GetClientSecret());

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        // Set timeout
        HttpClient.Timeout(MYeInvSetup."Timeout (Seconds)" * 1000);

        // Make request
        if not HttpClient.Post(MYeInvSetup."Identity Service URL", HttpContent, HttpResponse) then
            Error('Failed to connect to LHDN MyInvois authentication service.');

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode then
            Error('Authentication failed: %1\Response: %2', HttpResponse.HttpStatusCode, ResponseText);

        // Parse response and extract token
        if not ParseAuthResponse(ResponseText, AccessToken, ExpiresIn) then
            Error('Failed to parse authentication response.');

        // Store token
        MYeInvSetup.SetAccessToken(AccessToken, ExpiresIn);

        // Decode JWT and extract TIN
        ExtractTINFromToken(AccessToken, MYeInvSetup);

        // Mark as verified
        MYeInvSetup."TIN Verified" := true;
        MYeInvSetup."TIN Verification Date" := CurrentDateTime;
        MYeInvSetup.Modify(true);

        exit(true);
    end;

    local procedure ParseAuthResponse(ResponseText: Text; var AccessToken: Text; var ExpiresIn: Integer): Boolean
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        if not JsonObject.ReadFrom(ResponseText) then
            exit(false);

        if JsonObject.Get('access_token', JsonToken) then
            AccessToken := JsonToken.AsValue().AsText()
        else
            exit(false);

        if JsonObject.Get('expires_in', JsonToken) then
            ExpiresIn := JsonToken.AsValue().AsInteger()
        else
            ExpiresIn := 3600; // Default 1 hour

        exit(true);
    end;

    local procedure ExtractTINFromToken(AccessToken: Text; var MYeInvSetup: Record "MY eInv Setup")
    var
        PayloadJson: JsonObject;
        JsonToken: JsonToken;
        TIN: Text;
    begin
        // Decode JWT payload
        if not DecodeJWTPayload(AccessToken, PayloadJson) then
            exit;

        // Try common claim names for TIN
        if PayloadJson.Get('tin', JsonToken) then
            TIN := JsonToken.AsValue().AsText()
        else if PayloadJson.Get('Taxpayer TIN', JsonToken) then
            TIN := JsonToken.AsValue().AsText()
        else if PayloadJson.Get('tax_id', JsonToken) then
            TIN := JsonToken.AsValue().AsText()
        else if PayloadJson.Get('taxid', JsonToken) then
            TIN := JsonToken.AsValue().AsText()
        else if PayloadJson.Get('sub', JsonToken) then // subject claim
            TIN := JsonToken.AsValue().AsText();

        if TIN <> '' then begin
            MYeInvSetup."Authenticated TIN" := CopyStr(TIN, 1, 20);
            MYeInvSetup.Modify();
        end;
    end;

    local procedure DecodeJWTPayload(JWT: Text; var PayloadJson: JsonObject): Boolean
    var
        Parts: List of [Text];
        PayloadBase64: Text;
        PayloadText: Text;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        // JWT format: header.payload.signature
        Parts := JWT.Split('.');
        if Parts.Count <> 3 then
            exit(false);

        Parts.Get(2, PayloadBase64);

        // JWT uses Base64URL encoding, replace characters
        PayloadBase64 := PayloadBase64.Replace('-', '+');
        PayloadBase64 := PayloadBase64.Replace('_', '/');

        // Add padding if needed
        while (StrLen(PayloadBase64) mod 4) <> 0 do
            PayloadBase64 += '=';

        // Decode Base64
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(PayloadBase64, OutStr);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(PayloadText);

        // Parse JSON
        exit(PayloadJson.ReadFrom(PayloadText));
    end;

    procedure GetValidToken(var MYeInvSetup: Record "MY eInv Setup"): Text
    begin
        if not MYeInvSetup.Get() then
            Error('MY eInv Setup is not configured.');

        // Check if token is still valid
        if MYeInvSetup.IsTokenValid() then
            exit(MYeInvSetup.GetAccessToken());

        // Token expired or doesn't exist, get new one
        if not TestConnectionAndVerifyTIN(MYeInvSetup) then
            Error('Failed to authenticate with LHDN MyInvois.');

        exit(MYeInvSetup.GetAccessToken());
    end;
}
