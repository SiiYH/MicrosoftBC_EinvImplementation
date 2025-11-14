namespace MYeInvoiceCore.MYeInvoiceCore;


/// <summary>
/// Document Type for e-Invoice
/// </summary>
enum 7000002 "Document Type EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Sales Invoice")
    {
        Caption = 'Sales Invoice';
    }
    value(2; "Sales Credit Memo")
    {
        Caption = 'Sales Credit Memo';
    }
    value(3; "Sales Debit Note")
    {
        Caption = 'Sales Debit Note';
    }
    value(4; "Sales Refund Note")
    {
        Caption = 'Sales Refund Note';
    }
    value(11; "Purchase Invoice")
    {
        Caption = 'Purchase Invoice';
    }
    value(12; "Purchase Credit Memo")
    {
        Caption = 'Purchase Credit Memo';
    }
    value(13; "Purchase Debit Note")
    {
        Caption = 'Purchase Debit Note';
    }
    value(14; "Purchase Refund Note")
    {
        Caption = 'Purchase Refund Note';
    }

}
