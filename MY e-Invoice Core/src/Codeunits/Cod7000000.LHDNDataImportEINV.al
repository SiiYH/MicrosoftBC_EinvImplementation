namespace MYeInvoiceCore.MYeInvoiceCore;

codeunit 7000000 "LHDN Data Import EINV"
{
    TableNo = "e-Invoice Setup EINV";

    var
        ConfirmImportQst: Label 'This will download and import master data from LHDN SDK.\Do you want to continue?';
        ImportSuccessMsg: Label 'Import completed:\Lookup Codes: %1\Classification Codes: %2\MSIC Codes: %3\Total: %4 records';
        ImportErrorErr: Label 'Import failed: %1';
        DownloadingMsg: Label 'Downloading %1...';
        ParsingMsg: Label 'Parsing %1...';

    trigger OnRun()
    begin
        if not Confirm(ConfirmImportQst) then
            exit;

        ImportAllMasterData();
    end;

    /// <summary>
    /// Import all master data from LHDN SDK
    /// </summary>
    procedure ImportAllMasterData()
    var
        ProgressDialog: Dialog;
        LookupCount, ClassCount, MSICCount, TotalCount : Integer;
    begin
        ProgressDialog.Open('Importing LHDN Master Data...\#1####################');

        // 1. Import all lookup types (7 types in one go)
        ProgressDialog.Update(1, 'Importing Lookup Codes...');
        LookupCount := ImportAllLookupData();

        // 2. Import Classification Codes
        ProgressDialog.Update(1, 'Importing Classification Codes...');
        ClassCount := ImportClassificationCodes();

        // 3. Import MSIC Codes
        ProgressDialog.Update(1, 'Importing MSIC Codes...');
        MSICCount := ImportMSICCodes();

        ProgressDialog.Close();

        TotalCount := LookupCount + ClassCount + MSICCount;
        Message(ImportSuccessMsg, LookupCount, ClassCount, MSICCount, TotalCount);
    end;

    // =========================================================================
    // TABLE 1: LOOKUP CODES (7 types)
    // =========================================================================

    /// <summary>
    /// Import all lookup data types at once
    /// </summary>
    procedure ImportAllLookupData(): Integer
    var
        LookupType: Enum "LHDN Lookup Type EINV";
        TotalCount: Integer;
    begin
        foreach LookupType in "LHDN Lookup Type EINV".Ordinals() do
            TotalCount += ImportLookupData(LookupType);

        exit(TotalCount);
    end;

    /// <summary>
    /// Import specific lookup type
    /// </summary>
    procedure ImportLookupData(LookupType: Enum "LHDN Lookup Type EINV"): Integer
    var
        LookupCode: Record "LHDN Lookup Code EINV";
        HttpClient: Codeunit "Http Client EINV";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ResponseText: Text;
        URL: Text;
        ImportCount: Integer;
        Code, Description, DescriptionMS : Text;
    begin
        URL := GetLookupURL(LookupType);

        // Download JSON
        if not HttpClient.GetRequest(URL, ResponseText) then
            Error(ImportErrorErr, StrSubstNo('Failed to download %1', LookupType));

        // Parse JSON
        if not JsonArray.ReadFrom(ResponseText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        // Import records
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            Code := GetJsonValue(JsonObject, 'Code');
            Description := GetJsonValue(JsonObject, GetDescriptionFieldName(LookupType));
            DescriptionMS := GetJsonValue(JsonObject, 'DescriptionMS');

            if Code <> '' then begin
                // Insert or update
                if not LookupCode.Get(LookupType, Code) then begin
                    LookupCode.Init();
                    LookupCode."Lookup Type" := LookupType;
                    LookupCode.Code := CopyStr(Code, 1, MaxStrLen(LookupCode.Code));
                    LookupCode.Insert(true);
                end;

                LookupCode.Description := CopyStr(Description, 1, MaxStrLen(LookupCode.Description));
                if DescriptionMS <> '' then
                    LookupCode."Description (Malay)" := CopyStr(DescriptionMS, 1, MaxStrLen(LookupCode."Description (Malay)"));
                LookupCode."Is Active" := true;
                LookupCode.Modify(true);

                ImportCount += 1;
            end;
        end;

        exit(ImportCount);
    end;

    local procedure GetLookupURL(LookupType: Enum "LHDN Lookup Type EINV"): Text
    var
        BaseURL: Text;
    begin
        BaseURL := 'https://sdk.myinvois.hasil.gov.my/files/';

        case LookupType of
            LookupType::"Country Code":
                exit(BaseURL + 'CountryCodes.json');
            LookupType::"Currency Code":
                exit(BaseURL + 'CurrencyCodes.json');
            LookupType::"E-Invoice Type":
                exit(BaseURL + 'EInvoiceTypes.json');
            LookupType::"Payment Method":
                exit(BaseURL + 'PaymentMethods.json');
            LookupType::"State Code":
                exit(BaseURL + 'StateCodes.json');
            LookupType::"Tax Type":
                exit(BaseURL + 'TaxTypes.json');
            LookupType::"Unit Type":
                exit(BaseURL + 'UnitTypes.json');
        end;
    end;

    local procedure GetDescriptionFieldName(LookupType: Enum "LHDN Lookup Type EINV"): Text
    begin
        case LookupType of
            LookupType::"Unit Type":
                exit('Name'); // UnitTypes.json uses "Name" instead of "Description"
            else
                exit('Description');
        end;
    end;

    // =========================================================================
    // TABLE 2: CLASSIFICATION CODES
    // =========================================================================

    /// <summary>
    /// Import Classification Codes from JSON
    /// Source: https://sdk.myinvois.hasil.gov.my/files/ClassificationCodes.json
    /// </summary>
    procedure ImportClassificationCodes(): Integer
    var
        ClassificationCode: Record "LHDN Classification Code EINV";
        HttpClient: Codeunit "Http Client EINV";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ResponseText: Text;
        URL: Text;
        ImportCount: Integer;
    begin
        URL := 'https://sdk.myinvois.hasil.gov.my/files/ClassificationCodes.json';

        // Download JSON
        if not HttpClient.GetRequest(URL, ResponseText) then
            Error(ImportErrorErr, 'Failed to download classification codes');

        // Parse JSON
        if not JsonArray.ReadFrom(ResponseText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        // Import records
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            if ImportClassificationRecord(JsonObject) then
                ImportCount += 1;
        end;

        exit(ImportCount);
    end;

    local procedure ImportClassificationRecord(JsonObject: JsonObject): Boolean
    var
        ClassificationCode: Record "LHDN Classification Code EINV";
        Code, Description, DescriptionMS, Category : Text;
    begin
        // Extract values from JSON
        Code := GetJsonValue(JsonObject, 'Code');
        Description := GetJsonValue(JsonObject, 'Description');
        DescriptionMS := GetJsonValue(JsonObject, 'DescriptionMS');
        Category := GetJsonValue(JsonObject, 'Category');

        if Code = '' then
            exit(false);

        // Insert or update record
        if not ClassificationCode.Get(Code) then begin
            ClassificationCode.Init();
            ClassificationCode.Code := CopyStr(Code, 1, MaxStrLen(ClassificationCode.Code));
            ClassificationCode.Insert(true);
        end;

        ClassificationCode.Description := CopyStr(Description, 1, MaxStrLen(ClassificationCode.Description));
        ClassificationCode."Description (Malay)" := CopyStr(DescriptionMS, 1, MaxStrLen(ClassificationCode."Description (Malay)"));
        ClassificationCode.Category := ParseCategory(Category);
        ClassificationCode."Is Active" := true;
        ClassificationCode.Modify(true);

        exit(true);
    end;

    local procedure ParseCategory(CategoryText: Text): Enum "Classification Category EINV"
    var
        Category: Enum "Classification Category EINV";
    begin
        case CategoryText of
            'Goods':
                exit(Category::Goods);
            'Services':
                exit(Category::Services);
            'Capital Goods':
                exit(Category::"Capital Goods");
            'Medical Equipment':
                exit(Category::"Medical Equipment");
            else
                exit(Category::Others);
        end;
    end;

    // =========================================================================
    // TABLE 3: MSIC CODES
    // =========================================================================

    /// <summary>
    /// Import MSIC Codes from JSON
    /// Source: https://sdk.myinvois.hasil.gov.my/files/MSICCodes.json
    /// Source: https://sdk.myinvois.hasil.gov.my/files/MSICSubCategoryCodes.json
    /// </summary>
    procedure ImportMSICCodes(): Integer
    var
        MSICCode: Record "LHDN MSIC Code EINV";
        HttpClient: Codeunit "Http Client EINV";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ResponseText: Text;
        URL: Text;
        ImportCount: Integer;
        Code, Description, CategoryCode, CategoryDesc : Text;
    begin
        // Import main MSIC Codes
        URL := 'https://sdk.myinvois.hasil.gov.my/files/MSICCodes.json';

        if not HttpClient.GetRequest(URL, ResponseText) then
            Error(ImportErrorErr, 'Failed to download MSIC codes');

        if not JsonArray.ReadFrom(ResponseText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            Code := GetJsonValue(JsonObject, 'Code');
            Description := GetJsonValue(JsonObject, 'Description');

            if Code <> '' then begin
                if not MSICCode.Get(Code) then begin
                    MSICCode.Init();
                    MSICCode.Code := CopyStr(Code, 1, MaxStrLen(MSICCode.Code));
                    MSICCode.Insert(true);
                end;

                MSICCode.Description := CopyStr(Description, 1, MaxStrLen(MSICCode.Description));
                MSICCode."Is Active" := true;
                MSICCode.Modify(true);

                ImportCount += 1;
            end;
        end;

        // Import MSIC Subcategory Codes
        Clear(JsonArray);
        URL := 'https://sdk.myinvois.hasil.gov.my/files/MSICSubCategoryCodes.json';

        if HttpClient.GetRequest(URL, ResponseText) then begin
            if JsonArray.ReadFrom(ResponseText) then begin
                foreach JsonToken in JsonArray do begin
                    JsonObject := JsonToken.AsObject();

                    Code := GetJsonValue(JsonObject, 'Code');
                    Description := GetJsonValue(JsonObject, 'Description');
                    CategoryCode := GetJsonValue(JsonObject, 'CategoryCode');
                    CategoryDesc := GetJsonValue(JsonObject, 'CategoryDescription');

                    if Code <> '' then begin
                        if not MSICCode.Get(Code) then begin
                            MSICCode.Init();
                            MSICCode.Code := CopyStr(Code, 1, MaxStrLen(MSICCode.Code));
                            MSICCode.Insert(true);
                        end;

                        MSICCode.Description := CopyStr(Description, 1, MaxStrLen(MSICCode.Description));
                        MSICCode."Category Code" := CopyStr(CategoryCode, 1, MaxStrLen(MSICCode."Category Code"));
                        MSICCode."Category Description" := CopyStr(CategoryDesc, 1, MaxStrLen(MSICCode."Category Description"));
                        MSICCode."Is Active" := true;
                        MSICCode.Modify(true);

                        ImportCount += 1;
                    end;
                end;
            end;
        end;

        exit(ImportCount);
    end;

    // =========================================================================
    // ALTERNATIVE: Import from Uploaded File
    // =========================================================================

    procedure ImportFromFile(var InStream: InStream; DataType: Text): Integer
    var
        ResponseText: Text;
        ImportCount: Integer;
    begin
        // Read file content
        InStream.ReadText(ResponseText);

        // Import based on type
        case UpperCase(DataType) of
            'CLASSIFICATION':
                ImportCount := ImportClassificationCodesFromText(ResponseText);
            'MSIC':
                ImportCount := ImportMSICCodesFromText(ResponseText);
            'COUNTRY':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"Country Code");
            'CURRENCY':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"Currency Code");
            'EINVOICETYPE':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"E-Invoice Type");
            'PAYMENT':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"Payment Method");
            'STATE':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"State Code");
            'TAX':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"Tax Type");
            'UNIT':
                ImportCount := ImportLookupDataFromText(ResponseText, "LHDN Lookup Type EINV"::"Unit Type");
        end;

        Message('Import completed: %1 records imported', ImportCount);
        exit(ImportCount);
    end;

    local procedure ImportClassificationCodesFromText(JsonText: Text): Integer
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ImportCount: Integer;
    begin
        if not JsonArray.ReadFrom(JsonText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();
            if ImportClassificationRecord(JsonObject) then
                ImportCount += 1;
        end;

        exit(ImportCount);
    end;

    local procedure ImportMSICCodesFromText(JsonText: Text): Integer
    var
        MSICCode: Record "LHDN MSIC Code EINV";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ImportCount: Integer;
        Code, Description : Text;
    begin
        if not JsonArray.ReadFrom(JsonText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            Code := GetJsonValue(JsonObject, 'Code');
            Description := GetJsonValue(JsonObject, 'Description');

            if Code <> '' then begin
                if not MSICCode.Get(Code) then begin
                    MSICCode.Init();
                    MSICCode.Code := CopyStr(Code, 1, MaxStrLen(MSICCode.Code));
                    MSICCode.Insert(true);
                end;

                MSICCode.Description := CopyStr(Description, 1, MaxStrLen(MSICCode.Description));
                MSICCode.Modify(true);
                ImportCount += 1;
            end;
        end;

        exit(ImportCount);
    end;

    local procedure ImportLookupDataFromText(JsonText: Text; LookupType: Enum "LHDN Lookup Type EINV"): Integer
    var
        LookupCode: Record "LHDN Lookup Code EINV";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ImportCount: Integer;
        Code, Description, DescriptionMS : Text;
    begin
        if not JsonArray.ReadFrom(JsonText) then
            Error(ImportErrorErr, 'Invalid JSON format');

        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            Code := GetJsonValue(JsonObject, 'Code');
            Description := GetJsonValue(JsonObject, GetDescriptionFieldName(LookupType));
            DescriptionMS := GetJsonValue(JsonObject, 'DescriptionMS');

            if Code <> '' then begin
                if not LookupCode.Get(LookupType, Code) then begin
                    LookupCode.Init();
                    LookupCode."Lookup Type" := LookupType;
                    LookupCode.Code := CopyStr(Code, 1, MaxStrLen(LookupCode.Code));
                    LookupCode.Insert(true);
                end;

                LookupCode.Description := CopyStr(Description, 1, MaxStrLen(LookupCode.Description));
                if DescriptionMS <> '' then
                    LookupCode."Description (Malay)" := CopyStr(DescriptionMS, 1, MaxStrLen(LookupCode."Description (Malay)"));
                LookupCode."Is Active" := true;
                LookupCode.Modify(true);

                ImportCount += 1;
            end;
        end;

        exit(ImportCount);
    end;

    // =========================================================================
    // HELPER PROCEDURES
    // =========================================================================

    local procedure GetJsonValue(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(PropertyName, JsonToken) then
            if not JsonToken.AsValue().IsNull then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;
}