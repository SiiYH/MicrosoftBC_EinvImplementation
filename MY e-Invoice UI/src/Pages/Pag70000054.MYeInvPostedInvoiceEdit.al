page 70000054 "MY eInv Posted Invoice Edit"
{
    Caption = 'Edit eInvoice Information';
    PageType = Document;
    SourceTable = "Sales Invoice Header";
    Editable = true;
    Permissions = tabledata "Sales Invoice Header" = rm, tabledata "Sales Invoice Line" = rm;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Document Information';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("MY eInv Status"; Rec."MY eInv Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            part(Lines; "MY eInv Posted Invoice Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AutoFillFromMaster)
            {
                ApplicationArea = All;
                Caption = 'Auto-Fill from Master Data';
                Image = RefreshLines;
                ToolTip = 'Automatically fill eInvoice fields from Item/Resource master data';

                trigger OnAction()
                var
                    SalesInvoiceLine: Record "Sales Invoice Line";
                    UpdateCount: Integer;
                begin
                    if not Confirm('This will update eInvoice fields for all lines based on master data.\Do you want to continue?', false) then
                        exit;

                    UpdateCount := 0;
                    SalesInvoiceLine.SetRange("Document No.", Rec."No.");
                    if SalesInvoiceLine.FindSet(true) then
                        repeat
                            if UpdateLineFromMaster(SalesInvoiceLine) then
                                UpdateCount += 1;
                        until SalesInvoiceLine.Next() = 0;

                    CurrPage.Update(false);
                    Message('%1 lines have been updated.', UpdateCount);
                end;
            }
        }
    }

    local procedure UpdateLineFromMaster(var SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    var
        Item: Record Item;
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
        UnitOfMeasure: Record "Unit of Measure";
        Updated: Boolean;
    begin
        Updated := false;

        case SalesInvoiceLine.Type of
            SalesInvoiceLine.Type::Item:
                if Item.Get(SalesInvoiceLine."No.") then begin
                    SalesInvoiceLine."MY eInv Classification Code" := Item."MY eInv Sales Classification";
                    SalesInvoiceLine."MY eInv Country of Origin" := Item."MY eInv Country of Origin";
                    SalesInvoiceLine."MY eInv Tariff Code" := Item."MY eInv Tariff Code";
                    Updated := true;
                end;

            SalesInvoiceLine.Type::Resource:
                if Resource.Get(SalesInvoiceLine."No.") then begin
                    SalesInvoiceLine."MY eInv Classification Code" := Resource."MY eInv Sales Classification";
                    Updated := true;
                end;

            SalesInvoiceLine.Type::"Charge (Item)":
                if ItemCharge.Get(SalesInvoiceLine."No.") then begin
                    SalesInvoiceLine."MY eInv Classification Code" := ItemCharge."MY eInv Sales Classification";
                    Updated := true;
                end;
        end;

        // Update LHDN UOM from Unit of Measure
        if SalesInvoiceLine."Unit of Measure Code" <> '' then
            if UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code") then begin
                SalesInvoiceLine."MY eInv LHDN UOM" := UnitOfMeasure."MY eInv LHDN UOM";
                Updated := true;
            end;

        if Updated then
            SalesInvoiceLine.Modify(true);

        exit(Updated);
    end;
}
