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
                    StyleExpr = SubmittedStyleExpr;
                }

                field("MY eInv Status"; Rec."MY eInv Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Current status in MyInvois system.';
                    StyleExpr = StatusStyleExpr;
                }

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

                field("MY eInv Submission Date"; Rec."MY eInv Submission Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date when the invoice was submitted to MyInvois.';
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

                action(SubmitToMyInvois)
                {
                    Caption = 'Submit to MyInvois';
                    ApplicationArea = All;
                    Image = SendTo;
                    ToolTip = 'Submit this invoice to MyInvois system in XML format (UBL 2.1).';
                    Enabled = not Rec."MY eInv Submitted";
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

                action(CheckStatus)
                {
                    Caption = 'Check Status from MyInvois';
                    ApplicationArea = All;
                    Image = Status;
                    ToolTip = 'Check the current status of this e-invoice from MyInvois API.';
                    Enabled = Rec."MY eInv Submitted";
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        Rec.CheckStatusFromAPI();
                        CurrPage.Update();
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
                    Enabled = Rec."MY eInv Submitted";

                    trigger OnAction()
                    begin
                        DownloadSubmittedXML();
                    end;
                }

                action(DownloadQRCode)
                {
                    Caption = 'Download QR Code';
                    ApplicationArea = All;
                    Image = QRCode;
                    ToolTip = 'Download the QR code for this e-invoice (for sharing with buyer).';
                    Enabled = Rec."MY eInv Submitted";

                    trigger OnAction()
                    begin
                        DownloadQRCode();
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
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ShowEInvoiceStatus := CompanyInfo."MY eInv Enabled";
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
}
