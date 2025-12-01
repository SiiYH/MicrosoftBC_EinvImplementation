xmlport 70902 "SalesInvoice1.0 MY01-IBIZ"
{
    Caption = 'Sales Invoice 1.0';
    Direction = Export;
    Encoding = UTF8;
    Namespaces = "" = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';

    schema
    {
        tableelement(invoiceheaderloop; Integer)
        {
            MaxOccurs = Once;
            XmlName = 'Invoice';
            SourceTableView = sorting(Number) where(Number = filter(1));
            //e-Invoice Code / Number>>
            textelement(ID)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'ID';
            }
            //e-Invoice Code / Number<<
            //e-Invoice Date>>
            textelement(IssueDate)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'IssueDate';
            }
            //e-Invoice Date<<
            //e-Invoice Time>>
            textelement(IssueTime)
            {
                XmlName = 'IssueTime';
                NamespacePrefix = 'cbc';
            }
            //e-Invoice Time<<
            // e-Invoice Version>>//e-Invoice Type Code>>
            textelement(InvoiceTypeCode)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'InvoiceTypeCode';
                textattribute(InvoiceTypecodeListID)
                {
                    XmlName = 'listVersionID';
                }
            }
            // e-Invoice Version>>//e-Invoice Type Code<<
            //Invoice Currency Code>>
            textelement(DocumentCurrencyCode)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'DocumentCurrencyCode';
            }
            textelement(taxcurrencycodelcy)
            {
                NamespacePrefix = 'cbc';
                XmlName = 'TaxCurrencyCode';

                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetTaxTotalInfoLCY(SalesHeader, TaxCurrencyCodeLCY);
                    if TaxCurrencyCodeLCY = '' then
                        currXMLport.Skip();
                end;
            }
            //Invoice Currency Code<<
            //Frequency of Billing>>
            textelement(InvoicePeriod)
            {
                NamespacePrefix = 'cac';
                XmlName = 'InvoicePeriod';
                //Billing Period Start Date>>
                textelement(StartDate)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'StartDate';
                    trigger OnBeforePassVariable()
                    begin
                        if StartDate = '' then
                            currXMLport.Skip();
                    end;
                }
                //Billing Period Start Date<<
                //Billing Period End Date>>
                textelement(EndDate)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'EndDate';
                    trigger OnBeforePassVariable()
                    begin
                        if EndDate = '' then
                            currXMLport.Skip();
                    end;
                }
                //Billing Period End Date<<
                //Frequency of Billing>>
                textelement(InvoicePeriodDescription)
                {
                    XmlName = 'Description';
                    NamespacePrefix = 'cbc';
                    trigger OnBeforePassVariable()
                    begin
                        if InvoicePeriodDescription = '' then
                            currXMLport.Skip();
                    end;
                }
                //Frequency of Billing<<
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetInvoicePeriodInfo(SalesHeader,
                      StartDate, EndDate, InvoicePeriodDescription);

                    if (StartDate = '') and (EndDate = '') and (InvoicePeriodDescription = '') then
                        currXMLport.Skip();
                end;
            }
            //Bill Reference Number>>
            // textelement(BillingReferenceDoc)
            tableelement(BillingReferenceDocloop; Integer)
            {
                XmlName = 'BillingReference';
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(InvoiceDocumentReference)
                {
                    XmlName = 'InvoiceDocumentReference';
                    NamespacePrefix = 'cac';
                    textelement(ReferenceIDDoc)
                    {
                        XmlName = 'ID';
                        NamespacePrefix = 'cbc';
                    }
                    textelement(ReferenceUUID)
                    {
                        XmlName = 'UUID';
                        NamespacePrefix = 'cbc';
                    }
                }

                trigger OnPreXmlItem()
                var
                    lReferenceDetails: Record "Reference Details MY01-IBIZ";
                begin
                    if SalesHeader."e-Invoice Type MY01-IBIZ" in ['02', '03', '04'] then begin
                        Clear(TempReferenceDetails);
                        case ProcessedDocType of
                            ProcessedDocType::Invoice:
                                begin
                                    lReferenceDetails.SetRange("Record ID", SalesInvoiceHeader.RecordId);
                                    if lReferenceDetails.FindSet() then
                                        repeat
                                            TempReferenceDetails.TransferFields(lReferenceDetails);
                                            TempReferenceDetails.Insert(false);
                                        until lReferenceDetails.Next() = 0;
                                end;
                            ProcessedDocType::CM:
                                begin
                                    lReferenceDetails.SetRange("Record ID", SalesCMHeader.RecordId);
                                    if lReferenceDetails.FindSet() then
                                        repeat
                                            TempReferenceDetails.TransferFields(lReferenceDetails);
                                            TempReferenceDetails.Insert(false);
                                        until lReferenceDetails.Next() = 0;
                                end;
                        end;
                    end;
                end;

                trigger OnAfterGetRecord()
                var
                    lSalesInvoiceHeader: Record "Sales Invoice Header";
                begin
                    IF InvoiceTypeCode = '01' then
                        currXMLport.Break();
                    Clear(ReferenceIDDoc);
                    Clear(ReferenceUUID);

                    if not FindNextReferenceRec(TempReferenceDetails, BillingReferenceDocloop.Number) then begin
                        if BillingReferenceDocloop.Number = 1 then begin
                            ReferenceIDDoc := 'NA';
                            ReferenceUUID := 'NA';
                        end else
                            currXMLport.Break();
                    end else begin
                        ReferenceIDDoc := TempReferenceDetails."Original IRBM RefNo.";
                        if ReferenceIDDoc = '' then
                            currXMLport.Skip();
                        if lSalesInvoiceHeader.get(ReferenceIDDoc) then
                            ReferenceUUID := lSalesInvoiceHeader."IRBM Unique Id. No. MY01-IBIZ";
                        if ReferenceUUID = '' then
                            Error('Reference document: %1 do not have a valid UUID', ReferenceIDDoc);
                    end;
                end;

            }
            //Bill Reference Number<<  
            //Bill Reference Number>>
            textelement(BillingReference)
            {
                XmlName = 'BillingReference';
                NamespacePrefix = 'cac';
                textelement(AdditionalDocumentReference)
                {
                    XmlName = 'AdditionalDocumentReference';
                    NamespacePrefix = 'cac';
                    textelement(ReferenceID)
                    {
                        XmlName = 'ID';
                        NamespacePrefix = 'cbc';
                    }
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetBillingReference(SalesHeader, ReferenceID);
                    if ReferenceID = '' then
                        currXMLport.Skip();
                end;
            }
            //Bill Reference Number<<  
            //Ref.No. of Customs>>
            textelement("AdditionalDocumentReference[1]")
            {
                XmlName = 'AdditionalDocumentReference';
                NamespacePrefix = 'cac';
                textelement("AdditionalDocumentReference[1]ID")
                {
                    XmlName = 'ID';
                    NamespacePrefix = 'cbc';
                }
                textelement(AdditionalDocumentReferenceDocumentType)
                {
                    XmlName = 'DocumentType';
                    NamespacePrefix = 'cbc';
                }
                trigger OnBeforePassVariable()
                begin
                    // AdditionalDocumentReferenceDocumentType := Header."Addi.Doc.Ref.[1]DocumentType";
                    // "AdditionalDocumentReference[1]ID" := Header."AdditionalDocumentReference[1]";
                    // if Header."Entry Type" <> Header."Entry Type"::Purchase then
                    //     currXMLport.Skip();
                    currXMLport.Skip();//Aadya this is sale transaction
                    InvoiceMgt.GetRefNoofCustoms(SalesHeader, AdditionalDocumentReferenceDocumentType, "AdditionalDocumentReference[1]ID");
                    if "AdditionalDocumentReference[1]ID" = '' then
                        currXMLport.Skip();
                end;
            }
            // Ref.No. of Customs<<
            // FTA>>
            textelement("AdditionalDocumentReference[2]")
            {
                XmlName = 'AdditionalDocumentReference';
                NamespacePrefix = 'cac';
                textelement("AdditionalDocumentReference[2]ID")
                {
                    XmlName = 'ID';
                    NamespacePrefix = 'cbc';
                }
                textelement("AdditionalDocumentReference[2]DocumentType")
                {
                    XmlName = 'DocumentType';
                    NamespacePrefix = 'cbc';
                }
                textelement("AdditionalDocumentReference[2]DocumentDescription")
                {
                    XmlName = 'DocumentDescription';
                    NamespacePrefix = 'cbc';
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetFTA(SalesHeader, "AdditionalDocumentReference[2]DocumentType", "AdditionalDocumentReference[2]ID", "AdditionalDocumentReference[2]DocumentDescription");
                    // "AdditionalDocumentReference[2]DocumentType" := Header."AdditionalDocumentReference[2]";
                    // "AdditionalDocumentReference[2]ID" := Header."AdditionalDocumentRef.ID[2]";
                    // "AdditionalDocumentReference[2]DocumentDescription" := Header."Addi.Docu.Ref.Description[2]";
                    if "AdditionalDocumentReference[2]DocumentDescription" = '' then
                        currXMLport.Skip();
                end;
            }
            // FTA<<
            // Customs Form No.2>>
            textelement("AdditionalDocumentReference[3]")
            {
                XmlName = 'AdditionalDocumentReference';
                NamespacePrefix = 'cac';
                textelement("AdditionalDocumentReference[3]ID")
                {
                    XmlName = 'ID';
                    NamespacePrefix = 'cbc';
                }
                textelement("Addi.Doc.Ref.DocumentType[3]")
                {
                    XmlName = 'DocumentType';
                    NamespacePrefix = 'cbc';
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetCustomsFormNo2(SalesHeader, "Addi.Doc.Ref.DocumentType[3]", "AdditionalDocumentReference[3]ID");
                    // "Addi.Doc.Ref.DocumentType[3]" := Header."Addi.Doc.Ref.DocumentType[3]";
                    // "AdditionalDocumentReference[3]ID" := Header."AdditionalDocumentReference[3]";
                    // if Header."Entry Type" <> Header."Entry Type"::Sale then
                    //     currXMLport.Skip();
                    if "AdditionalDocumentReference[3]ID" = '' then
                        currXMLport.Skip();
                end;
            }
            // Customs Form No.2<<
            // // Incoterms>>
            // textelement("AdditionalDocumentReference[4]")
            // {
            //     XmlName = 'AdditionalDocumentReference';
            //     NamespacePrefix = 'cac';
            //     textelement("AdditionalDocumentReference[4]ID")
            //     {
            //         XmlName = 'ID';
            //         NamespacePrefix = 'cac';
            //     }
            //     trigger OnBeforePassVariable()
            //     begin
            //         "AdditionalDocumentReference[4]ID" := Header."AdditionalDocumentReference[4]";
            //         if "AdditionalDocumentReference[4]ID" = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // // Incoterms<<
            //Supplier>>
            textelement(AccountingSupplierParty)
            {
                NamespacePrefix = 'cac';
                XmlName = 'AccountingSupplierParty';
                textelement(AdditionalAccountID)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'AdditionalAccountID';
                    textattribute(schemeAgencyName)
                    {
                        XmlName = 'schemeAgencyName';
                    }
                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetCustomsFormNo2(SalesHeader, schemeAgencyName, AdditionalAccountID);
                        if AdditionalAccountID = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(supplierparty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(SupplierIndustryClassificationCode)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'IndustryClassificationCode';
                        textattribute(SupplierIndustryClassificationCodeattribute)
                        {
                            XmlName = 'name';
                        }
                        trigger OnBeforePassVariable()
                        begin
                            InvoiceMgt.GetSupplierIndustryClassificationCode(SupplierIndustryClassificationCode, SupplierIndustryClassificationCodeattribute);
                        end;
                    }
                    textelement(PartyIdentification)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';

                        textelement(SupplierTIN)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(SupplierTINschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if SupplierTIN = '' then
                                Error('Supplier TIN is mandatory.');
                        end;
                    }
                    textelement(SupplierPartyIdentification2)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(SupplierRegistration)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(SupplierRegistrationschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if SupplierRegistration = '' then
                                Error('Supplier Registration details not exist.');
                        end;
                    }
                    textelement(SupplierPartyIdentification3)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(SupplierSST)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(SupplierSSTschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if SupplierSST = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(SupplierPartyIdentification4)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(SupplierTTX)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(SupplierTTXschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if SupplierTTX = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(supplierpostaladdress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(CityName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                            trigger OnBeforePassVariable()
                            begin
                                if CityName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(PostalZone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                            trigger OnBeforePassVariable()
                            begin
                                if PostalZone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(CountrySubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentityCode';
                            trigger OnBeforePassVariable()
                            begin
                                if CountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(SupplierAddressLineA)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(StreetName)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if StreetName = '' then
                                    Error('Supplier Address cannot be blank.');
                            end;
                        }
                        textelement(SupplierAddressLineB)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(supplieradditionalstreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if SupplierAdditionalStreetName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Country)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(SupplierCountryIdentificationCode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                                textattribute(SupplierCountryListID)
                                {
                                    XmlName = 'listID';
                                }
                                textattribute(SupplierCountryListAgencyID)
                                {
                                    XmlName = 'listAgencyID';
                                }
                                trigger OnBeforePassVariable()
                                begin
                                    if SupplierCountryIdentificationCode = '' then
                                        Error('Supplier country cannot be blank.');
                                end;
                            }
                        }
                    }
                    textelement(SupplierPartyLegalEntity)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyLegalEntity';
                        textelement(suppliername)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';
                            trigger OnBeforePassVariable()
                            begin
                                if suppliername = '' then
                                    Error('Supplier Registration Name is mandatory.');
                            end;
                        }
                    }
                    textelement(Contact)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'Contact';
                        textelement(Telephone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telephone';
                            trigger OnBeforePassVariable()
                            begin
                                if Telephone = '' then
                                    Error('Supplier Telephone cannot be blank.');
                            end;
                        }
                        textelement(ElectronicMail)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ElectronicMail';
                            trigger OnBeforePassVariable()
                            begin
                                if ElectronicMail = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if (Telephone = '') and (ElectronicMail = '') then
                                currXMLport.Skip();
                        end;
                    }
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetSupplierPartyIdentification(SalesHeader, SupplierTINschemeID, SupplierTIN, SupplierRegistration, SupplierRegistrationschemeID, SupplierSSTschemeID, SupplierSST, SupplierTTXschemeID, SupplierTTX);

                    InvoiceMgt.GetAccountingSupplierPartyInfoBIS(SupplierName);

                    InvoiceMgt.GetAccountingSupplierPartyPostalAddr(SalesHeader, StreetName, SupplierAdditionalStreetName,
                      CityName, PostalZone, CountrySubentity, SupplierCountryIdentificationCode, DummyVar, SupplierCountryListID, SupplierCountryListAgencyID);

                    InvoiceMgt.GetAccountingSupplierPartyContact(SalesHeader, DummyVar, Telephone, ElectronicMail);
                end;
            }
            //Supplier<<
            //Buyer>>
            textelement(AccountingCustomerParty)
            {
                NamespacePrefix = 'cac';
                XmlName = 'AccountingCustomerParty';
                textelement(customerparty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Party';
                    textelement(customerpartyidentification)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(customerpartyidentificationid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(customerpartyidschemeid)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if CustomerPartyIdentificationID = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(BuyerPartyIdentification2)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(BuyerRegistration)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(BuyerRegistrationschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if BuyerRegistration = '' then
                                Error('Buyer Registration cannot be blank.');
                        end;
                    }
                    textelement(BuyerPartyIdentification3)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(BuyerSST)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(BuyerSSTschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            if BuyerSST = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(customerpostaladdress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(customercityname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                        }
                        textelement(customerpostalzone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                        }
                        textelement(customercountrysubentity)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentityCode';
                            trigger OnBeforePassVariable()
                            begin
                                if CustomerCountrySubentity = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(BuyerAddressLineA)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(customerstreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if customerstreetname = '' then
                                    Error('Customer Address cannot be blank.');
                            end;
                        }
                        textelement(BuyerAddressLineB)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(customeradditionalstreetname)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if BuyerAddressLineB = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(customercountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(customeridentificationcode)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'IdentificationCode';
                                textattribute(BuyerListid)
                                {
                                    XmlName = 'listID';
                                }
                                textattribute(BuyerListAgencyID)
                                {
                                    XmlName = 'listAgencyID';
                                }
                                trigger OnBeforePassVariable()
                                begin
                                    if customeridentificationcode = '' then
                                        Error('Buyer country cannot be blank.');
                                end;
                            }
                        }
                    }
                    textelement(custpartylegalentity)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyLegalEntity';
                        textelement(custpartylegalentityregname)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';

                            trigger OnBeforePassVariable()
                            begin
                                if custpartylegalentityregname = '' then
                                    Error('Buyer Registration Name cannot be blank.');
                            end;
                        }
                    }
                    textelement(custcontact)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'Contact';
                        textelement(custcontacttelephone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Telephone';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactTelephone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(custcontactelectronicmail)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ElectronicMail';

                            trigger OnBeforePassVariable()
                            begin
                                if CustContactElectronicMail = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if (CustContactElectronicMail = '') and (CustContactTelephone = '') then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetAccountingCustomerPartyInfoByFormat(SalesHeader, CustomerPartyIdentificationID, CustomerPartyIDSchemeID);

                    InvoiceMgt.GetBuyerRegistration(SalesHeader, BuyerRegistration, BuyerRegistrationschemeID);

                    InvoiceMgt.GetBuyerSSTRegistration(SalesHeader, BuyerSST, BuyerSSTschemeID);

                    InvoiceMgt.GetAccountingCustomerPartyPostalAddr(SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone,
                                                                    CustomerCountrySubentity, CustomerIdentificationCode, DummyVar, BuyerListid, BuyerListAgencyID);

                    InvoiceMgt.GetAccountingCustomerPartyLegalEntityBIS(SalesHeader, CustPartyLegalEntityRegName);

                    InvoiceMgt.GetAccountingCustomerPartyContact(SalesHeader, CustContactTelephone, CustContactElectronicMail);
                end;
            }
            //Buyer<<
            //Delivery>>
            textelement(Delivery)
            {
                NamespacePrefix = 'cac';
                XmlName = 'Delivery';
                textelement(DeliveryParty)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'DeliveryParty';
                    textelement(DeliveryPartyIdentification)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(DeliveryPartyTIN)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(DeliveryPartyTINschemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            InvoiceMgt.GetDeliveryPartyIdentification(SalesHeader, DeliveryPartyTIN, DeliveryPartyTINschemeID);
                            if DeliveryPartyTIN = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(DeliveryPartyIdentification2)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyIdentification';
                        textelement(DeliveryPartyRegistration)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            textattribute(DeliveryPartyRegistrationSchemeID)
                            {
                                XmlName = 'schemeID';
                            }
                        }
                        trigger OnBeforePassVariable()
                        begin
                            InvoiceMgt.GetDeliveryPartyRegistration(SalesHeader, DeliveryPartyRegistration, DeliveryPartyRegistrationSchemeID);
                            if DeliveryPartyRegistration = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(DeliveryPartyPostalAddress)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PostalAddress';
                        textelement(DeliveryCityName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CityName';
                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryCityName = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryPostalZone)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'PostalZone';
                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryPostalZone = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryCountrySubentityCode)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'CountrySubentityCode';
                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryCountrySubentityCode = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryAddressLine0)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(Line0)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if Line0 = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryAddressLine1)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(Line1)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if Line1 = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryAddressLine3)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'AddressLine';
                            textelement(Line2)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Line';
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if Line2 = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(DeliveryCountry)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'Country';
                            textelement(DeliveryCountryIdentificationCode)
                            {
                                XmlName = 'IdentificationCode';
                                NamespacePrefix = 'cbc';
                                textattribute(DeliveryCountryListID)
                                {
                                    XmlName = 'listID';
                                }
                                textattribute(DeliveryCountryListAgencyID)
                                {
                                    XmlName = 'listAgencyID';
                                }
                            }
                            trigger OnBeforePassVariable()
                            begin
                                if DeliveryCountryIdentificationCode = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                    textelement(DeliveryPartyLegalEntity)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'PartyLegalEntity';
                        textelement(RegistrationName)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'RegistrationName';
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetDeliveryAddressV2(SalesHeader, DeliveryCityName, DeliveryPostalZone, DeliveryCountrySubentityCode, Line0, Line1, Line2, DeliveryCountryIdentificationCode, DeliveryCountryListID, DeliveryCountryListAgencyID, RegistrationName);
                        if RegistrationName = '' then
                            currXMLport.Skip();
                    end;
                }
                //27/02/2025>>Shipment
                textelement(Shipment)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Shipment';
                    textelement(ShipmentID)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    textelement(FreightAllowanceCharge)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'FreightAllowanceCharge';
                        textelement(ChargeIndicator)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ChargeIndicator';
                        }
                        textelement(AllowanceChargeReason)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'AllowanceChargeReason';
                        }
                        textelement(FreightAllowanceChargeAmount)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Amount';
                            textattribute(CurrencyID)
                            {
                                XmlName = 'currencyID';
                            }
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetOtherChargeInformation(SalesHeader, ShipmentID, AllowanceChargeReason, FreightAllowanceChargeAmount, CurrencyID, ChargeIndicator);
                        if FreightAllowanceChargeAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                //27/02/2025<<Shipment
            }
            //Delivery<<
            //Payment Mode>>
            textelement(PaymentMeans)
            {
                NamespacePrefix = 'cac';
                XmlName = 'PaymentMeans';
                textelement(PaymentMeansCode)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'PaymentMeansCode';
                    trigger OnBeforePassVariable()
                    begin
                        if PaymentMeansCode = '' then
                            currXMLport.Skip();
                    end;
                }
                //Supplier’s Bank Account Number>>
                textelement(PayeeFinancialAccount)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'PayeeFinancialAccount';
                    textelement(payeefinancialaccountid)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ID';
                    }
                    trigger OnBeforePassVariable()
                    begin
                        if PayeeFinancialAccountID = '' then
                            currXMLport.Skip();
                    end;
                }
                //Supplier’s Bank Account Number<<
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetPaymentMeansInfo(SalesHeader, PaymentMeansCode);
                    InvoiceMgt.GetPaymentMeansPayeeFinancialAccBIS(PayeeFinancialAccountID);
                    if (PaymentMeansCode = '') and (PayeeFinancialAccountID = '') then
                        currXMLport.Skip();
                end;
            }
            //Payment Mode<<
            //Payment Terms>>
            tableelement(pmttermsloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'PaymentTerms';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(paymenttermsnote)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'Note';
                }

                trigger OnAfterGetRecord()
                begin
                    InvoiceMgt.GetPaymentTermsInfo(SalesHeader, PaymentTermsNote);

                    if PaymentTermsNote = '' then
                        currXMLport.Skip();
                end;

                trigger OnPreXmlItem()
                begin
                    PmtTermsLoop.SetRange(Number, 1, 1);
                end;
            }
            //Payment Terms<<
            //PrePayment Amount>>
            textelement(PrepaidPayment)
            {
                XmlName = 'PrepaidPayment';
                NamespacePrefix = 'cac';
                // PrePayment Reference Number>>
                textelement(PaidID)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                // PrePayment Reference Number>>
                // PrePayment Amount>>
                textelement(PaidAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'PaidAmount';
                    textattribute(CurrencyID8)
                    {
                        XmlName = 'currencyID';
                    }
                }
                // PrePayment Amount<<
                // PrePayment Date>>
                textelement(PaidDate)
                {
                    XmlName = 'PaidDate';
                    NamespacePrefix = 'cbc';
                }
                // PrePayment Date<<
                // PrePayment Time>>
                textelement(PaidTime)
                {
                    XmlName = 'PaidTime';
                    NamespacePrefix = 'cbc';
                }
                // PrePayment Time<<
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetPrePaymentInfo(SalesHeader, PaidAmount, CurrencyID8, PaidDate, PaidTime, PaidID);
                    if (PaidAmount = '0.00') or (PaidAmount = '') then
                        currXMLport.Skip();
                end;
            }
            //PrePayment Amount<<
            //Invoice Additional Discount Amount>>
            textelement(AllowanceChargeDiscount)
            {
                XmlName = 'AllowanceCharge';
                NamespacePrefix = 'cac';
                textelement(ChargeIndicatorDiscount)
                {
                    XmlName = 'ChargeIndicator';
                    NamespacePrefix = 'cbc';
                }
                textelement(AllowanceChargeReasonDiscount)
                {
                    XmlName = 'AllowanceChargeReason';
                    NamespacePrefix = 'cbc';
                }
                textelement(Amount)
                {
                    XmlName = 'Amount';
                    NamespacePrefix = 'cbc';
                    textattribute(TaxCurrencyIDA1)
                    {
                        XmlName = 'currencyID';
                    }
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetDiscountInformation(SalesHeader, AllowanceChargeReasonDiscount, Amount, TaxCurrencyIDA1, ChargeIndicatorDiscount);
                    if Amount = '0.00' then
                        currXMLport.Skip();
                end;
            }
            //Invoice Additional Discount Amount<<
            //Invoice Additional Fee Amount>>
            textelement(AllowanceChargeFee)
            {
                XmlName = 'AllowanceCharge';
                NamespacePrefix = 'cac';
                textelement(ChargeIndicatorFee)
                {
                    XmlName = 'ChargeIndicator';
                    NamespacePrefix = 'cbc';
                }
                textelement(AllowanceChargeReasonFee)
                {
                    XmlName = 'AllowanceChargeReason';
                    NamespacePrefix = 'cbc';
                }
                textelement(AmountFee)
                {
                    XmlName = 'Amount';
                    NamespacePrefix = 'cbc';
                    textattribute(TaxCurrencyIDA2)
                    {
                        XmlName = 'currencyID';
                    }
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetFeeInformation(SalesHeader, AmountFee, TaxCurrencyIDA2, AllowanceChargeReasonFee, ChargeIndicatorFee);
                    if AmountFee = '0.00' then
                        currXMLport.Skip();
                end;
            }
            //Invoice Additional Fee Amount<<
            //Currency Exchange Rate>>
            textelement(TaxExchangeRate)
            {
                NamespacePrefix = 'cac';
                XmlName = 'TaxExchangeRate';
                textelement(SourceCurrencyCode)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'SourceCurrencyCode';
                }
                textelement(TargetCurrencyCode)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'TargetCurrencyCode';
                }
                textelement(CalculationRate)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'CalculationRate';
                }
                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetDocumentExchangeRate2(SalesHeader, SourceCurrencyCode, TargetCurrencyCode, CalculationRate);
                    if (SourceCurrencyCode = '') and (TargetCurrencyCode = '') and (CalculationRate = '') then
                        currXMLport.Skip();
                end;
            }
            //Currency Exchange Rate<< 
            //Total Tax Amount>>
            textelement(TaxTotal)
            {
                NamespacePrefix = 'cac';
                XmlName = 'TaxTotal';
                textelement(TaxAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'TaxAmount';
                    textattribute(taxtotalcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                tableelement(taxsubtotalloop; Integer)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'TaxSubtotal';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    textelement(TaxableAmount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxableAmount';
                        textattribute(taxsubtotalcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(subtotaltaxamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxAmount';
                        textattribute(taxamountcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(subtotaltaxcategory)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxCategory';
                        textelement(taxtotaltaxcategoryid)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ID';
                            trigger OnBeforePassVariable()
                            begin
                                //taxtotaltaxcategoryid := 'E'; //Aadya
                            end;
                        }
                        textelement(taxcategorypercent)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'Percent';
                        }
                        textelement(TaxExemptionReason)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'TaxExemptionReason';
                            trigger OnBeforePassVariable()
                            begin
                                if TaxExemptionReason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(taxsubtotaltaxscheme)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxScheme';
                            textelement(taxtotaltaxschemeid)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not FindNextVATAmtRec(TempVATAmtLine, TaxSubtotalLoop.Number) then begin
                            if taxsubtotalloop.Number = 1 then
                                InvoiceMgt.SetTaxSubtotalInfoZero(TempVATAmtLine, SalesHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID,
                                                             TaxTotalTaxCategoryID, TaxCategoryPercent, TaxTotalTaxSchemeID)
                            else
                                currXMLport.Break();
                        end;
                        // currXMLport.Break();

                        InvoiceMgt.GetTaxSubtotalInfo(TempVATAmtLine, SalesHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID,
                                                         TaxTotalTaxCategoryID, TaxCategoryPercent, TaxTotalTaxSchemeID);

                        InvoiceMgt.GetTaxExemptionReason(TempVATProductPostingGroup, TaxExemptionReason, TaxTotalTaxCategoryID);
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetTaxTotalInfo(SalesHeader, TempVATAmtLine, TaxAmount, TaxTotalCurrencyID);
                end;
            }
            //Total Tax Amount<<
            // textelement(Note)
            // {
            //     NamespacePrefix = 'cbc';

            //     trigger OnBeforePassVariable()
            //     begin
            //         if Note = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(TaxPointDate)
            // {
            //     NamespacePrefix = 'cbc';

            //     trigger OnBeforePassVariable()
            //     begin
            //         if TaxPointDate = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(AccountingCost)
            // {
            //     NamespacePrefix = 'cbc';

            //     trigger OnBeforePassVariable()
            //     begin
            //         if AccountingCost = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(BuyerReference)
            // {
            //     NamespacePrefix = 'cbc';

            //     trigger OnBeforePassVariable()
            //     begin
            //         BuyerReference := SalesHeader."Your Reference";
            //         if BuyerReference = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(OrderReference)
            // {
            //     NamespacePrefix = 'cac';
            //     textelement(orderreferenceid)
            //     {
            //         NamespacePrefix = 'cbc';
            //         XmlName = 'ID';
            //     }

            //     trigger OnBeforePassVariable()
            //     begin
            //         InvoiceMgt.GetOrderReferenceInfo(
            //           SalesHeader,
            //           OrderReferenceID);

            //         if OrderReferenceID = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(ContractDocumentReference)
            // {
            //     NamespacePrefix = 'cac';
            //     textelement(contractdocumentreferenceid)
            //     {
            //         NamespacePrefix = 'cbc';
            //         XmlName = 'ID';
            //     }

            //     trigger OnBeforePassVariable()
            //     var
            //         DocumentTypeCode: Text;
            //         ContractRefDocTypeCodeListID: Text;
            //         DocumentType: Text;
            //     begin
            //         InvoiceMgt.GetContractDocRefInfo(
            //           SalesHeader,
            //           ContractDocumentReferenceID,
            //           DocumentTypeCode,
            //           ContractRefDocTypeCodeListID,
            //           DocumentType);

            //         if ContractDocumentReferenceID = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // textelement(TaxRepresentativeParty)
            // {
            //     NamespacePrefix = 'cac';
            //     textelement(taxreppartypartyname)
            //     {
            //         NamespacePrefix = 'cac';
            //         XmlName = 'PartyName';
            //         textelement(taxreppartynamename)
            //         {
            //             NamespacePrefix = 'cbc';
            //             XmlName = 'Name';
            //         }
            //     }
            //     textelement(payeepartytaxscheme)
            //     {
            //         NamespacePrefix = 'cac';
            //         XmlName = 'PartyTaxScheme';
            //         textelement(payeepartytaxschemecompanyid)
            //         {
            //             NamespacePrefix = 'cbc';
            //             XmlName = 'CompanyID';
            //             textattribute(payeepartytaxschcompidschemeid)
            //             {
            //                 XmlName = 'schemeID';
            //             }
            //         }
            //         textelement(payeepartytaxschemetaxscheme)
            //         {
            //             NamespacePrefix = 'cac';
            //             XmlName = 'TaxScheme';
            //             textelement(payeepartytaxschemetaxschemeid)
            //             {
            //                 NamespacePrefix = 'cbc';
            //                 XmlName = 'ID';
            //             }
            //         }

            //         trigger OnBeforePassVariable()
            //         begin
            //             if PayeePartyTaxScheme = '' then
            //                 currXMLport.Skip();
            //         end;
            //     }

            //     trigger OnBeforePassVariable()
            //     begin
            //         InvoiceMgt.GetTaxRepresentativePartyInfo(
            //           TaxRepPartyNameName,
            //           PayeePartyTaxSchemeCompanyID,
            //           PayeePartyTaxSchCompIDSchemeID,
            //           PayeePartyTaxSchemeTaxSchemeID);

            //         if TaxRepPartyPartyName = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            // tableelement(allowancechargeloop; Integer)
            // {
            //     NamespacePrefix = 'cac';
            //     XmlName = 'AllowanceCharge';
            //     SourceTableView = sorting(Number) where(Number = filter(1 ..));
            //     textelement(ChargeIndicator)
            //     {
            //         NamespacePrefix = 'cbc';
            //         XmlName = 'ChargeIndicator';
            //     }
            //     textelement(AllowanceChargeReasonCode)
            //     {
            //         NamespacePrefix = 'cbc';
            //         XmlName = 'AllowanceChargeReason';
            //     }
            //     textelement(AllowanceChargeReason)
            //     {
            //         NamespacePrefix = 'cbc';
            //     }
            //     textelement(Amount)
            //     {
            //         NamespacePrefix = 'cbc';
            //         textattribute(allowancechargecurrencyid)
            //         {
            //             XmlName = 'currencyID';
            //         }
            //     }
            //     textelement(TaxCategory)
            //     {
            //         NamespacePrefix = 'cac';
            //         textelement(taxcategoryid)
            //         {
            //             NamespacePrefix = 'cbc';
            //             XmlName = 'ID';
            //         }
            //         textelement(Percent)
            //         {
            //             NamespacePrefix = 'cbc';

            //             trigger OnBeforePassVariable()
            //             begin
            //                 if Percent = '' then
            //                     currXMLport.Skip();
            //             end;
            //         }
            //         textelement(TaxScheme)
            //         {
            //             NamespacePrefix = 'cac';
            //             textelement(allowancechargetaxschemeid)
            //             {
            //                 NamespacePrefix = 'cbc';
            //                 XmlName = 'ID';
            //             }
            //         }
            //     }

            //     trigger OnAfterGetRecord()
            //     begin
            //         if not FindNextVATAmtRec(TempVATAmtLine, AllowanceChargeLoop.Number) then
            //             currXMLport.Break();

            //         InvoiceMgt.GetAllowanceChargeInfo(
            //           TempVATAmtLine,
            //           SalesHeader,
            //           ChargeIndicator,
            //           AllowanceChargeReasonCode,
            //           DummyVar,
            //           AllowanceChargeReason,
            //           Amount,
            //           AllowanceChargeCurrencyID,
            //           TaxCategoryID,
            //           DummyVar,
            //           Percent,
            //           AllowanceChargeTaxSchemeID);

            //         if ChargeIndicator = '' then
            //             currXMLport.Skip();
            //     end;
            // }

            // textelement(taxtotallcy)
            // {
            //     NamespacePrefix = 'cac';
            //     XmlName = 'TaxTotal';
            //     textelement(taxamountlcy)
            //     {
            //         NamespacePrefix = 'cbc';
            //         XmlName = 'TaxAmount';
            //         textattribute(taxtotalcurrencyidlcy)
            //         {
            //             XmlName = 'currencyID';
            //         }
            //     }
            //     trigger OnBeforePassVariable()
            //     begin
            //         if TaxTotalCurrencyIDLCY = '' then
            //             currXMLport.Skip();
            //     end;
            // }
            //LegalMonetaryTotal// Total Excluding Tax>>
            textelement(LegalMonetaryTotal)
            {
                NamespacePrefix = 'cac';
                XmlName = 'LegalMonetaryTotal';
                textelement(LineExtensionAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'LineExtensionAmount';
                    textattribute(legalmonetarytotalcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(TaxExclusiveAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'TaxExclusiveAmount';
                    textattribute(taxexclusiveamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(TaxInclusiveAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'TaxInclusiveAmount';
                    textattribute(taxinclusiveamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                textelement(AllowanceTotalAmount)
                {
                    XmlName = 'AllowanceTotalAmount';
                    NamespacePrefix = 'cbc';
                    textattribute(allowancetotalamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if AllowanceTotalAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(ChargeTotalAmount)
                {
                    XmlName = 'ChargeTotalAmount';
                    NamespacePrefix = 'cbc';
                    textattribute(chargetotalamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if ChargeTotalAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                // textelement(PrepaidAmount)
                // {
                //     NamespacePrefix = 'cbc';
                //     textattribute(prepaidcurrencyid)
                //     {
                //         XmlName = 'currencyID';
                //     }
                // }
                textelement(PayableRoundingAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'PayableRoundingAmount';
                    textattribute(payablerndingamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PayableRoundingAmount = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(PayableAmount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'PayableAmount';
                    textattribute(payableamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }

                trigger OnBeforePassVariable()
                begin
                    InvoiceMgt.GetLegalMonetaryInfo(SalesHeader, TempSalesLineRounding, TempVATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount,
                    TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID,
                      ChargeTotalAmount, ChargeTotalAmountCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);
                end;
            }
            //LegalMonetaryTotal// Total Excluding Tax<<
            tableelement(invoicelineloop; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'InvoiceLine';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(invoicelineid)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'ID';
                }
                // textelement(invoicelinenote)
                // {
                //     NamespacePrefix = 'cbc';
                //     XmlName = 'Note';
                //     trigger OnBeforePassVariable()
                //     begin
                //         if InvoiceLineNote = '' then
                //             currXMLport.Skip();
                //     end;
                // }
                //Quantity>>
                textelement(InvoicedQuantity)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'InvoicedQuantity';
                    //Measurement>>
                    textattribute(unitCode)
                    {
                        XmlName = 'unitCode';
                    }
                    //Measurement<<
                }
                //Quantity<<
                //Total Excluding Tax>>
                textelement(invoicelineextensionamount)
                {
                    NamespacePrefix = 'cbc';
                    XmlName = 'LineExtensionAmount';
                    textattribute(lineextensionamountcurrencyid)
                    {
                        XmlName = 'currencyID';
                    }
                }
                //Total Excluding Tax<
                //Discount Rate>>
                tableelement(invlnallowancechargeloop; Integer)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'AllowanceCharge';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    textelement(invlnallowancechargeindicator)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ChargeIndicator';
                    }
                    textelement(invlnallowancechargereason)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'AllowanceChargeReason';
                    }
                    textelement(LineMultiplierFactorNumeric)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'MultiplierFactorNumeric';
                    }
                    textelement(invlnallowancechargeamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Amount';
                        textattribute(invlnallowancechargeamtcurrid)
                        {
                            XmlName = 'currencyID';
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        InvoiceMgt.GetLineAllowanceChargeInfo(SalesLine, SalesHeader, InvLnAllowanceChargeIndicator, InvLnAllowanceChargeReason,
                            InvLnAllowanceChargeAmount, InvLnAllowanceChargeAmtCurrID, LineMultiplierFactorNumeric);

                        if InvLnAllowanceChargeIndicator = '' then
                            currXMLport.Skip();
                    end;

                    trigger OnPreXmlItem()
                    begin
                        InvLnAllowanceChargeLoop.SetRange(Number, 1, 1);
                    end;
                }
                //Discount Rate<<
                //Fee / Charge Rate>>
                textelement(LineAllowanceCharge2)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'AllowanceCharge';
                    textelement(LineChargeIndicator2)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'ChargeIndicator';
                    }
                    textelement(AllowanceChargeReason2)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'AllowanceChargeReason';
                    }
                    textelement(LineMultiplierFactorNumeric2)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'MultiplierFactorNumeric';
                    }
                    textelement(LineAmount3)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Amount';
                        textattribute(currencyId7)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        LineChargeIndicator2 := 'true';
                        LineAmount3 := '';
                        AllowanceChargeReason2 := 'Fee';
                        currencyId7 := '';
                        LineMultiplierFactorNumeric2 := '';
                        if LineAmount3 = '' then
                            currXMLport.Skip();
                    end;
                }
                //Fee / Charge Rate<<
                //TaxRate>>
                textelement(LineTaxTotal2)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'TaxTotal';
                    textelement(LineTaxAmout)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'TaxAmount';
                        textattribute(LinecurrencyId7)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    textelement(TaxSubtotalLine3)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'TaxSubtotal';
                        textelement(LineTaxableAmount)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'TaxableAmount';
                            textattribute(LinecurrencyId3)
                            {
                                XmlName = 'currencyID';
                            }
                        }
                        textelement(LineTaxAmount2)
                        {
                            XmlName = 'TaxAmount';
                            NamespacePrefix = 'cbc';
                            textattribute(currencyId11)
                            {
                                XmlName = 'currencyID';
                            }
                        }
                        textelement(TaxCategoryLine)
                        {
                            NamespacePrefix = 'cac';
                            XmlName = 'TaxCategory';
                            textelement(TaxCategoryID)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'ID';
                            }
                            textelement(Percent)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'Percent';
                            }
                            textelement(LineTaxExemptionReason)
                            {
                                NamespacePrefix = 'cbc';
                                XmlName = 'TaxExemptionReason';
                                //Revise-v10>>
                                trigger OnBeforePassVariable()
                                begin
                                    if LineTaxExemptionReason = '' then
                                        currXMLport.Skip();
                                end;
                                //Revise-v10>>
                            }
                            textelement(TaxScheme)
                            {
                                NamespacePrefix = 'cac';
                                XmlName = 'TaxScheme';
                                textelement(TaxSchemeID2)
                                {
                                    NamespacePrefix = 'cbc';
                                    XmlName = 'ID';
                                    textattribute(schemeID)
                                    {
                                        XmlName = 'schemeID';
                                    }
                                    textattribute(schemeAgencyID)
                                    {
                                        XmlName = 'schemeAgencyID';
                                    }
                                }
                            }
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetLineTaxInformation(SalesHeader, SalesLine, LineTaxAmout, LinecurrencyId7, LineTaxableAmount, LinecurrencyId3, LineTaxAmount2
                        , CurrencyID11, TaxCategoryID, Percent, LineTaxExemptionReason, schemeID, schemeAgencyID, TaxSchemeID2);
                    end;
                }
                //TaxRate>>
                textelement(Item)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Item';
                    //Description>>
                    textelement(Description)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Description';
                        trigger OnBeforePassVariable()
                        begin
                            if Description = '' then
                                Error('Line Description is mandatory.');
                        end;
                    }
                    //Description<<
                    //Country of Origin>>
                    textelement(OriginCountry)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'OriginCountry';
                        textelement(origincountryidcode)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'IdentificationCode';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if OriginCountryIdCode = '' then
                                currXMLport.Skip();
                        end;
                    }
                    //Country of Origin<<
                    //Product Tariff Code>>
                    tableelement(commodityclassificationloop; Integer)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'CommodityClassification';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        textelement(ItemClassificationCode)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ItemClassificationCode';
                            textattribute(itemclassificationcodelistid)
                            {
                                XmlName = 'listID';
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if ItemClassificationCode = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            InvoiceMgt.GetLineItemCommodityClassficationInfo(SalesLine, ItemClassificationCode, ItemClassificationCodeListID);

                            if ItemClassificationCode = '' then
                                currXMLport.Skip();
                        end;

                        trigger OnPreXmlItem()
                        begin
                            CommodityClassificationLoop.SetRange(Number, 1, 1);
                        end;
                    }
                    //Product Tariff Code<<
                    //Classification>>
                    tableelement(commodityclassificationloop2; Integer)
                    {
                        NamespacePrefix = 'cac';
                        XmlName = 'CommodityClassification';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        textelement(ItemClassificationCode2)
                        {
                            NamespacePrefix = 'cbc';
                            XmlName = 'ItemClassificationCode';
                            textattribute(itemclassificationcodelistid2)
                            {
                                XmlName = 'listID';
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if ItemClassificationCode2 = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            InvoiceMgt.GetLineItemCommodityClassficationInfo2(SalesLine, ItemClassificationCode2, itemclassificationcodelistid2);

                            if ItemClassificationCode2 = '' then//Revise-v10>>
                                currXMLport.Skip();
                        end;

                        trigger OnPreXmlItem()
                        begin
                            CommodityClassificationLoop2.SetRange(Number, 1, 1);
                        end;
                    }
                    //Classification<<

                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetLineItemInfo(SalesLine, Description, OriginCountryIdCode);
                    end;
                }
                textelement(invoicelineprice)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'Price';
                    textelement(invoicelinepriceamount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'PriceAmount';
                        textattribute(invlinepriceamountcurrencyid)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    trigger OnBeforePassVariable()
                    begin
                        InvoiceMgt.GetLinePriceInfo(SalesLine, SalesHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID);
                    end;
                }
                //Subtotal>>
                textelement(LineItemPriceExtension)
                {
                    NamespacePrefix = 'cac';
                    XmlName = 'ItemPriceExtension';
                    textelement(LineAmount)
                    {
                        NamespacePrefix = 'cbc';
                        XmlName = 'Amount';
                        textattribute(currencyId4)
                        {
                            XmlName = 'currencyID';
                        }
                        trigger OnBeforePassVariable()
                        begin
                            InvoiceMgt.GetLineItemPriceExtension(SalesLine, SalesHeader, LineAmount, currencyId4);
                        end;
                    }
                }
                //Subtotal<<
                trigger OnAfterGetRecord()
                var
                    Skip: Boolean;
                begin
                    if not FindNextInvoiceLineRec(InvoiceLineLoop.Number, Skip) then
                        currXMLport.Break();
                    //27/02/2025>>
                    if Skip then
                        currXMLport.Skip();
                    //27/02/2025<<
                    InvoiceMgt.GetLineGeneralInfo(SalesLine, SalesHeader, InvoiceLineID,
                      InvoicedQuantity, InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID);

                    InvoiceMgt.GetLineUnitCodeInfo(SalesLine, unitCode);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not FindNextInvoiceRec(InvoiceHeaderLoop.Number) then
                    currXMLport.Break();
                GetTotals();
                InvoiceMgt.GetGeneralInfoBIS(SalesHeader, ID, IssueDate,
                  InvoiceTypeCode, DocumentCurrencyCode, IssueTime, InvoiceTypecodeListID);
            end;
        }
    }

    var
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        TempReferenceDetails: Record "Reference Details MY01-IBIZ" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCMHeader: Record "Sales Cr.Memo Header";
        SalesCMLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary;
        TempSalesLineRounding: Record "Sales Line" temporary;
        InvoiceMgt: Codeunit "Sales Management 1.0 MY01-IBIZ";
        DummyVar: Text;
        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        ProcessedDocType: Option Invoice,CM;

    local procedure GetTotals()
    begin
        case ProcessedDocType of
            ProcessedDocType::Invoice:
                begin
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesInvoiceLine);
                            SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                            InvoiceMgt.GetTotals(SalesLine, TempVATAmtLine);
                            InvoiceMgt.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesInvoiceLine.Next() = 0;
                end;
            ProcessedDocType::CM:
                begin
                    SalesCMLine.SetRange("Document No.", SalesCMHeader."No.");
                    if SalesCMLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesCMLine);
                            SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                            InvoiceMgt.GetTotals(SalesLine, TempVATAmtLine);
                            InvoiceMgt.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesCMLine.Next() = 0;
                end;
        end;
    end;

    local procedure FindNextInvoiceRec(Position: Integer): Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Invoice:
                begin
                    exit(InvoiceMgt.FindNextInvoiceRec(SalesInvoiceHeader, SalesHeader, ProcessedDocType, Position));
                end;
            ProcessedDocType::CM:
                begin
                    exit(InvoiceMgt.FindNextCreditMemoRec(SalesCMHeader, SalesHeader, ProcessedDocType, Position));
                end;
        end;
    end;

    local procedure FindNextInvoiceLineRec(Position: Integer; var Skip: Boolean): Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Invoice:
                begin
                    exit(InvoiceMgt.FindNextInvoiceLineRec(SalesInvoiceLine, SalesLine, ProcessedDocType, Position, Skip));
                end;
            ProcessedDocType::CM:
                begin
                    exit(InvoiceMgt.FindNextCreditMemoLineRec(SalesCMLine, SalesLine, ProcessedDocType, Position, Skip));
                end;
        end;
    end;

    local procedure FindNextReferenceRec(var lReferenceDetails: Record "Reference Details MY01-IBIZ"; Position: Integer): Boolean
    // var
    //     Found: Boolean;
    begin
        if Position = 1 then
            exit(lReferenceDetails.Find('-'));
        exit(lReferenceDetails.Next() <> 0);
        // if Position = 1 then
        //     Found := lReferenceDetails.Find('-')
        // else
        //     Found := lReferenceDetails.Next() <> 0;
        // exit(Found);
    end;

    local procedure FindNextVATAmtRec(var VATAmtLine: Record "VAT Amount Line"; Position: Integer): Boolean
    begin
        if Position = 1 then
            exit(VATAmtLine.Find('-'));
        exit(VATAmtLine.Next() <> 0);
    end;

    procedure Initialize(DocVariant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocVariant);
        case RecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    if SalesInvoiceHeader."No." = '' then
                        Error(SpecifyASalesInvoiceNoErr);
                    SalesInvoiceHeader.SetRecFilter();
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
                    SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesInvoiceLine);
                            SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                            InvoiceMgt.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until SalesInvoiceLine.Next() = 0;
                    if TempSalesLineRounding."Line No." <> 0 then
                        SalesInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

                    ProcessedDocType := ProcessedDocType::Invoice;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCMHeader);
                    if SalesCMHeader."No." = '' then
                        Error(SpecifyASalesInvoiceNoErr);
                    SalesCMHeader.SetRecFilter();
                    SalesCMLine.SetRange("Document No.", SalesCMHeader."No.");
                    SalesCMLine.SetFilter(Type, '<>%1', SalesCMLine.Type::" ");
                    SalesCMLine.SetFilter(Quantity, '<>%1', 0);
                    if SalesCMLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesCMLine);
                            SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                            InvoiceMgt.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until SalesCMLine.Next() = 0;
                    if TempSalesLineRounding."Line No." <> 0 then
                        SalesCMLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

                    ProcessedDocType := ProcessedDocType::CM;
                end;
            else
                Error(UnSupportedTableTypeErr, RecRef.Number);
        end;
    end;
}

