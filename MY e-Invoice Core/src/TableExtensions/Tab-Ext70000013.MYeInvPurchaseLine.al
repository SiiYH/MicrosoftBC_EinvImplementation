tableextension 70000013 "MY eInv Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(70000000; "MY eInv Classification Code"; Code[20])
        {
            Caption = 'eInvoice Classification';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(Classification));
        }

        field(70000001; "MY eInv LHDN UOM"; Code[10])
        {
            Caption = 'eInvoice LHDN UOM';
            DataClassification = CustomerContent;
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const("Unit of Measurement"));
        }
        field(70000002; "MY eInv Country of Origin"; Code[10])
        {
            Caption = 'Country of Origin';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }

        field(70000003; "MY eInv Tariff Code"; Code[20])
        {
            Caption = 'Tariff Code';
            DataClassification = CustomerContent;
        }

        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                CopyEInvoiceFieldsFromMaster();
            end;
        }
        modify("Unit of Measure Code")
        {
            trigger OnAfterValidate()
            begin
                CopyLHDNUOMFromUnitOfMeasure();
            end;
        }

        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                // Clear fields when type changes
                Rec."MY eInv Classification Code" := '';
                Rec."MY eInv LHDN UOM" := '';
            end;
        }
    }

    local procedure CopyEInvoiceFieldsFromMaster()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        Resource: Record Resource;
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";
    begin
        if not MYeInvFeaMgmt.IsEInvoiceEnabled() then
            exit;

        if Rec."No." = '' then
            exit;

        case Rec.Type of
            Rec.Type::Item:
                if Item.Get(Rec."No.") then begin
                    Rec."MY eInv Classification Code" := Item."MY eInv Purch. Classification"; // Use purchase classification
                    Rec."MY eInv Country of Origin" := Item."MY eInv Country of Origin";
                    Rec."MY eInv Tariff Code" := Item."MY eInv Tariff Code"
                end;

            Rec.Type::"Charge (Item)":
                if ItemCharge.Get(Rec."No.") then begin
                    Rec."MY eInv Classification Code" := ItemCharge."MY eInv Classification Code";
                end;

            Rec.Type::Resource:
                if Resource.Get(Rec."No.") then begin
                    Rec."MY eInv Classification Code" := Resource."MY eInv Classification Code";
                end;
        end;
    end;

    local procedure CopyLHDNUOMFromUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        EInvSetup: Record "MY eInv Setup";
        MYeInvFeaMgmt: Codeunit "MY eInv Feature Management";

    begin
        if not MYeInvFeaMgmt.IsEInvoiceEnabled() then
            exit;
        if Rec."Unit of Measure Code" = '' then
            exit;

        if UnitOfMeasure.Get(Rec."Unit of Measure Code") then
            Rec."MY eInv LHDN UOM" := UnitOfMeasure."MY eInv LHDN UOM";
    end;
}
