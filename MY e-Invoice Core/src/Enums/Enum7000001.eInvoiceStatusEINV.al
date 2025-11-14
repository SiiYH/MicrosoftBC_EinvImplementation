namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000001 "e-Invoice Status EINV"
{
    Extensible = true; // Allow UI app to add display-only statuses if needed

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Pending)
    {
        Caption = 'Pending';
    }
    value(2; Submitted)
    {
        Caption = 'Submitted';
    }
    value(3; Valid)
    {
        Caption = 'Valid';
    }
    value(4; Invalid)
    {
        Caption = 'Invalid';
    }
    value(5; Rejected)
    {
        Caption = 'Rejected';
    }
    value(6; Cancelled)
    {
        Caption = 'Cancelled';
    }
    value(7; Error)
    {
        Caption = 'Error';
    }
}
