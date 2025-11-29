codeunit 70000013 "MY eInv XML Generator 02"
{
    // ═════════════════════════════════════════════════════════════════
    // MY eInv XML Generator - UBL 2.1 Invoice Generation (FIXED)
    // Matches sample XML structure with all required fields
    // ═════════════════════════════════════════════════════════════════
    procedure GenerateDocumentXML(DocumentVariant: Variant; DocumentType: Text): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case DocumentType of
            'Invoice':
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    exit(GenerateInvoiceXML(SalesInvoiceHeader));
                end;
            'CreditMemo':
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    exit(GenerateCreditMemoXML(SalesCrMemoHeader));
                end;
            else
                Error('Unsupported document type: %1', DocumentType);
        end;
    end;

    procedure GenerateInvoiceXML(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        XMLDoc: XmlDocument;
        RootElement: XmlElement;
        Result: Text;
        XMLDeclaration: Text;
    begin
        RootElement := CreateInvoiceRootElement();
        BuildInvoiceStructure(RootElement, SalesInvoiceHeader);
        XMLDoc.Add(RootElement);
        XMLDoc.WriteTo(Result);

        // Remove existing XML declaration if present
        if Result.StartsWith('<?xml') then begin
            Result := Result.Substring(Result.IndexOf('?>') + 2);
            Result := Result.TrimStart();
        end;

        // Add custom XML declaration
        XMLDeclaration := '<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
        Result := XMLDeclaration + Result;

        exit(Result);
    end;

    procedure GenerateCreditMemoXML(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        XMLDoc: XmlDocument;
        RootElement: XmlElement;
        Result: Text;
    begin
        RootElement := CreateCreditNoteRootElement();
        BuildCreditMemoStructure(RootElement, SalesCrMemoHeader);
        XMLDoc.Add(RootElement);
        XMLDoc.WriteTo(Result);

        if not Result.StartsWith('<?xml') then
            Result := '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' + Result;

        exit(Result);
    end;

    local procedure BuildInvoiceStructure(var RootElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        // Basic invoice information
        AddElement(RootElement, 'cbc:ID', SalesInvoiceHeader."No.");
        AddElement(RootElement, 'cbc:IssueDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(RootElement, 'cbc:IssueTime', Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));

        // Invoice type code with version attribute
        AddElementWithAttribute(RootElement, 'cbc:InvoiceTypeCode', '01', 'listVersionID', '1.0');

        AddDocumentCurrencyCode(RootElement, SalesInvoiceHeader."Currency Code");
        // AddElement(RootElement, 'cbc:TaxCurrencyCode', GetCurrencyCode(SalesInvoiceHeader."Currency Code"));
        AddElement(RootElement, 'cbc:TaxCurrencyCode', GetLHDNTaxCode());

        // Billing reference
        AddBillingReference(RootElement, SalesInvoiceHeader."Order No.");

        // Parties with complete information
        AddSupplierPartyFromInvoice(RootElement, SalesInvoiceHeader);
        AddCustomerPartyFromInvoice(RootElement, SalesInvoiceHeader);

        // Delivery with shipment details
        AddDeliveryFromInvoice(RootElement, SalesInvoiceHeader);

        // Payment means and terms
        AddPaymentMeans(RootElement);
        AddPaymentTerms(RootElement, SalesInvoiceHeader);

        // Tax exchange rate
        AddTaxExchangeRate(RootElement, SalesInvoiceHeader);

        // Tax totals
        AddTaxTotalFromInvoice(RootElement, SalesInvoiceHeader);

        // Monetary totals
        AddLegalMonetaryTotalFromInvoice(RootElement, SalesInvoiceHeader);

        // Invoice lines
        AddInvoiceLines(RootElement, SalesInvoiceHeader);
    end;

    local procedure BuildCreditMemoStructure(var RootElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        AddElement(RootElement, 'cbc:ID', SalesCrMemoHeader."No.");
        AddElement(RootElement, 'cbc:IssueDate', Format(SalesCrMemoHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(RootElement, 'cbc:IssueTime', Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));
        AddElementWithAttribute(RootElement, 'cbc:CreditNoteTypeCode', '02', 'listVersionID', '1.0');
        AddDocumentCurrencyCode(RootElement, SalesCrMemoHeader."Currency Code");
        AddElement(RootElement, 'cbc:TaxCurrencyCode', GetCurrencyCode(SalesCrMemoHeader."Currency Code"));

        if SalesCrMemoHeader."Applies-to Doc. No." <> '' then
            AddBillingReference(RootElement, SalesCrMemoHeader."Applies-to Doc. No.");

        AddSupplierPartyFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddCustomerPartyFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddDeliveryFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddPaymentMeans(RootElement);
        AddPaymentTerms(RootElement, SalesCrMemoHeader);
        AddTaxExchangeRateCrMemo(RootElement, SalesCrMemoHeader);
        AddTaxTotalFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddLegalMonetaryTotalFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddCreditMemoLines(RootElement, SalesCrMemoHeader);
    end;

    local procedure CreateInvoiceRootElement(): XmlElement
    var
        RootElement: XmlElement;
    begin
        RootElement := XmlElement.Create('Invoice', 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'));
        exit(RootElement);
    end;

    local procedure CreateCreditNoteRootElement(): XmlElement
    var
        RootElement: XmlElement;
    begin
        RootElement := XmlElement.Create('CreditNote', 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'));
        exit(RootElement);
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            exit(GeneralLedgerSetup."LCY Code");
        end;
        exit(CurrencyCode);
    end;

    local procedure AddDocumentCurrencyCode(var ParentElement: XmlElement; CurrencyCode: Code[10])
    begin
        AddElement(ParentElement, 'cbc:DocumentCurrencyCode', GetCurrencyCode(CurrencyCode));
    end;

    local procedure AddBillingReference(var ParentElement: XmlElement; ReferenceNo: Code[20])
    var
        BillingRefElement: XmlElement;
        AdditionalDocRefElement: XmlElement;
        RefValue: Text;
    begin
        RefValue := ReferenceNo;
        if RefValue = '' then
            RefValue := 'ANALYTICS';

        BillingRefElement := XmlElement.Create('BillingReference', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AdditionalDocRefElement := XmlElement.Create('AdditionalDocumentReference', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(AdditionalDocRefElement, 'cbc:ID', RefValue);
        BillingRefElement.Add(AdditionalDocRefElement);
        ParentElement.Add(BillingRefElement);
    end;

    local procedure AddSupplierPartyFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        AddSupplierParty(ParentElement, CompanyInfo);
    end;

    local procedure AddSupplierPartyFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        AddSupplierParty(ParentElement, CompanyInfo);
    end;

    local procedure AddSupplierParty(var ParentElement: XmlElement; CompanyInfo: Record "Company Information")
    var
        PostCode: Record "Post Code";
        SupplierElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
        ContactElement: XmlElement;
        StateCode: Text;
    begin
        SupplierElement := XmlElement.Create('AccountingSupplierParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Industry classification
        AddElementWithAttribute(PartyElement, 'cbc:IndustryClassificationCode', '00000', 'name', 'NOT APPLICABLE');

        // Party identifications
        AddPartyIdentification(PartyElement, GetTINNumber(CompanyInfo), 'TIN');
        AddPartyIdentification(PartyElement, CompanyInfo."Registration No.", 'BRN');
        AddPartyIdentification(PartyElement, GetSSTNumber(CompanyInfo), 'SST');

        // Postal address
        PostalElement := XmlElement.Create('PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        if CompanyInfo.City <> '' then
            AddElement(PostalElement, 'cbc:CityName', CompanyInfo.City);
        if CompanyInfo."Post Code" <> '' then
            AddElement(PostalElement, 'cbc:PostalZone', CompanyInfo."Post Code");

        StateCode := PostCode.GetStateCodeFromPostCode(CompanyInfo."Post Code");
        if StateCode <> '' then
            AddElement(PostalElement, 'cbc:CountrySubentityCode', StateCode);

        AddAddressLine(PostalElement, CompanyInfo.Address);
        AddAddressLine(PostalElement, CompanyInfo."Address 2");
        AddCountry(PostalElement, CompanyInfo."Country/Region Code");
        PartyElement.Add(PostalElement);

        // Legal entity
        LegalElement := XmlElement.Create('PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', CompanyInfo.Name);
        PartyElement.Add(LegalElement);

        // Contact information
        ContactElement := XmlElement.Create('Contact', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ContactElement, 'cbc:Telephone', CompanyInfo."Phone No.");
        AddElement(ContactElement, 'cbc:ElectronicMail', CompanyInfo."E-Mail");
        PartyElement.Add(ContactElement);

        SupplierElement.Add(PartyElement);
        ParentElement.Add(SupplierElement);
    end;

    local procedure AddCustomerPartyFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        AddCustomerParty(ParentElement, Customer, SalesInvoiceHeader."Bill-to Address",
            SalesInvoiceHeader."Bill-to Address 2", SalesInvoiceHeader."Bill-to Country/Region Code",
            SalesInvoiceHeader."Bill-to Name");
    end;

    local procedure AddCustomerPartyFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        AddCustomerParty(ParentElement, Customer, SalesCrMemoHeader."Bill-to Address",
            SalesCrMemoHeader."Bill-to Address 2", SalesCrMemoHeader."Bill-to Country/Region Code",
            SalesCrMemoHeader."Bill-to Name");
    end;

    local procedure AddCustomerParty(var ParentElement: XmlElement; Customer: Record Customer; Address: Text[100]; Address2: Text[50]; CountryCode: Code[10]; Name: Text[100])
    var
        CustomerElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
        ContactElement: XmlElement;
        StateCode: Text;
    begin
        CustomerElement := XmlElement.Create('AccountingCustomerParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Party identifications
        AddPartyIdentification(PartyElement, GetTINNumber(Customer), 'TIN');
        AddPartyIdentification(PartyElement, GetBRNNumber(Customer), 'BRN');
        AddPartyIdentification(PartyElement, GetSSTNumber(Customer), 'SST');

        // Postal address
        PostalElement := XmlElement.Create('PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        if Customer.City <> '' then
            AddElement(PostalElement, 'cbc:CityName', Customer.City);
        if Customer."Post Code" <> '' then
            AddElement(PostalElement, 'cbc:PostalZone', Customer."Post Code");

        AddAddressLine(PostalElement, Address);
        AddCountry(PostalElement, CountryCode);
        PartyElement.Add(PostalElement);

        // Legal entity
        LegalElement := XmlElement.Create('PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', Name);
        PartyElement.Add(LegalElement);

        // Contact information
        ContactElement := XmlElement.Create('Contact', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ContactElement, 'cbc:Telephone', Customer."Phone No.");
        AddElement(ContactElement, 'cbc:ElectronicMail', Customer."E-Mail");
        PartyElement.Add(ContactElement);

        CustomerElement.Add(PartyElement);
        ParentElement.Add(CustomerElement);
    end;

    local procedure AddDeliveryFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        DeliveryElement: XmlElement;
        DeliveryPartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
        ShipmentElement: XmlElement;
        FreightElement: XmlElement;
        CurrencyCode: Code[10];
    begin
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CurrencyCode := GetCurrencyCode(SalesInvoiceHeader."Currency Code");

        DeliveryElement := XmlElement.Create('Delivery', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Delivery party
        DeliveryPartyElement := XmlElement.Create('DeliveryParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        PostalElement := XmlElement.Create('PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', SalesInvoiceHeader."Ship-to City");
        AddElement(PostalElement, 'cbc:PostalZone', SalesInvoiceHeader."Ship-to Post Code");
        AddAddressLine(PostalElement, SalesInvoiceHeader."Ship-to Address");
        AddAddressLine(PostalElement, SalesInvoiceHeader."Ship-to Address 2");
        AddCountry(PostalElement, SalesInvoiceHeader."Ship-to Country/Region Code");
        DeliveryPartyElement.Add(PostalElement);

        LegalElement := XmlElement.Create('PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', SalesInvoiceHeader."Ship-to Name");
        DeliveryPartyElement.Add(LegalElement);

        DeliveryElement.Add(DeliveryPartyElement);

        // Shipment
        ShipmentElement := XmlElement.Create('Shipment', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ShipmentElement, 'cbc:ID', SalesInvoiceHeader."No.");

        FreightElement := XmlElement.Create('FreightAllowanceCharge', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(FreightElement, 'cbc:ChargeIndicator', 'true');
        AddElement(FreightElement, 'cbc:AllowanceChargeReason', 'Other Charge');
        AddAmountElement(FreightElement, 'cbc:Amount', 0.00, CurrencyCode);
        ShipmentElement.Add(FreightElement);

        DeliveryElement.Add(ShipmentElement);
        ParentElement.Add(DeliveryElement);
    end;

    local procedure AddDeliveryFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        DeliveryElement: XmlElement;
        DeliveryPartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
        ShipmentElement: XmlElement;
        FreightElement: XmlElement;
        CurrencyCode: Code[10];
    begin
        CurrencyCode := GetCurrencyCode(SalesCrMemoHeader."Currency Code");

        DeliveryElement := XmlElement.Create('Delivery', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        DeliveryPartyElement := XmlElement.Create('DeliveryParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        PostalElement := XmlElement.Create('PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', SalesCrMemoHeader."Ship-to City");
        AddElement(PostalElement, 'cbc:PostalZone', SalesCrMemoHeader."Ship-to Post Code");
        AddAddressLine(PostalElement, SalesCrMemoHeader."Ship-to Address");
        AddAddressLine(PostalElement, SalesCrMemoHeader."Ship-to Address 2");
        AddCountry(PostalElement, SalesCrMemoHeader."Ship-to Country/Region Code");
        DeliveryPartyElement.Add(PostalElement);

        LegalElement := XmlElement.Create('PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', SalesCrMemoHeader."Ship-to Name");
        DeliveryPartyElement.Add(LegalElement);

        DeliveryElement.Add(DeliveryPartyElement);

        ShipmentElement := XmlElement.Create('Shipment', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ShipmentElement, 'cbc:ID', SalesCrMemoHeader."No.");

        FreightElement := XmlElement.Create('FreightAllowanceCharge', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(FreightElement, 'cbc:ChargeIndicator', 'true');
        AddElement(FreightElement, 'cbc:AllowanceChargeReason', 'Other Charge');
        AddAmountElement(FreightElement, 'cbc:Amount', 0.00, CurrencyCode);
        ShipmentElement.Add(FreightElement);

        DeliveryElement.Add(ShipmentElement);
        ParentElement.Add(DeliveryElement);
    end;

    local procedure AddPaymentMeans(var ParentElement: XmlElement)
    var
        PaymentElement: XmlElement;
        FinancialAccountElement: XmlElement;
    begin
        PaymentElement := XmlElement.Create('PaymentMeans', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PaymentElement, 'cbc:PaymentMeansCode', '08');

        FinancialAccountElement := XmlElement.Create('PayeeFinancialAccount', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(FinancialAccountElement, 'cbc:ID', '99-99-888');
        PaymentElement.Add(FinancialAccountElement);

        ParentElement.Add(PaymentElement);
    end;

    local procedure AddPaymentTerms(var ParentElement: XmlElement; DocumentVariant: Variant)
    var
        PaymentTermsElement: XmlElement;
    begin
        PaymentTermsElement := XmlElement.Create('PaymentTerms', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PaymentTermsElement, 'cbc:Note', 'Current Month');
        ParentElement.Add(PaymentTermsElement);
    end;

    local procedure AddTaxExchangeRate(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ExchangeRateElement: XmlElement;
    begin
        ExchangeRateElement := XmlElement.Create('TaxExchangeRate', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ExchangeRateElement, 'cbc:SourceCurrencyCode', 'GBP');
        AddElement(ExchangeRateElement, 'cbc:TargetCurrencyCode', GetCurrencyCode(SalesInvoiceHeader."Currency Code"));
        AddElement(ExchangeRateElement, 'cbc:CalculationRate', '0.000000');
        ParentElement.Add(ExchangeRateElement);
    end;

    local procedure AddTaxExchangeRateCrMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ExchangeRateElement: XmlElement;
    begin
        ExchangeRateElement := XmlElement.Create('TaxExchangeRate', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ExchangeRateElement, 'cbc:SourceCurrencyCode', 'GBP');
        AddElement(ExchangeRateElement, 'cbc:TargetCurrencyCode', GetCurrencyCode(SalesCrMemoHeader."Currency Code"));
        AddElement(ExchangeRateElement, 'cbc:CalculationRate', '0.000000');
        ParentElement.Add(ExchangeRateElement);
    end;

    local procedure AddTaxTotalFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        TotalTaxAmount: Decimal;
        TaxableAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                TotalTaxAmount += SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
                TaxableAmount += SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        CurrencyCode := GetCurrencyCode(SalesInvoiceHeader."Currency Code");
        AddTaxTotal(ParentElement, TotalTaxAmount, TaxableAmount, CurrencyCode);
    end;

    local procedure AddTaxTotalFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TotalTaxAmount: Decimal;
        TaxableAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                TotalTaxAmount += SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
                TaxableAmount += SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;

        CurrencyCode := GetCurrencyCode(SalesCrMemoHeader."Currency Code");
        AddTaxTotal(ParentElement, TotalTaxAmount, TaxableAmount, CurrencyCode);
    end;

    local procedure AddTaxTotal(var ParentElement: XmlElement; TotalTaxAmount: Decimal; TaxableAmount: Decimal; CurrencyCode: Code[10])
    var
        TaxTotalElement: XmlElement;
        TaxSubtotalElement: XmlElement;
        TaxCategoryElement: XmlElement;
        TaxSchemeElement: XmlElement;
    begin
        TaxTotalElement := XmlElement.Create('TaxTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxTotalElement, 'cbc:TaxAmount', TotalTaxAmount, CurrencyCode);

        TaxSubtotalElement := XmlElement.Create('TaxSubtotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxableAmount', TaxableAmount, CurrencyCode);
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxAmount', TotalTaxAmount, CurrencyCode);

        TaxCategoryElement := XmlElement.Create('TaxCategory', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxCategoryElement, 'cbc:ID', '06');
        AddElement(TaxCategoryElement, 'cbc:Percent', Format(0.00, 0, '<Precision,2:2><Standard Format,0>'));

        TaxSchemeElement := XmlElement.Create('TaxScheme', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxSchemeElement, 'cbc:ID', 'OTH');
        TaxCategoryElement.Add(TaxSchemeElement);

        TaxSubtotalElement.Add(TaxCategoryElement);
        TaxTotalElement.Add(TaxSubtotalElement);
        ParentElement.Add(TaxTotalElement);
    end;

    local procedure AddLegalMonetaryTotalFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        LineExtensionAmount: Decimal;
        TaxExclusiveAmount: Decimal;
        TaxInclusiveAmount: Decimal;
        AllowanceTotalAmount: Decimal;
        PayableRoundingAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                LineExtensionAmount += SalesInvoiceLine.Amount;
                TaxExclusiveAmount += SalesInvoiceLine.Amount;
                TaxInclusiveAmount += SalesInvoiceLine."Amount Including VAT";
                AllowanceTotalAmount += SalesInvoiceLine."Line Discount Amount";
            until SalesInvoiceLine.Next() = 0;

        if SalesInvoiceHeader."Currency Code" = '' then
            CurrencyCode := GetLCYCode()
        else
            CurrencyCode := SalesInvoiceHeader."Currency Code";

        PayableRoundingAmount := 0; // Usually 0 unless you have rounding logic

        AddLegalMonetaryTotal(ParentElement, LineExtensionAmount, TaxExclusiveAmount,
                             TaxInclusiveAmount, AllowanceTotalAmount, PayableRoundingAmount,
                             TaxInclusiveAmount, CurrencyCode);
    end;

    local procedure AddLegalMonetaryTotalFromCreditMemo(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        LineExtensionAmount: Decimal;
        TaxExclusiveAmount: Decimal;
        TaxInclusiveAmount: Decimal;
        AllowanceTotalAmount: Decimal;
        PayableRoundingAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                LineExtensionAmount += SalesInvoiceLine.Amount;
                TaxExclusiveAmount += SalesInvoiceLine.Amount;
                TaxInclusiveAmount += SalesInvoiceLine."Amount Including VAT";
                AllowanceTotalAmount += SalesInvoiceLine."Line Discount Amount";
            until SalesInvoiceLine.Next() = 0;

        if SalesInvoiceHeader."Currency Code" = '' then
            CurrencyCode := GetLCYCode()
        else
            CurrencyCode := SalesInvoiceHeader."Currency Code";

        PayableRoundingAmount := 0; // Usually 0 unless you have rounding logic

        AddLegalMonetaryTotal(ParentElement, LineExtensionAmount, TaxExclusiveAmount,
                             TaxInclusiveAmount, AllowanceTotalAmount, PayableRoundingAmount,
                             TaxInclusiveAmount, CurrencyCode);
    end;

    local procedure AddLegalMonetaryTotal(var ParentElement: XmlElement; LineExtensionAmount: Decimal; TaxExclusiveAmount: Decimal; TaxInclusiveAmount: Decimal; AllowanceTotalAmount: Decimal; PayableRoundingAmount: Decimal; PayableAmount: Decimal; CurrencyCode: Code[10])
    var
        MonetaryElement: XmlElement;
    begin
        MonetaryElement := XmlElement.Create('LegalMonetaryTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        AddAmountElement(MonetaryElement, 'cbc:LineExtensionAmount', LineExtensionAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:TaxExclusiveAmount', TaxExclusiveAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:TaxInclusiveAmount', TaxInclusiveAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:AllowanceTotalAmount', AllowanceTotalAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:PayableRoundingAmount', PayableRoundingAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:PayableAmount', PayableAmount, CurrencyCode);

        ParentElement.Add(MonetaryElement);
    end;

    local procedure AddInvoiceLines(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CurrencyCode: Code[10];
    begin
        if SalesInvoiceHeader."Currency Code" = '' then
            CurrencyCode := GetLCYCode()
        else
            CurrencyCode := SalesInvoiceHeader."Currency Code";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        if SalesInvoiceLine.FindSet() then
            repeat
                AddInvoiceLine(ParentElement, SalesInvoiceLine, CurrencyCode);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure AddCreditMemoLines(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CurrencyCode: Code[10];
    begin
        if SalesInvoiceHeader."Currency Code" = '' then
            CurrencyCode := GetLCYCode()
        else
            CurrencyCode := SalesInvoiceHeader."Currency Code";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        if SalesInvoiceLine.FindSet() then
            repeat
                AddInvoiceLine(ParentElement, SalesInvoiceLine, CurrencyCode);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure AddInvoiceLine(var ParentElement: XmlElement; SalesInvoiceLine: Record "Sales Invoice Line"; CurrencyCode: Code[10])
    var
        LineElement: XmlElement;
        AllowanceChargeElement: XmlElement;
        TaxTotalElement: XmlElement;
        TaxSubtotalElement: XmlElement;
        TaxCategoryElement: XmlElement;
        TaxSchemeElement: XmlElement;
        ItemElement: XmlElement;
        CommodityElement: XmlElement;
        PriceElement: XmlElement;
        ItemPriceExtElement: XmlElement;
        TaxAmount: Decimal;
        DiscountAmount: Decimal;
        DiscountPercent: Decimal;
    begin
        LineElement := XmlElement.Create('InvoiceLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Line ID
        AddElement(LineElement, 'cbc:ID', Format(SalesInvoiceLine."Line No."));

        // Invoiced Quantity
        AddQuantityElement(LineElement, 'cbc:InvoicedQuantity', SalesInvoiceLine.Quantity, SalesInvoiceLine."Unit of Measure Code");

        // Line Extension Amount
        AddAmountElement(LineElement, 'cbc:LineExtensionAmount', SalesInvoiceLine.Amount, CurrencyCode);

        // Allowance Charge (Discount)
        AllowanceChargeElement := XmlElement.Create('AllowanceCharge', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(AllowanceChargeElement, 'cbc:ChargeIndicator', 'false');
        AddElement(AllowanceChargeElement, 'cbc:AllowanceChargeReason', 'Line Discount Amount');

        // Calculate discount
        if SalesInvoiceLine."Line Discount %" <> 0 then begin
            DiscountPercent := SalesInvoiceLine."Line Discount %" / 100;
            DiscountAmount := SalesInvoiceLine."Line Discount Amount";
        end else begin
            DiscountPercent := 0;
            DiscountAmount := 0;
        end;

        AddElement(AllowanceChargeElement, 'cbc:MultiplierFactorNumeric', Format(DiscountPercent, 0, '<Precision,2:2><Standard Format,0>'));
        AddAmountElement(AllowanceChargeElement, 'cbc:Amount', DiscountAmount, CurrencyCode);
        LineElement.Add(AllowanceChargeElement);

        // Tax Total for Line
        TaxAmount := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;

        TaxTotalElement := XmlElement.Create('TaxTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxTotalElement, 'cbc:TaxAmount', TaxAmount, CurrencyCode);

        TaxSubtotalElement := XmlElement.Create('TaxSubtotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxableAmount', SalesInvoiceLine.Amount, CurrencyCode);
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxAmount', TaxAmount, CurrencyCode);

        TaxCategoryElement := XmlElement.Create('TaxCategory', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxCategoryElement, 'cbc:ID', '06'); // Tax category code

        if SalesInvoiceLine."VAT %" <> 0 then
            AddElement(TaxCategoryElement, 'cbc:Percent', Format(SalesInvoiceLine."VAT %", 0, '<Precision,2:2><Standard Format,0>'))
        else
            AddElement(TaxCategoryElement, 'cbc:Percent', '0.00');

        TaxSchemeElement := XmlElement.Create('TaxScheme', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElementWithTwoAttributes(TaxSchemeElement, 'cbc:ID', 'OTH', 'schemeID', 'UN/ECE 5153', 'schemeAgencyID', '6');
        TaxCategoryElement.Add(TaxSchemeElement);

        TaxSubtotalElement.Add(TaxCategoryElement);
        TaxTotalElement.Add(TaxSubtotalElement);
        LineElement.Add(TaxTotalElement);

        // Item
        ItemElement := XmlElement.Create('Item', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ItemElement, 'cbc:Description', SalesInvoiceLine.Description);

        // Commodity Classification
        CommodityElement := XmlElement.Create('CommodityClassification', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElementWithAttribute(CommodityElement, 'cbc:ItemClassificationCode', '022', 'listID', 'CLASS');
        ItemElement.Add(CommodityElement);

        LineElement.Add(ItemElement);

        // Price
        PriceElement := XmlElement.Create('Price', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(PriceElement, 'cbc:PriceAmount', SalesInvoiceLine."Unit Price", CurrencyCode);
        LineElement.Add(PriceElement);

        // Item Price Extension
        ItemPriceExtElement := XmlElement.Create('ItemPriceExtension', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(ItemPriceExtElement, 'cbc:Amount', SalesInvoiceLine.Amount, CurrencyCode);
        LineElement.Add(ItemPriceExtElement);

        ParentElement.Add(LineElement);
    end;

    local procedure AddElementWithTwoAttributes(var ParentElement: XmlElement; ElementName: Text; ElementValue: Text; Attr1Name: Text; Attr1Value: Text; Attr2Name: Text; Attr2Value: Text)
    var
        NewElement: XmlElement;
        Attribute1: XmlAttribute;
        Attribute2: XmlAttribute;
        Prefix: Text;
        LocalName: Text;
        NamespaceUri: Text;
        ColonPos: Integer;
    begin
        ColonPos := StrPos(ElementName, ':');
        if ColonPos > 0 then begin
            Prefix := CopyStr(ElementName, 1, ColonPos - 1);
            LocalName := CopyStr(ElementName, ColonPos + 1);
            NamespaceUri := GetNamespaceUri(Prefix);
        end else begin
            LocalName := ElementName;
            NamespaceUri := GetNamespaceUri('');
        end;

        NewElement := XmlElement.Create(LocalName, NamespaceUri, ElementValue);
        Attribute1 := XmlAttribute.Create(Attr1Name, Attr1Value);
        Attribute2 := XmlAttribute.Create(Attr2Name, Attr2Value);
        NewElement.Add(Attribute1);
        NewElement.Add(Attribute2);
        ParentElement.Add(NewElement);
    end;

    // HELPER METHODS
    local procedure AddElement(var ParentElement: XmlElement; ElementName: Text; ElementValue: Text)
    var
        NewElement: XmlElement;
        Prefix: Text;
        LocalName: Text;
        NamespaceUri: Text;
        ColonPos: Integer;
    begin
        if ElementValue <> '' then begin
            ColonPos := StrPos(ElementName, ':');
            if ColonPos > 0 then begin
                Prefix := CopyStr(ElementName, 1, ColonPos - 1);
                LocalName := CopyStr(ElementName, ColonPos + 1);
                NamespaceUri := GetNamespaceUri(Prefix);
            end else begin
                LocalName := ElementName;
                NamespaceUri := GetNamespaceUri('');
            end;

            NewElement := XmlElement.Create(LocalName, NamespaceUri, ElementValue);
            ParentElement.Add(NewElement);
        end;
    end;

    local procedure GetNamespaceUri(Prefix: Text): Text
    begin
        case Prefix of
            'cbc':
                exit('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
            'cac':
                exit('urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            '':
                exit('urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        end;
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure GetLHDNTaxCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        exit('MYR');
    end;

    local procedure GetTINNumber(Customer: Record Customer): Text[20]
    begin
        // TIN (Tax Identification Number)
        if Customer."MY eInv TIN" <> '' then
            exit(Customer."MY eInv TIN")
        else
            exit('');
    end;

    local procedure GetBRNNumber(Customer: Record Customer): Text[20]
    begin
        // BRN (Business Register Number)
        if Customer."MY eInv BRN" <> '' then
            exit(Customer."MY eInv BRN")
        else
            exit('');
    end;

    local procedure GetSSTNumber(Customer: Record Customer): Text[20]
    begin
        // SST (Sales Service Tax)
        if Customer."MY eInv SST No." <> '' then
            exit(Customer."MY eInv SST No.")
        else
            exit('');
    end;

    local procedure GetTINNumber(CompanyInfo: Record "Company Information"): Text
    begin
        // TIN (Tax Identification Number) - separate from VAT
        // You need to add a custom field "TIN No." to Customer table
        if CompanyInfo."MY eInv Tin" <> '' then
            exit(CompanyInfo."MY eInv Tin")
        else
            exit('');
    end;

    local procedure GetSSTNumber(CompanyInfo: Record "Company Information"): Text[20]
    begin
        // SST (Sales Service Tax)
        if CompanyInfo."MY eInv SST No." <> '' then
            exit(CompanyInfo."MY eInv SST No.")
        else
            exit('');
    end;

    local procedure AddAmountElement(var ParentElement: XmlElement; ElementName: Text; Amount: Decimal; CurrencyCode: Code[10])
    var
        NewElement: XmlElement;
        CurrencyAttr: XmlAttribute;
        Prefix: Text;
        LocalName: Text;
        NamespaceUri: Text;
        ColonPos: Integer;
        FormattedAmount: Text;
    begin
        ColonPos := StrPos(ElementName, ':');
        if ColonPos > 0 then begin
            Prefix := CopyStr(ElementName, 1, ColonPos - 1);
            LocalName := CopyStr(ElementName, ColonPos + 1);
            NamespaceUri := GetNamespaceUri(Prefix);
        end else begin
            LocalName := ElementName;
            NamespaceUri := GetNamespaceUri('');
        end;

        // Format without thousand separator
        FormattedAmount := Format(Amount, 0, '<Precision,2:2><Standard Format,9>');

        NewElement := XmlElement.Create(LocalName, NamespaceUri, FormattedAmount);
        CurrencyAttr := XmlAttribute.Create('currencyID', CurrencyCode);
        NewElement.Add(CurrencyAttr);
        ParentElement.Add(NewElement);
    end;

    local procedure AddQuantityElement(var ParentElement: XmlElement; ElementName: Text; Quantity: Decimal; UnitCode: Code[10])
    var
        NewElement: XmlElement;
        UnitAttr: XmlAttribute;
        Prefix: Text;
        LocalName: Text;
        NamespaceUri: Text;
        ColonPos: Integer;
    begin
        ColonPos := StrPos(ElementName, ':');
        if ColonPos > 0 then begin
            Prefix := CopyStr(ElementName, 1, ColonPos - 1);
            LocalName := CopyStr(ElementName, ColonPos + 1);
            NamespaceUri := GetNamespaceUri(Prefix);
        end else begin
            LocalName := ElementName;
            NamespaceUri := GetNamespaceUri('');
        end;

        NewElement := XmlElement.Create(LocalName, NamespaceUri, Format(Quantity, 0, '<Precision,2:2><Standard Format,0>'));
        UnitAttr := XmlAttribute.Create('unitCode', UnitCode);
        NewElement.Add(UnitAttr);
        ParentElement.Add(NewElement);
    end;

    local procedure AddPartyIdentification(var PartyElement: XmlElement; IDValue: Text; SchemeID: Text)
    var
        IDElement: XmlElement;
        PartyIDElement: XmlElement;
        SchemeAttr: XmlAttribute;
    begin
        if IDValue <> '' then begin
            PartyIDElement := XmlElement.Create('PartyIdentification', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            IDElement := XmlElement.Create('ID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', IDValue);
            SchemeAttr := XmlAttribute.Create('schemeID', SchemeID);
            IDElement.Add(SchemeAttr);
            PartyIDElement.Add(IDElement);
            PartyElement.Add(PartyIDElement);
        end;
    end;

    local procedure AddAddressLine(var PostalElement: XmlElement; AddressText: Text)
    var
        AddressLineElement: XmlElement;
    begin
        if AddressText <> '' then begin
            AddressLineElement := XmlElement.Create('AddressLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElement(AddressLineElement, 'cbc:Line', AddressText);
            PostalElement.Add(AddressLineElement);
        end;
    end;

    local procedure AddCountry(var PostalElement: XmlElement; CountryCode: Code[10])
    var
        CountryElement: XmlElement;
    begin
        if CountryCode <> '' then begin
            CountryElement := XmlElement.Create('Country', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElementWithTwoAttributes(CountryElement, 'cbc:IdentificationCode', CountryCode, 'listID', 'ISO3166-1', 'listAgencyID', '6');
            PostalElement.Add(CountryElement);
        end;
    end;

    /* local procedure AddCountry(var PostalElement: XmlElement; CountryCode: Code[10])
    var
        CountryElement: XmlElement;
    begin
        if CountryCode <> '' then begin
            CountryElement := XmlElement.Create('Country', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElement(CountryElement, 'cbc:IdentificationCode', CountryCode);
            PostalElement.Add(CountryElement);
        end;
    end; */

    local procedure AddElementWithAttribute(var ParentElement: XmlElement; ElementName: Text; ElementValue: Text; AttributeName: Text; AttributeValue: Text)
    var
        NewElement: XmlElement;
        NewAttribute: XmlAttribute;
        Prefix: Text;
        LocalName: Text;
        NamespaceUri: Text;
        ColonPos: Integer;
    begin
        ColonPos := StrPos(ElementName, ':');
        if ColonPos > 0 then begin
            Prefix := CopyStr(ElementName, 1, ColonPos - 1);
            LocalName := CopyStr(ElementName, ColonPos + 1);
            NamespaceUri := GetNamespaceUri(Prefix);
        end else begin
            LocalName := ElementName;
            NamespaceUri := GetNamespaceUri('');
        end;

        NewElement := XmlElement.Create(LocalName, NamespaceUri, ElementValue);
        NewAttribute := XmlAttribute.Create(AttributeName, AttributeValue);
        NewElement.Add(NewAttribute);
        ParentElement.Add(NewElement);
    end;
}
