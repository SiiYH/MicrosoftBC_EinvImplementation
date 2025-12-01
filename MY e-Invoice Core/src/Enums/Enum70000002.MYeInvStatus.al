enum 70000002 "MY eInv Status"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Submitted)
    {
        Caption = 'Submitted';
    }
    value(2; Valid)
    {
        Caption = 'Valid';
    }
    value(3; Invalid)
    {
        Caption = 'Invalid';
    }
    value(4; Cancelled)
    {
        Caption = 'Cancelled';
    }
    value(5; Rejected)
    {
        Caption = 'Rejected';
    }
    //more detail of cancellation
    value(7; "Cancellation Failed") { Caption = 'Cancellation Failed'; }
    value(8; Error) { Caption = 'Error'; }
}
