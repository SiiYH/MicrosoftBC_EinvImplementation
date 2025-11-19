// ═════════════════════════════════════════════════════════════════
// MY eInv XML Generator - UBL 2.1 Invoice Generation
// ═════════════════════════════════════════════════════════════════
codeunit 70000007 "MY eInv XML Generator"
{
    procedure GenerateInvoiceXML(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        XMLDoc: XmlDocument;
        RootElement: XmlElement;
        Result: Text;
    begin
        // Create root Invoice element with namespaces
        RootElement := CreateInvoiceRootElement();

        // Build invoice structure
        AddUBLVersionID(RootElement);
        AddCustomizationID(RootElement);
        AddProfileID(RootElement);
        AddInvoiceTypeCode(RootElement, SalesInvoiceHeader);
        AddDocumentCurrencyCode(RootElement, SalesInvoiceHeader);
        AddInvoiceIdentification(RootElement, SalesInvoiceHeader);
        AddInvoicePeriod(RootElement, SalesInvoiceHeader);
        AddBillingReference(RootElement, SalesInvoiceHeader);
        AddSupplierParty(RootElement, SalesInvoiceHeader);
        AddCustomerParty(RootElement, SalesInvoiceHeader);
        AddDelivery(RootElement, SalesInvoiceHeader);
        AddPaymentMeans(RootElement, SalesInvoiceHeader);
        AddTaxTotal(RootElement, SalesInvoiceHeader);
        AddLegalMonetaryTotal(RootElement, SalesInvoiceHeader);
        AddInvoiceLines(RootElement, SalesInvoiceHeader);

        XMLDoc.Add(RootElement);

        // Convert to text with XML declaration
        XMLDoc.WriteTo(Result);

        // Ensure XML declaration is present (BC automatically adds it)
        if not Result.StartsWith('<?xml') then
            Result := '<?xml version="1.0" encoding="UTF-8"?>' + Result;

        exit(Result);
    end;

    local procedure CreateInvoiceRootElement(): XmlElement
    var
        RootElement: XmlElement;
        Xmlns: XmlAttribute;
    begin
        RootElement := XmlElement.Create('Invoice');

        // Add namespaces
        Xmlns := XmlAttribute.CreateNamespaceDeclaration('', 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        RootElement.Add(Xmlns);

        Xmlns := XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        RootElement.Add(Xmlns);

        Xmlns := XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        RootElement.Add(Xmlns);

        exit(RootElement);
    end;

    local procedure AddUBLVersionID(var ParentElement: XmlElement)
    begin
        AddElement(ParentElement, 'cbc:UBLVersionID', '2.1');
    end;

    local procedure AddCustomizationID(var ParentElement: XmlElement)
    begin
        AddElement(ParentElement, 'cbc:CustomizationID', 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0');
    end;

    local procedure AddProfileID(var ParentElement: XmlElement)
    begin
        AddElement(ParentElement, 'cbc:ProfileID', 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
    end;

    local procedure AddInvoiceTypeCode(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        TypeCode: Text;
    begin
        // 01 = Invoice, 02 = Credit Note, 03 = Debit Note, etc.
        TypeCode := '01';
        AddElement(ParentElement, 'cbc:InvoiceTypeCode', TypeCode);
    end;

    local procedure AddDocumentCurrencyCode(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        AddElement(ParentElement, 'cbc:DocumentCurrencyCode', SalesInvoiceHeader."Currency Code");
    end;

    local procedure AddInvoiceIdentification(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        AddElement(ParentElement, 'cbc:ID', SalesInvoiceHeader."No.");
        AddElement(ParentElement, 'cbc:IssueDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(ParentElement, 'cbc:IssueTime', Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));
    end;

    local procedure AddInvoicePeriod(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PeriodElement: XmlElement;
    begin
        PeriodElement := XmlElement.Create('cac:InvoicePeriod', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PeriodElement, 'cbc:StartDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(PeriodElement, 'cbc:EndDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        ParentElement.Add(PeriodElement);
    end;

    local procedure AddBillingReference(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        BillingRefElement: XmlElement;
    begin
        if SalesInvoiceHeader."Order No." <> '' then begin
            BillingRefElement := XmlElement.Create('cac:BillingReference', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElement(BillingRefElement, 'cbc:ID', SalesInvoiceHeader."Order No.");
            ParentElement.Add(BillingRefElement);
        end;
    end;

    local procedure AddSupplierParty(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CompanyInfo: Record "Company Information";
        SupplierElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
    begin
        CompanyInfo.Get();

        SupplierElement := XmlElement.Create('cac:AccountingSupplierParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('cac:Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Party identification (TIN/SST)
        AddPartyIdentification(PartyElement, CompanyInfo."Registration No.", 'TIN');

        // Postal address
        PostalElement := XmlElement.Create('cac:PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', CompanyInfo.City);
        AddElement(PostalElement, 'cbc:PostalZone', CompanyInfo."Post Code");
        AddElement(PostalElement, 'cbc:CountrySubentityCode', GetStateCode(CompanyInfo.County));
        AddAddressLine(PostalElement, CompanyInfo.Address);
        AddAddressLine(PostalElement, CompanyInfo."Address 2");
        AddCountry(PostalElement, CompanyInfo."Country/Region Code");
        PartyElement.Add(PostalElement);

        // Legal entity
        LegalElement := XmlElement.Create('cac:PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', CompanyInfo.Name);
        PartyElement.Add(LegalElement);

        SupplierElement.Add(PartyElement);
        ParentElement.Add(SupplierElement);
    end;

    local procedure AddCustomerParty(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        CustomerElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
    begin
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");

        CustomerElement := XmlElement.Create('cac:AccountingCustomerParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('cac:Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        // Party identification
        AddPartyIdentification(PartyElement, Customer."VAT Registration No.", 'TIN');

        // Postal address
        PostalElement := XmlElement.Create('cac:PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', Customer.City);
        AddElement(PostalElement, 'cbc:PostalZone', Customer."Post Code");
        AddElement(PostalElement, 'cbc:CountrySubentityCode', GetStateCode(Customer.County));
        AddAddressLine(PostalElement, SalesInvoiceHeader."Bill-to Address");
        AddAddressLine(PostalElement, SalesInvoiceHeader."Bill-to Address 2");
        AddCountry(PostalElement, SalesInvoiceHeader."Bill-to Country/Region Code");
        PartyElement.Add(PostalElement);

        // Legal entity
        LegalElement := XmlElement.Create('cac:PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', SalesInvoiceHeader."Bill-to Name");
        PartyElement.Add(LegalElement);

        CustomerElement.Add(PartyElement);
        ParentElement.Add(CustomerElement);
    end;

    local procedure AddDelivery(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DeliveryElement: XmlElement;
    begin
        DeliveryElement := XmlElement.Create('cac:Delivery', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(DeliveryElement, 'cbc:ActualDeliveryDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        ParentElement.Add(DeliveryElement);
    end;

    local procedure AddPaymentMeans(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentElement: XmlElement;
    begin
        PaymentElement := XmlElement.Create('cac:PaymentMeans', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PaymentElement, 'cbc:PaymentMeansCode', '01'); // 01 = Bank Transfer
        ParentElement.Add(PaymentElement);
    end;

    local procedure AddTaxTotal(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxTotalElement: XmlElement;
        TaxSubtotalElement: XmlElement;
        TaxCategoryElement: XmlElement;
        TaxSchemeElement: XmlElement;
        TotalTaxAmount: Decimal;
        TaxableAmount: Decimal;
    begin
        // Calculate totals
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                TotalTaxAmount += SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
                TaxableAmount += SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        TaxTotalElement := XmlElement.Create('cac:TaxTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxTotalElement, 'cbc:TaxAmount', TotalTaxAmount, SalesInvoiceHeader."Currency Code");

        // Tax subtotal
        TaxSubtotalElement := XmlElement.Create('cac:TaxSubtotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxableAmount', TaxableAmount, SalesInvoiceHeader."Currency Code");
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxAmount', TotalTaxAmount, SalesInvoiceHeader."Currency Code");

        // Tax category
        TaxCategoryElement := XmlElement.Create('cac:TaxCategory', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxCategoryElement, 'cbc:ID', 'S'); // S = Standard rate
        AddElement(TaxCategoryElement, 'cbc:Percent', '6.00'); // SST rate

        TaxSchemeElement := XmlElement.Create('cac:TaxScheme', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxSchemeElement, 'cbc:ID', 'SST');
        TaxCategoryElement.Add(TaxSchemeElement);

        TaxSubtotalElement.Add(TaxCategoryElement);
        TaxTotalElement.Add(TaxSubtotalElement);
        ParentElement.Add(TaxTotalElement);
    end;

    local procedure AddLegalMonetaryTotal(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        MonetaryElement: XmlElement;
        LineExtensionAmount: Decimal;
        TaxExclusiveAmount: Decimal;
        TaxInclusiveAmount: Decimal;
        PayableAmount: Decimal;
    begin
        // Calculate amounts
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                LineExtensionAmount += SalesInvoiceLine.Amount;
                TaxExclusiveAmount += SalesInvoiceLine.Amount;
                TaxInclusiveAmount += SalesInvoiceLine."Amount Including VAT";
            until SalesInvoiceLine.Next() = 0;

        PayableAmount := TaxInclusiveAmount;

        MonetaryElement := XmlElement.Create('cac:LegalMonetaryTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(MonetaryElement, 'cbc:LineExtensionAmount', LineExtensionAmount, SalesInvoiceHeader."Currency Code");
        AddAmountElement(MonetaryElement, 'cbc:TaxExclusiveAmount', TaxExclusiveAmount, SalesInvoiceHeader."Currency Code");
        AddAmountElement(MonetaryElement, 'cbc:TaxInclusiveAmount', TaxInclusiveAmount, SalesInvoiceHeader."Currency Code");
        AddAmountElement(MonetaryElement, 'cbc:PayableAmount', PayableAmount, SalesInvoiceHeader."Currency Code");

        ParentElement.Add(MonetaryElement);
    end;

    local procedure AddInvoiceLines(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        if SalesInvoiceLine.FindSet() then
            repeat
                AddInvoiceLine(ParentElement, SalesInvoiceLine, SalesInvoiceHeader);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure AddInvoiceLine(var ParentElement: XmlElement; SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        LineElement: XmlElement;
        ItemElement: XmlElement;
        PriceElement: XmlElement;
        TaxTotalElement: XmlElement;
    begin
        LineElement := XmlElement.Create('cac:InvoiceLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        AddElement(LineElement, 'cbc:ID', Format(SalesInvoiceLine."Line No."));
        AddQuantityElement(LineElement, 'cbc:InvoicedQuantity', SalesInvoiceLine.Quantity, SalesInvoiceLine."Unit of Measure Code");
        AddAmountElement(LineElement, 'cbc:LineExtensionAmount', SalesInvoiceLine.Amount, SalesInvoiceHeader."Currency Code");

        // Item
        ItemElement := XmlElement.Create('cac:Item', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ItemElement, 'cbc:Description', SalesInvoiceLine.Description);
        LineElement.Add(ItemElement);

        // Price
        PriceElement := XmlElement.Create('cac:Price', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(PriceElement, 'cbc:PriceAmount', SalesInvoiceLine."Unit Price", SalesInvoiceHeader."Currency Code");
        LineElement.Add(PriceElement);

        ParentElement.Add(LineElement);
    end;

    // Helper methods
    local procedure AddElement(var ParentElement: XmlElement; ElementName: Text; ElementValue: Text)
    var
        NewElement: XmlElement;
    begin
        if ElementValue <> '' then begin
            NewElement := XmlElement.Create(ElementName, GetNamespace(ElementName), ElementValue);
            ParentElement.Add(NewElement);
        end;
    end;

    local procedure AddAmountElement(var ParentElement: XmlElement; ElementName: Text; Amount: Decimal; CurrencyCode: Code[10])
    var
        NewElement: XmlElement;
        CurrencyAttr: XmlAttribute;
    begin
        NewElement := XmlElement.Create(ElementName, GetNamespace(ElementName), Format(Amount, 0, '<Precision,2:2><Standard Format,0>'));
        CurrencyAttr := XmlAttribute.Create('currencyID', CurrencyCode);
        NewElement.Add(CurrencyAttr);
        ParentElement.Add(NewElement);
    end;

    local procedure AddQuantityElement(var ParentElement: XmlElement; ElementName: Text; Quantity: Decimal; UnitCode: Code[10])
    var
        NewElement: XmlElement;
        UnitAttr: XmlAttribute;
    begin
        NewElement := XmlElement.Create(ElementName, GetNamespace(ElementName), Format(Quantity, 0, '<Precision,2:2><Standard Format,0>'));
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
            PartyIDElement := XmlElement.Create('cac:PartyIdentification', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            IDElement := XmlElement.Create('cbc:ID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', IDValue);
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
            AddressLineElement := XmlElement.Create('cac:AddressLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElement(AddressLineElement, 'cbc:Line', AddressText);
            PostalElement.Add(AddressLineElement);
        end;
    end;

    local procedure AddCountry(var PostalElement: XmlElement; CountryCode: Code[10])
    var
        CountryElement: XmlElement;
    begin
        CountryElement := XmlElement.Create('cac:Country', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(CountryElement, 'cbc:IdentificationCode', CountryCode);
        PostalElement.Add(CountryElement);
    end;

    local procedure GetNamespace(ElementName: Text): Text
    begin
        if StrPos(ElementName, 'cbc:') > 0 then
            exit('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        if StrPos(ElementName, 'cac:') > 0 then
            exit('urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        exit('urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
    end;

    local procedure GetStateCode(StateName: Text): Code[10]
    begin
        // Map Malaysian state names to codes
        case StateName of
            'Johor':
                exit('01');
            'Kedah':
                exit('02');
            'Kelantan':
                exit('03');
            'Melaka', 'Malacca':
                exit('04');
            'Negeri Sembilan':
                exit('05');
            'Pahang':
                exit('06');
            'Penang', 'Pulau Pinang':
                exit('07');
            'Perak':
                exit('08');
            'Perlis':
                exit('09');
            'Selangor':
                exit('10');
            'Terengganu':
                exit('11');
            'Sabah':
                exit('12');
            'Sarawak':
                exit('13');
            'Kuala Lumpur', 'WP Kuala Lumpur':
                exit('14');
            'Labuan', 'WP Labuan':
                exit('15');
            'Putrajaya', 'WP Putrajaya':
                exit('16');
            else
                exit('10'); // Default to Selangor
        end;
    end;
}