codeunit 70000000 "MY eInv LHDN Code Synch"
{
    procedure SyncAllCodes()
    var
        Window: Dialog;
        CodeType: Enum "MY eInv LHDN Code Type";
        CurrentStep: Integer;
        TotalSteps: Integer;
    begin
        TotalSteps := 9;
        Window.Open('Synchronizing LHDN Codes...\\' +
                   'Progress: #1######## of #2########\' +
                   'Current Type: #3################');

        CurrentStep := 1;
        Window.Update(1, CurrentStep);
        Window.Update(2, TotalSteps);

        Window.Update(3, 'State Codes');
        SyncCodeType("MY eInv LHDN Code Type"::State);
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Country Codes');
        SyncCodeType("MY eInv LHDN Code Type"::Country);
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Currency Codes');
        SyncCodeType("MY eInv LHDN Code Type"::Currency);
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'E-Invoice Types');
        SyncCodeType("MY eInv LHDN Code Type"::"E-Invoice Type");
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'MSIC Codes');
        SyncCodeType("MY eInv LHDN Code Type"::MSIC);
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Payment Modes');
        SyncCodeType("MY eInv LHDN Code Type"::"Payment Mode");
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Tax Types');
        SyncCodeType("MY eInv LHDN Code Type"::"Tax Type");
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Unit Types');
        SyncCodeType("MY eInv LHDN Code Type"::"Unit of Measurement");
        CurrentStep += 1;
        Window.Update(1, CurrentStep);

        Window.Update(3, 'Classification Codes');
        SyncCodeType("MY eInv LHDN Code Type"::Classification);

        Window.Close();
        Message('All codes synchronized successfully from MyInvois SDK.');
    end;

    procedure SyncCodeType(CodeType: Enum "MY eInv LHDN Code Type")
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        Url: Text;
        RecordsImported: Integer;
    begin
        // Get URL based on code type
        Url := GetSDKUrl(CodeType);

        if Url = '' then
            Error('URL not configured for code type: %1', CodeType);

        // Download JSON from SDK
        if not HttpClient.Get(Url, HttpResponse) then
            Error('Failed to download data from MyInvois SDK for %1.', CodeType);

        if not HttpResponse.IsSuccessStatusCode then
            Error('HTTP Error %1 when downloading %2', HttpResponse.HttpStatusCode, CodeType);

        HttpResponse.Content.ReadAs(ResponseText);

        // Parse and import data based on code type
        RecordsImported := ImportJsonData(CodeType, ResponseText);

        Message('%1 synchronized: %2 codes imported.', CodeType, RecordsImported);
    end;

    local procedure GetSDKUrl(CodeType: Enum "MY eInv LHDN Code Type"): Text
    var
        BaseUrl: Label 'https://sdk.myinvois.hasil.gov.my/files/', Locked = true;
    begin
        case CodeType of
            CodeType::State:
                exit(BaseUrl + 'StateCodes.json');
            CodeType::Country:
                exit(BaseUrl + 'CountryCodes.json');
            CodeType::Currency:
                exit(BaseUrl + 'CurrencyCodes.json');
            CodeType::"E-Invoice Type":
                exit(BaseUrl + 'EInvoiceTypes.json');
            CodeType::MSIC:
                exit(BaseUrl + 'MSICSubCategoryCodes.json');
            CodeType::"Payment Mode":
                exit(BaseUrl + 'PaymentMethods.json');
            CodeType::"Tax Type":
                exit(BaseUrl + 'TaxTypes.json');
            CodeType::"Unit of Measurement":
                exit(BaseUrl + 'UnitTypes.json');
            CodeType::Classification:
                exit(BaseUrl + 'ClassificationCodes.json');
        end;
    end;

    local procedure ImportJsonData(CodeType: Enum "MY eInv LHDN Code Type"; JsonText: Text): Integer
    var
        LHDNCode: Record "MY eInv LHDN Code";
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        i: Integer;
        RecordCount: Integer;
    begin
        // Delete existing codes of this type
        LHDNCode.SetRange("Code Type", CodeType);
        LHDNCode.DeleteAll();

        RecordCount := 0;

        // Try to parse as array first (most common structure)
        if JsonArray.ReadFrom(JsonText) then begin
            for i := 0 to JsonArray.Count - 1 do begin
                JsonArray.Get(i, JsonToken);
                if JsonToken.IsObject then begin
                    InsertCodeFromJson(CodeType, JsonToken.AsObject());
                    RecordCount += 1;
                end;
            end;
        end
        // Try to parse as object with array property
        else
            if JsonObject.ReadFrom(JsonText) then begin
                // Try common property names
                if TryGetArrayFromObject(JsonObject, 'data', JsonArray) or
                   TryGetArrayFromObject(JsonObject, 'codes', JsonArray) or
                   TryGetArrayFromObject(JsonObject, 'items', JsonArray) or
                   TryGetArrayFromObject(JsonObject, 'result', JsonArray)
                then begin
                    for i := 0 to JsonArray.Count - 1 do begin
                        JsonArray.Get(i, JsonToken);
                        if JsonToken.IsObject then begin
                            InsertCodeFromJson(CodeType, JsonToken.AsObject());
                            RecordCount += 1;
                        end;
                    end;
                end else
                    Error('Could not find array data in JSON response for %1', CodeType);
            end else
                Error('Invalid JSON format for %1', CodeType);

        exit(RecordCount);
    end;

    local procedure TryGetArrayFromObject(JsonObj: JsonObject; PropertyName: Text; var JsonArray: JsonArray): Boolean
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsArray then begin
                JsonArray := JsonToken.AsArray();
                exit(true);
            end;
        exit(false);
    end;

    local procedure InsertCodeFromJson(CodeType: Enum "MY eInv LHDN Code Type"; JsonObj: JsonObject)
    var
        LHDNCode: Record "MY eInv LHDN Code";
        JsonToken: JsonToken;
        Code: Text;
        Description: Text;
        DescriptionMalay: Text;
        TaxRate: Decimal;
        ParentCode: Text;
    begin
        // Extract Code field - different field names per JSON type
        case CodeType of
            CodeType::Classification,
            CodeType::Country,
            CodeType::Currency,
            CodeType::MSIC,
            CodeType::"Payment Mode",
            CodeType::State,
            CodeType::"Tax Type",
            CodeType::"E-Invoice Type",
            CodeType::"Unit of Measurement":
                Code := GetJsonValue(JsonObj, 'Code'); // All use 'Code'
        end;

        // Extract Description field - different field names per JSON type
        case CodeType of
            CodeType::Classification,
            CodeType::"E-Invoice Type",
            CodeType::MSIC,
            CodeType::"Tax Type":
                Description := GetJsonValue(JsonObj, 'Description');
            CodeType::"Payment Mode":
                Description := GetJsonValue(JsonObj, 'Payment Method');
            CodeType::Country:
                Description := GetJsonValue(JsonObj, 'Country');
            CodeType::Currency:
                Description := GetJsonValue(JsonObj, 'Currency');
            CodeType::State:
                Description := GetJsonValue(JsonObj, 'State');
            CodeType::"Unit of Measurement":
                Description := GetJsonValue(JsonObj, 'Name');
        end;

        // Extract Malay description (if available)
        // Note: Check actual JSON files - this field may not exist in all files
        DescriptionMalay := GetJsonValue(JsonObj, 'DescriptionMs');
        if DescriptionMalay = '' then
            DescriptionMalay := GetJsonValue(JsonObj, 'description_ms');

        // Parent code for MSIC (hierarchical structure)
        if CodeType = CodeType::MSIC then
            ParentCode := GetJsonValue(JsonObj, 'MSIC Category Reference');

        // Tax rate (for tax types only - check if this field exists)
        /* if CodeType = CodeType::"Tax Type" then begin
            if GetJsonDecimal(JsonObj, 'Rate', TaxRate) or
               GetJsonDecimal(JsonObj, 'TaxRate', TaxRate)
            then;
        end; */

        if Code = '' then
            exit; // Skip if no code found

        // Insert record
        LHDNCode.Init();
        LHDNCode."Code Type" := CodeType;
        LHDNCode."Code" := CopyStr(Code, 1, MaxStrLen(LHDNCode."Code"));
        LHDNCode.Description := CopyStr(Description, 1, MaxStrLen(LHDNCode.Description));
        if DescriptionMalay <> '' then
            LHDNCode."Description (Malay)" := CopyStr(DescriptionMalay, 1, MaxStrLen(LHDNCode."Description (Malay)"));
        if CodeType = CodeType::"Tax Type" then
            LHDNCode."Tax Rate %" := TaxRate;
        if ParentCode <> '' then
            LHDNCode."Parent Code" := CopyStr(ParentCode, 1, MaxStrLen(LHDNCode."Parent Code"));
        LHDNCode.Active := true;
        LHDNCode."Last Updated" := CurrentDateTime;
        LHDNCode.Source := 'MyInvois SDK';
        if LHDNCode.Insert(true) then;
    end;

    local procedure GetJsonValue(JsonObj: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsValue then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonValue(JsonObj: JsonObject; PropertyName1: Text; PropertyName2: Text; PropertyName3: Text; PropertyName4: Text): Text
    var
        JsonToken: JsonToken;
        PropertyNames: List of [Text];
        PropName: Text;
    begin
        PropertyNames.Add(PropertyName1);
        PropertyNames.Add(PropertyName2);
        PropertyNames.Add(PropertyName3);
        PropertyNames.Add(PropertyName4);

        foreach PropName in PropertyNames do begin
            if PropName <> '' then
                if JsonObj.Get(PropName, JsonToken) then
                    if JsonToken.IsValue then
                        exit(JsonToken.AsValue().AsText());
        end;
        exit('');
    end;

    local procedure GetJsonValue(JsonObj: JsonObject; PropertyName1: Text; PropertyName2: Text; PropertyName3: Text; PropertyName4: Text; PropertyName5: Text; PropertyName6: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName1, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        if JsonObj.Get(PropertyName2, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        if JsonObj.Get(PropertyName3, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        if JsonObj.Get(PropertyName4, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        if JsonObj.Get(PropertyName5, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        if JsonObj.Get(PropertyName6, JsonToken) then if JsonToken.IsValue then exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonDecimal(JsonObj: JsonObject; PropertyName: Text; var DecValue: Decimal): Boolean
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsValue then begin
                DecValue := JsonToken.AsValue().AsDecimal();
                exit(true);
            end;
        exit(false);
    end;

    procedure UpdateAllStateCodesFromPostCode()
    var
        PostCode: Record "Post Code";
        ConfirmMsg: Label 'This will update MY eInv State Code for all customers based on their Post Code.\\Existing state codes will be overwritten.\\Do you want to continue?';
        UpdatedCount: Integer;
        SkippedCount: Integer;
        SuccessMsg: Label 'Update completed:\\- %1 post code(s) updated\\- %2 post code(s) skipped (no matching state code found)';
    begin
        // Confirm with default = false (No button is default)
        if not Dialog.Confirm(ConfirmMsg, false) then
            exit;

        PostCode.SetRange(PostCode."Country/Region Code", 'MY');
        if PostCode.FindSet(true) then begin
            repeat
                PostCode."MY eInv State Code" := PostCode.GetStateCodeFromPostCode(PostCode."Code");
                if PostCode."MY eInv State Code" <> '' then begin
                    PostCode.Modify(true);
                    UpdatedCount += 1;
                end else
                    SkippedCount += 1;
            until PostCode.Next() = 0;
        end;

        Message(SuccessMsg, UpdatedCount, SkippedCount);
    end;


    procedure InitializeAllCountries()
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.FindSet(true) then
            repeat
                InitializeCountryISOCode(CountryRegion);
            until CountryRegion.Next() = 0;
    end;

    local procedure InitializeCountryISOCode(var CountryRegion: Record "Country/Region")
    var
        ISOCode: Code[3];
    begin
        // Skip if already populated
        if CountryRegion."MY eInv ISO Code" <> '' then
            exit;

        // Try to use existing ISO Code first
        if CountryRegion."ISO Code" <> '' then begin
            if ValidateISOCodeExists(CountryRegion."ISO Code") then begin
                CountryRegion."MY eInv ISO Code" := CountryRegion."ISO Code";
                CountryRegion.Modify(true);
                exit;
            end;
        end;

        // Try to find by country name
        ISOCode := FindISOCodeByName(CountryRegion.Name);
        if ISOCode <> '' then begin
            CountryRegion."MY eInv ISO Code" := ISOCode;
            CountryRegion.Modify(true);
        end;
    end;

    local procedure ValidateISOCodeExists(ISOCode: Code[3]): Boolean
    var
        MYeInvCodeTable: Record "MY eInv LHDN Code"; // Replace with your actual table name
    begin
        MYeInvCodeTable.SetRange("Code Type", Enum::"MY eInv LHDN Code Type"::Country);
        MYeInvCodeTable.SetRange(Code, ISOCode);
        MYeInvCodeTable.SetRange(Active, true);
        exit(MYeInvCodeTable.FindFirst());
    end;

    local procedure FindISOCodeByName(CountryName: Text[50]): Code[3]
    var
        MYeInvCodeTable: Record "MY eInv LHDN Code"; // Replace with your actual table name
    begin
        MYeInvCodeTable.SetRange("Code Type", Enum::"MY eInv LHDN Code Type"::Country);
        MYeInvCodeTable.SetRange(Active, true);

        // Try exact match first
        MYeInvCodeTable.SetFilter(Description, '@' + CountryName);
        if MYeInvCodeTable.FindFirst() then
            exit(MYeInvCodeTable.Code);

        // Try partial match
        MYeInvCodeTable.SetFilter(Description, '@*' + CountryName + '*');
        if MYeInvCodeTable.FindFirst() then
            exit(MYeInvCodeTable.Code);

        exit('');
    end;

    procedure InitializeSingleCountry(var CountryRegion: Record "Country/Region")
    begin
        InitializeCountryISOCode(CountryRegion);
    end;
}
