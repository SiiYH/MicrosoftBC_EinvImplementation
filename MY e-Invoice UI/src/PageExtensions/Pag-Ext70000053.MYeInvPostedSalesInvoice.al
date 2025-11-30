pageextension 70000053 "MY eInv Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("No.")
        {
            field("MY eInv Type Code"; Rec."MY eInv Type Code")
            {
                ApplicationArea = All;
                ToolTip = 'E-Invoice type code from LHDN reference table.';
            }

            field("MY eInv Type Description"; Rec."MY eInv Type Description")
            {
                ApplicationArea = All;
                ToolTip = 'E-Invoice type description.';
            }
        }

        addlast(General)
        {
            group("E-Invoice Status")
            {
                Caption = 'E-Invoice Status';
                Visible = ShowEInvoiceStatus;

                field("MY eInv Submitted"; Rec."MY eInv Submitted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates if this invoice has been submitted to MyInvois.';
                    // StyleExpr = SubmittedStyleExpr;
                }

                field("MY eInv Status"; Rec."MY eInv Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Current status in MyInvois system.';
                    StyleExpr = StatusStyleExpr;
                }
                group(Submmited)
                {
                    field("MY eInv Submission UID"; Rec."MY eInv Submission UID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Unique Identifier Number (UIN) from MyInvois.';

                        trigger OnDrillDown()
                        begin
                            if Rec."MY eInv Validation URL" <> '' then
                                Hyperlink(Rec."MY eInv Validation URL");
                        end;
                    }
                    field("MY eInv Document UUID"; Rec."MY eInv Document UUID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Document UUID field.', Comment = '%';
                    }
                    field("MY eInv Submission Date"; Rec."MY eInv Submission Date")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Date when the invoice was submitted to MyInvois.';
                    }
                }
                group(Validated)
                {
                    Visible = Rec."MY eInv Status" = Rec."MY eInv Status"::Valid;
                    field("MY eInv IRBM Unique ID"; Rec."MY eInv IRBM Unique ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the IRBM Unique ID field.', Comment = '%';
                    }
                    field("MY eInv Long ID"; Rec."MY eInv Long ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the MY eInv Long ID field.', Comment = '%';
                    }
                    field("MY eInv Validation Date"; Rec."MY eInv Validation Date")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Validation Date/Time field.', Comment = '%';
                    }
                }
                field("MY eInv Document Hash"; Rec."MY eInv Document Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'SHA-256 hash of the submitted document.';
                    Visible = false;
                }

                field("MY eInv Validation URL"; Rec."MY eInv Validation URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'URL to validate the e-invoice on MyInvois portal.';
                    ExtendedDatatype = URL;
                }

                field("E-Invoice Format Info"; EInvoiceFormatInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Format';
                    ToolTip = 'E-Invoice was submitted in XML (UBL 2.1) format.';
                    Editable = false;
                    StyleExpr = 'Subordinate';
                }
                field("MY eInv Cancelled"; Rec."MY eInv Cancelled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MY eInv Cancelled field.', Comment = '%';
                }
                field("MY eInv Error Message"; Rec."MY eInv Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MY eInv Error Message field.', Comment = '%';
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        addafter(Print)
        {
            group("E-Invoice")
            {
                Caption = 'E-Invoice';
                Image = ElectronicDoc;
                action(EditEInvoiceInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Edit eInvoice Information';
                    Image = Edit;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Edit eInvoice classification codes and LHDN UOM for posted invoice lines';
                    Enabled = not ((Rec."MY eInv Status" = Enum::"MY eInv Status"::Submitted) or (Rec."MY eInv Status" = Enum::"MY eInv Status"::Valid)); // Only allow edit if not yet submitted

                    trigger OnAction()
                    var
                        EInvoiceEdit: Page "MY eInv Posted Invoice Edit";
                    begin
                        EInvoiceEdit.SetRecord(Rec);
                        EInvoiceEdit.RunModal();
                        CurrPage.Update(false);
                    end;
                }

                action(SubmitToMyInvois)
                {
                    Caption = 'Submit to MyInvois';
                    ApplicationArea = All;
                    Image = SendTo;
                    ToolTip = 'Submit this invoice to MyInvois system in XML format (UBL 2.1).';
                    // Enabled = not Rec."MY eInv Submitted";
                    Enabled = not ((Rec."MY eInv Status" = Enum::"MY eInv Status"::Submitted) or (Rec."MY eInv Status" = Enum::"MY eInv Status"::Valid)); // Only allow edit if not yet submitted
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        ConfirmQst: Label 'Submit invoice %1 to MyInvois?\The invoice will be sent as XML (UBL 2.1) format.';
                    begin
                        if not Confirm(ConfirmQst, false, Rec."No.") then
                            exit;

                        Rec.SubmitToMyInvois();
                        CurrPage.Update();
                    end;
                }

                action(CheckMyInvoisStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Check MyInvois Status';
                    Image = Status;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Check if document has been validated and retrieve IRBM Unique ID';
                    Enabled = Rec."MY eInv Document UUID" <> '';

                    trigger OnAction()
                    var
                        Submission: Codeunit "MY eInv Submission";
                        StatusMsg: Text;
                        Window: Dialog;
                    begin
                        // Check if already validated
                        if Rec."MY eInv IRBM Unique ID" <> '' then begin
                            Message('This document is already validated.\IRBM Unique ID: %1\Validation Date: %2',
                                    Rec."MY eInv IRBM Unique ID",
                                    Rec."MY eInv Validation Date");
                            exit;
                        end;

                        // Check if submitted
                        if Rec."MY eInv Document UUID" = '' then
                            Error('This document has not been submitted to MyInvois yet.');

                        // Show processing message
                        Window.Open('Checking document status with MyInvois...');

                        // Get document details
                        if Submission.GetDocumentDetails(Rec) then begin
                            Window.Close();
                            CurrPage.Update(false);
                            Message('Document validated successfully!\IRBM Unique ID: %1\You can now print the invoice.',
                                    Rec."MY eInv IRBM Unique ID");
                        end else begin
                            Window.Close();
                            CurrPage.Update(false);

                            // Get detailed status/error message
                            StatusMsg := Submission.GetLastErrorMessage();

                            // Show message based on actual status
                            case Rec."MY eInv Status" of
                                "MY eInv Status"::Invalid:
                                    Message('Document validation FAILED!\%1', StatusMsg);

                                "MY eInv Status"::Submitted:
                                    Message('Document is still being validated.\Status: %1\Please check again in a few moments.', Rec."MY eInv Status");

                                else
                                    Message('Status: %1\%2', Rec."MY eInv Status", StatusMsg);
                            end;
                        end;
                    end;
                }

                action(CancelInMyInvois)
                {
                    Caption = 'Cancel in MyInvois';
                    ApplicationArea = All;
                    Image = Cancel;
                    ToolTip = 'Cancel this invoice in MyInvois system (within 72-hour window).';
                    Enabled = Rec."MY eInv Submitted" and not Rec."MY eInv Cancelled";

                    trigger OnAction()
                    var
                        ConfirmQst: Label 'Cancel invoice %1 in MyInvois?\This action cannot be undone.\You have 72 hours from validation to cancel.';
                    begin
                        if not Confirm(ConfirmQst, false, Rec."No.") then
                            exit;

                        Rec.CancelInMyInvois();
                        CurrPage.Update();
                    end;
                }

                action(ShowSubmissionLog)
                {
                    Caption = 'Submission Log';
                    ApplicationArea = All;
                    Image = Log;
                    ToolTip = 'View complete submission history and details for this invoice.';

                    trigger OnAction()
                    begin
                        Rec.ShowSubmissionLog();
                    end;
                }

                action(DownloadXML)
                {
                    Caption = 'Download XML';
                    ApplicationArea = All;
                    Image = XMLFile;
                    ToolTip = 'Download the UBL 2.1 XML document that was submitted.';
                    // Enabled = Rec."MY eInv Submitted";

                    trigger OnAction()
                    var
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                        XMLGenerator: Codeunit "MY eInv XML Generator 02";
                        TempBlob: Codeunit "Temp Blob";
                        InStr: InStream;
                        OutStr: OutStream;
                        XMLText: Text;
                        FileName: Text;
                    begin
                        SalesInvoiceHeader := Rec;

                        // Generate XML
                        XMLText := XMLGenerator.GenerateInvoiceXML(SalesInvoiceHeader);

                        // Create file name
                        FileName := SalesInvoiceHeader."No." + '_eInvoice.xml';

                        // Write to TempBlob
                        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
                        OutStr.WriteText(XMLText);

                        // Download file
                        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
                        DownloadFromStream(InStr, 'Download XML', '', 'XML Files (*.xml)|*.xml', FileName);
                        // DownloadSubmittedXML();
                    end;
                }

                action(ViewOnMyInvoisPortal)
                {
                    Caption = 'View on MyInvois Portal';
                    ApplicationArea = All;
                    Image = Web;
                    ToolTip = 'Open this invoice on the MyInvois portal.';
                    Enabled = Rec."MY eInv Submitted";

                    trigger OnAction()
                    begin
                        if Rec."MY eInv Validation URL" <> '' then
                            Hyperlink(Rec."MY eInv Validation URL")
                        else
                            Hyperlink('https://myinvois.hasil.gov.my');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
        UpdateEInvoiceInfo();
    end;

    local procedure SetStyles()
    begin
        if Rec."MY eInv Submitted" then
            SubmittedStyleExpr := 'Favorable'
        else
            SubmittedStyleExpr := 'Standard';

        case Rec."MY eInv Status" of
            Rec."MY eInv Status"::Valid:
                StatusStyleExpr := 'Favorable';
            Rec."MY eInv Status"::Invalid,
            Rec."MY eInv Status"::Rejected:
                StatusStyleExpr := 'Unfavorable';
            Rec."MY eInv Status"::Cancelled:
                StatusStyleExpr := 'Subordinate';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;

    local procedure UpdateEInvoiceInfo()
    var
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";
    begin
        ShowEInvoiceStatus := MYeInvFeaMgmt.IsEInvoiceEnabled();
        EInvoiceFormatInfo := 'XML (UBL 2.1)';
    end;

    local procedure DownloadSubmittedXML()
    var
        SubmissionLog: Record "MY eInv Submission Log";
    begin
        SubmissionLog.SetFilter("Document Type", '%1|%2', '01', '03');
        SubmissionLog.SetRange("Document No.", Rec."No.");
        if SubmissionLog.FindLast() then
            SubmissionLog.DownloadSignedXML()
        else
            Message('No XML document found in submission log.');
    end;

    local procedure DownloadQRCode()
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FileName: Text;
    begin
        Rec.CalcFields("MY eInv QR Code");
        if not Rec."MY eInv QR Code".HasValue then begin
            Message('No QR code available for this invoice.');
            exit;
        end;

        Rec."MY eInv QR Code".CreateInStream(InStream);
        FileName := StrSubstNo('QRCode_%1.png', Rec."No.");
        DownloadFromStream(InStream, 'Download QR Code', '', 'PNG Files (*.png)|*.png', FileName);
    end;

    var
        ShowEInvoiceStatus: Boolean;
        SubmittedStyleExpr: Text;
        StatusStyleExpr: Text;
        EInvoiceFormatInfo: Text;
        QRCodeText: Text;
}
