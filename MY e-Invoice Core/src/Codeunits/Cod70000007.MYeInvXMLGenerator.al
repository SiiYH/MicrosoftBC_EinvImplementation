// ═════════════════════════════════════════════════════════════════
// MY eInv XML Generator - UBL 2.1 Invoice Generation
// ═════════════════════════════════════════════════════════════════
codeunit 70000007 "MY eInv XML Generator"
{

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
    begin
        // Create root Invoice element with namespaces
        RootElement := CreateInvoiceRootElement();

        // Build invoice structure - pass header record
        BuildInvoiceStructure(RootElement, SalesInvoiceHeader);

        XMLDoc.Add(RootElement);
        XMLDoc.WriteTo(Result);

        if not Result.StartsWith('<?xml') then
            Result := '<?xml version="1.0" encoding="UTF-8"?>' + Result;

        exit(Result);
    end;

    procedure GenerateCreditMemoXML(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        XMLDoc: XmlDocument;
        RootElement: XmlElement;
        Result: Text;
    begin
        // Create root CreditNote element (different from Invoice)
        RootElement := CreateCreditNoteRootElement();

        // Build credit memo structure - pass header record
        BuildCreditMemoStructure(RootElement, SalesCrMemoHeader);

        XMLDoc.Add(RootElement);
        XMLDoc.WriteTo(Result);

        if not Result.StartsWith('<?xml') then
            Result := '<?xml version="1.0" encoding="UTF-8"?>' + Result;

        exit(Result);
    end;

    // INVOICE SPECIFIC
    local procedure BuildInvoiceStructure(var RootElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        AddUBLVersionID(RootElement);
        AddCustomizationID(RootElement);
        AddProfileID(RootElement);
        AddElement(RootElement, 'cbc:InvoiceTypeCode', '01'); // Invoice type
        AddDocumentCurrencyCode(RootElement, SalesInvoiceHeader."Currency Code");
        AddElement(RootElement, 'cbc:ID', SalesInvoiceHeader."No.");
        AddElement(RootElement, 'cbc:IssueDate', Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(RootElement, 'cbc:IssueTime', Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));

        AddInvoicePeriod(RootElement, SalesInvoiceHeader."Posting Date");
        AddBillingReference(RootElement, SalesInvoiceHeader."Order No.");
        AddSupplierPartyFromInvoice(RootElement, SalesInvoiceHeader);
        AddCustomerPartyFromInvoice(RootElement, SalesInvoiceHeader);
        AddDelivery(RootElement, SalesInvoiceHeader."Posting Date");
        AddPaymentMeans(RootElement);
        AddTaxTotalFromInvoice(RootElement, SalesInvoiceHeader);
        AddLegalMonetaryTotalFromInvoice(RootElement, SalesInvoiceHeader);
        AddInvoiceLines(RootElement, SalesInvoiceHeader);
    end;

    // CREDIT MEMO SPECIFIC
    local procedure BuildCreditMemoStructure(var RootElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        AddUBLVersionID(RootElement);
        AddCustomizationID(RootElement);
        AddProfileID(RootElement);
        AddElement(RootElement, 'cbc:CreditNoteTypeCode', '02'); // Credit note type
        AddDocumentCurrencyCode(RootElement, SalesCrMemoHeader."Currency Code");
        AddElement(RootElement, 'cbc:ID', SalesCrMemoHeader."No.");
        AddElement(RootElement, 'cbc:IssueDate', Format(SalesCrMemoHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(RootElement, 'cbc:IssueTime', Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));

        // Add billing reference to original invoice if applicable
        if SalesCrMemoHeader."Applies-to Doc. No." <> '' then
            AddBillingReference(RootElement, SalesCrMemoHeader."Applies-to Doc. No.");

        AddInvoicePeriod(RootElement, SalesCrMemoHeader."Posting Date");
        AddSupplierPartyFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddCustomerPartyFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddDelivery(RootElement, SalesCrMemoHeader."Posting Date");
        AddPaymentMeans(RootElement);
        AddTaxTotalFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddLegalMonetaryTotalFromCreditMemo(RootElement, SalesCrMemoHeader);
        AddCreditMemoLines(RootElement, SalesCrMemoHeader);
    end;

    local procedure CreateCreditNoteRootElement(): XmlElement
    var
        RootElement: XmlElement;
        Xmlns: XmlAttribute;
    begin
        RootElement := XmlElement.Create('CreditNote'); // Different root element

        Xmlns := XmlAttribute.CreateNamespaceDeclaration('', 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        RootElement.Add(Xmlns);

        Xmlns := XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        RootElement.Add(Xmlns);

        Xmlns := XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        RootElement.Add(Xmlns);

        exit(RootElement);
    end;

    // GENERIC METHODS (Used by both Invoice and Credit Memo)
    local procedure CreateInvoiceRootElement(): XmlElement
    var
        RootElement: XmlElement;
    begin
        // Create the Invoice element with the default namespace
        RootElement := XmlElement.Create('Invoice', 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');

        // Add the prefixed namespace declarations
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'));

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

    local procedure AddDocumentCurrencyCode(var ParentElement: XmlElement; CurrencyCode: Code[10])
    begin
        AddElement(ParentElement, 'cbc:DocumentCurrencyCode', CurrencyCode);
    end;

    local procedure AddInvoicePeriod(var ParentElement: XmlElement; PostingDate: Date)
    var
        PeriodElement: XmlElement;
    begin
        PeriodElement := XmlElement.Create('InvoicePeriod', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PeriodElement, 'cbc:StartDate', Format(PostingDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        AddElement(PeriodElement, 'cbc:EndDate', Format(PostingDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        ParentElement.Add(PeriodElement);
    end;

    local procedure AddBillingReference(var ParentElement: XmlElement; ReferenceNo: Code[20])
    var
        BillingRefElement: XmlElement;
    begin
        if ReferenceNo <> '' then begin
            BillingRefElement := XmlElement.Create('cac:BillingReference', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            AddElement(BillingRefElement, 'cbc:ID', ReferenceNo);
            ParentElement.Add(BillingRefElement);
        end;
    end;

    local procedure AddDelivery(var ParentElement: XmlElement; DeliveryDate: Date)
    var
        DeliveryElement: XmlElement;
    begin
        DeliveryElement := XmlElement.Create('cac:Delivery', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(DeliveryElement, 'cbc:ActualDeliveryDate', Format(DeliveryDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        ParentElement.Add(DeliveryElement);
    end;

    local procedure AddPaymentMeans(var ParentElement: XmlElement)
    var
        PaymentElement: XmlElement;
    begin
        PaymentElement := XmlElement.Create('cac:PaymentMeans', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PaymentElement, 'cbc:PaymentMeansCode', '01');
        ParentElement.Add(PaymentElement);
    end;

    // INVOICE-SPECIFIC PARTY METHODS
    local procedure AddSupplierPartyFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        AddSupplierParty(ParentElement, CompanyInfo);
    end;

    local procedure AddCustomerPartyFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        AddCustomerParty(ParentElement,
            Customer."VAT Registration No.",
            Customer.City,
            Customer."Post Code",
            Customer.County,
            SalesInvoiceHeader."Bill-to Address",
            SalesInvoiceHeader."Bill-to Address 2",
            SalesInvoiceHeader."Bill-to Country/Region Code",
            SalesInvoiceHeader."Bill-to Name");
    end;

    // CREDIT MEMO-SPECIFIC PARTY METHODS
    local procedure AddSupplierPartyFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        AddSupplierParty(ParentElement, CompanyInfo);
    end;

    local procedure AddCustomerPartyFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        AddCustomerParty(ParentElement,
            Customer."VAT Registration No.",
            Customer.City,
            Customer."Post Code",
            Customer.County,
            SalesCrMemoHeader."Bill-to Address",
            SalesCrMemoHeader."Bill-to Address 2",
            SalesCrMemoHeader."Bill-to Country/Region Code",
            SalesCrMemoHeader."Bill-to Name");
    end;

    // GENERIC PARTY METHOD (reused by both)
    local procedure AddSupplierParty(var ParentElement: XmlElement; CompanyInfo: Record "Company Information")
    var
        PostCodeRec: Record "Post Code";
        SupplierElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
    begin
        SupplierElement := XmlElement.Create('cac:AccountingSupplierParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('cac:Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        AddPartyIdentification(PartyElement, CompanyInfo."Registration No.", 'TIN');

        PostalElement := XmlElement.Create('cac:PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', CompanyInfo.City);
        AddElement(PostalElement, 'cbc:PostalZone', CompanyInfo."Post Code");
        AddElement(PostalElement, 'cbc:CountrySubentityCode', PostCodeRec.GetStateCodeFromPostCode(CompanyInfo."Post Code"));
        AddAddressLine(PostalElement, CompanyInfo.Address);
        AddAddressLine(PostalElement, CompanyInfo."Address 2");
        AddCountry(PostalElement, CompanyInfo."Country/Region Code");
        PartyElement.Add(PostalElement);

        LegalElement := XmlElement.Create('cac:PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', CompanyInfo.Name);
        PartyElement.Add(LegalElement);

        SupplierElement.Add(PartyElement);
        ParentElement.Add(SupplierElement);
    end;

    local procedure AddCustomerParty(var ParentElement: XmlElement; VATRegNo: Text[20]; City: Text[30]; PostCode: Code[20]; County: Text[30]; Address: Text[100]; Address2: Text[50]; CountryCode: Code[10]; Name: Text[100])
    var
        PostCodeRec: Record "Post Code";
        CustomerElement: XmlElement;
        PartyElement: XmlElement;
        PostalElement: XmlElement;
        LegalElement: XmlElement;
    begin
        CustomerElement := XmlElement.Create('cac:AccountingCustomerParty', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyElement := XmlElement.Create('cac:Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        AddPartyIdentification(PartyElement, VATRegNo, 'TIN');

        PostalElement := XmlElement.Create('cac:PostalAddress', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(PostalElement, 'cbc:CityName', City);
        AddElement(PostalElement, 'cbc:PostalZone', PostCode);
        AddElement(PostalElement, 'cbc:CountrySubentityCode', PostCodeRec.GetStateCodeFromPostCode(PostCode));
        AddAddressLine(PostalElement, Address);
        AddAddressLine(PostalElement, Address2);
        AddCountry(PostalElement, CountryCode);
        PartyElement.Add(PostalElement);

        LegalElement := XmlElement.Create('cac:PartyLegalEntity', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LegalElement, 'cbc:RegistrationName', Name);
        PartyElement.Add(LegalElement);

        CustomerElement.Add(PartyElement);
        ParentElement.Add(CustomerElement);
    end;

    // TAX AND MONETARY - Continue pattern...
    local procedure AddTaxTotalFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        TotalTaxAmount: Decimal;
        TaxableAmount: Decimal;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                TotalTaxAmount += SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
                TaxableAmount += SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        AddTaxTotal(ParentElement, TotalTaxAmount, TaxableAmount, SalesInvoiceHeader."Currency Code");
    end;

    local procedure AddTaxTotalFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TotalTaxAmount: Decimal;
        TaxableAmount: Decimal;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                TotalTaxAmount += SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
                TaxableAmount += SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;

        AddTaxTotal(ParentElement, TotalTaxAmount, TaxableAmount, SalesCrMemoHeader."Currency Code");
    end;

    local procedure AddTaxTotal(var ParentElement: XmlElement; TotalTaxAmount: Decimal; TaxableAmount: Decimal; CurrencyCode: Code[10])
    var
        TaxTotalElement: XmlElement;
        TaxSubtotalElement: XmlElement;
        TaxCategoryElement: XmlElement;
        TaxSchemeElement: XmlElement;
    begin
        TaxTotalElement := XmlElement.Create('cac:TaxTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxTotalElement, 'cbc:TaxAmount', TotalTaxAmount, CurrencyCode);

        TaxSubtotalElement := XmlElement.Create('cac:TaxSubtotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxableAmount', TaxableAmount, CurrencyCode);
        AddAmountElement(TaxSubtotalElement, 'cbc:TaxAmount', TotalTaxAmount, CurrencyCode);

        TaxCategoryElement := XmlElement.Create('cac:TaxCategory', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxCategoryElement, 'cbc:ID', 'S');
        AddElement(TaxCategoryElement, 'cbc:Percent', '6.00');

        TaxSchemeElement := XmlElement.Create('cac:TaxScheme', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(TaxSchemeElement, 'cbc:ID', 'SST');
        TaxCategoryElement.Add(TaxSchemeElement);

        TaxSubtotalElement.Add(TaxCategoryElement);
        TaxTotalElement.Add(TaxSubtotalElement);
        ParentElement.Add(TaxTotalElement);
    end;

    // Continue similar pattern for monetary totals and lines...
    local procedure AddLegalMonetaryTotalFromInvoice(var ParentElement: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        LineExtensionAmount: Decimal;
        TaxExclusiveAmount: Decimal;
        TaxInclusiveAmount: Decimal;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                LineExtensionAmount += SalesInvoiceLine.Amount;
                TaxExclusiveAmount += SalesInvoiceLine.Amount;
                TaxInclusiveAmount += SalesInvoiceLine."Amount Including VAT";
            until SalesInvoiceLine.Next() = 0;

        AddLegalMonetaryTotal(ParentElement, LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount, SalesInvoiceHeader."Currency Code");
    end;

    local procedure AddLegalMonetaryTotalFromCreditMemo(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        LineExtensionAmount: Decimal;
        TaxExclusiveAmount: Decimal;
        TaxInclusiveAmount: Decimal;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                LineExtensionAmount += SalesCrMemoLine.Amount;
                TaxExclusiveAmount += SalesCrMemoLine.Amount;
                TaxInclusiveAmount += SalesCrMemoLine."Amount Including VAT";
            until SalesCrMemoLine.Next() = 0;

        AddLegalMonetaryTotal(ParentElement, LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount, SalesCrMemoHeader."Currency Code");
    end;

    local procedure AddLegalMonetaryTotal(var ParentElement: XmlElement; LineExtensionAmount: Decimal; TaxExclusiveAmount: Decimal; TaxInclusiveAmount: Decimal; CurrencyCode: Code[10])
    var
        MonetaryElement: XmlElement;
    begin
        MonetaryElement := XmlElement.Create('cac:LegalMonetaryTotal', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(MonetaryElement, 'cbc:LineExtensionAmount', LineExtensionAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:TaxExclusiveAmount', TaxExclusiveAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:TaxInclusiveAmount', TaxInclusiveAmount, CurrencyCode);
        AddAmountElement(MonetaryElement, 'cbc:PayableAmount', TaxInclusiveAmount, CurrencyCode);
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
                AddInvoiceLine(ParentElement, SalesInvoiceLine."Line No.", SalesInvoiceLine.Quantity,
                    SalesInvoiceLine."Unit of Measure Code", SalesInvoiceLine.Amount,
                    SalesInvoiceLine.Description, SalesInvoiceLine."Unit Price", SalesInvoiceHeader."Currency Code");
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure AddCreditMemoLines(var ParentElement: XmlElement; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindSet() then
            repeat
                AddCreditNoteLine(ParentElement, SalesCrMemoLine."Line No.", SalesCrMemoLine.Quantity,
                    SalesCrMemoLine."Unit of Measure Code", SalesCrMemoLine.Amount,
                    SalesCrMemoLine.Description, SalesCrMemoLine."Unit Price", SalesCrMemoHeader."Currency Code");
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure AddInvoiceLine(var ParentElement: XmlElement; LineNo: Integer; Quantity: Decimal; UnitOfMeasure: Code[10]; Amount: Decimal; Description: Text[100]; UnitPrice: Decimal; CurrencyCode: Code[10])
    var
        LineElement: XmlElement;
        ItemElement: XmlElement;
        PriceElement: XmlElement;
    begin
        LineElement := XmlElement.Create('cac:InvoiceLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LineElement, 'cbc:ID', Format(LineNo));
        AddQuantityElement(LineElement, 'cbc:InvoicedQuantity', Quantity, UnitOfMeasure);
        AddAmountElement(LineElement, 'cbc:LineExtensionAmount', Amount, CurrencyCode);

        ItemElement := XmlElement.Create('cac:Item', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ItemElement, 'cbc:Description', Description);
        LineElement.Add(ItemElement);

        PriceElement := XmlElement.Create('cac:Price', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(PriceElement, 'cbc:PriceAmount', UnitPrice, CurrencyCode);
        LineElement.Add(PriceElement);

        ParentElement.Add(LineElement);
    end;

    local procedure AddCreditNoteLine(var ParentElement: XmlElement; LineNo: Integer; Quantity: Decimal; UnitOfMeasure: Code[10]; Amount: Decimal; Description: Text[100]; UnitPrice: Decimal; CurrencyCode: Code[10])
    var
        LineElement: XmlElement;
        ItemElement: XmlElement;
        PriceElement: XmlElement;
    begin
        LineElement := XmlElement.Create('cac:CreditNoteLine', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(LineElement, 'cbc:ID', Format(LineNo));
        AddQuantityElement(LineElement, 'cbc:CreditedQuantity', Quantity, UnitOfMeasure);
        AddAmountElement(LineElement, 'cbc:LineExtensionAmount', Amount, CurrencyCode);

        ItemElement := XmlElement.Create('cac:Item', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddElement(ItemElement, 'cbc:Description', Description);
        LineElement.Add(ItemElement);

        PriceElement := XmlElement.Create('cac:Price', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        AddAmountElement(PriceElement, 'cbc:PriceAmount', UnitPrice, CurrencyCode);
        LineElement.Add(PriceElement);

        ParentElement.Add(LineElement);
    end;

    // ALL YOUR EXISTING HELPER METHODS (unchanged)
    /* local procedure AddElement(var ParentElement: XmlElement; ElementName: Text; ElementValue: Text)
    var
        NewElement: XmlElement;
    begin
        if ElementValue <> '' then begin
            NewElement := XmlElement.Create(ElementName, GetNamespace(ElementName), ElementValue);
            ParentElement.Add(NewElement);
        end;
    end; */
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
}