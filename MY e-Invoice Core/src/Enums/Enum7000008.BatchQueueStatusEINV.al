namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000008 "Batch Queue Status EINV"
{
    Extensible = false;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Processing)
    {
        Caption = 'Processing';
    }
    value(2; Submitted)
    {
        Caption = 'Submitted';
    }
    value(3; Completed)
    {
        Caption = 'Completed';
    }
    value(4; Failed)
    {
        Caption = 'Failed';
    }
    value(5; Cancelled)
    {
        Caption = 'Cancelled';
    }

}
