namespace MYeInvoiceCore.MYeInvoiceCore;
/// <summary>
/// LHDN Document Type Codes (as per LHDN specification)
/// </summary>
enum 7000003 "LHDN Document Type Code EINV"
{
    Extensible = false;

    value(1; "01")
    {
        Caption = '01 - Invoice';
    }
    value(2; "02")
    {
        Caption = '02 - Credit Note';
    }
    value(3; "03")
    {
        Caption = '03 - Debit Note';
    }
    value(4; "04")
    {
        Caption = '04 - Refund Note';
    }
    value(11; "11")
    {
        Caption = '11 - Self-billed Invoice';
    }
    value(12; "12")
    {
        Caption = '12 - Self-billed Credit Note';
    }
    value(13; "13")
    {
        Caption = '13 - Self-billed Debit Note';
    }
    value(14; "14")
    {
        Caption = '14 - Self-billed Refund Note';
    }

}
