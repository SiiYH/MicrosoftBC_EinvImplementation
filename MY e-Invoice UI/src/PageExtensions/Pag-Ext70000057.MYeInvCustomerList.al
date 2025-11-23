pageextension 70000057 "MY eInv Customer List" extends "Customer List"
{
    layout
    {
        addafter(Name)
        {
            field("MY eInv Entity Type"; Rec."MY eInv Entity Type")
            {
                ApplicationArea = All;
                ToolTip = 'Customer entity type.';
                Visible = false;
            }

            field("MY eInv TIN"; Rec."MY eInv TIN")
            {
                ApplicationArea = All;
                ToolTip = 'Tax Identification Number.';
                Visible = false;
            }

            field("MY eInv Use General TIN"; Rec."MY eInv Use General TIN")
            {
                ApplicationArea = All;
                ToolTip = 'Using General TIN.';
                Visible = false;
            }

            field("MY eInv State Code"; Rec."MY eInv State Code")
            {
                ApplicationArea = All;
                ToolTip = 'State code.';
                Visible = false;
            }
        }
    }

    actions
    {
        addfirst(processing)
        {
            action(ValidateEInvoiceSetup)
            {
                Caption = 'Validate E-Invoice Setup';
                ApplicationArea = All;
                Image = Validate;
                ToolTip = 'Validate that selected customers are configured for e-invoicing.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                    ValidationErrors: Text;
                    ErrorCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Customer);
                    if Customer.FindSet() then
                        repeat
                            if not TryValidateCustomer(Customer) then begin
                                ValidationErrors += Customer."No." + ': ' + GetLastErrorText() + '\';
                                ErrorCount += 1;
                            end;
                        until Customer.Next() = 0;

                    if ErrorCount = 0 then
                        Message('✓ All selected customers are properly configured for e-invoicing.')
                    else
                        Message('Found %1 customer(s) with configuration issues:\%2', ErrorCount, ValidationErrors);
                end;
            }
        }
    }

    [TryFunction]
    local procedure TryValidateCustomer(Customer: Record Customer)
    begin
        Customer.ValidateForEInvoice();
    end;
}
