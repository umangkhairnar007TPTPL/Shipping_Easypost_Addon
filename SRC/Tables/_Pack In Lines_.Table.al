table 55013 "Pack In Lines"
{
    Caption = 'Pack In Lines';

    fields
    {
        field(1; "Packing No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Item Description"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Sales UoM"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Gross Wt (Items)"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Total Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Qty Packed"; Decimal)
        {
            DataClassification = ToBeClassified;
            // trigger OnValidate()
            // var
            // SubPackingLines : Record "Sub Packing Lines";
            // begin
            //     SubPackingLines.Reset();
            //     SubPackingLines.SetRange("Packing No.",Rec."Packing No.");
            //     SubPackingLines.SetRange("Packing Type",Rec."Packing Type");
            //     if SubPackingLines.FindFirst()
            // end;
        }
        field(10; "Remaining Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Box Qty Packing Details"; Text[500])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Box ID"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Box Master";
        }
        field(13; "Qty to Add"; Decimal)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                ReadjustPacking: Record "ReAdjust Packing";
                PackingAdjustment: Record "Packing Adjustment";
                Item: Record Item;
                SubPackingLines: record "Sub Packing Lines";
                BoxMaster: Record "Box Master";
                SubPackingLinesPage: Page "Sub Packing Lines";
                Readjust: Record "ReAdjust Packing";
                SubPackingLines2: record "Sub Packing Lines";
                SubPackingLines3: Record "Sub Packing Lines";
            begin
                if Rec."Qty to Add" <> 0 then begin
                    Rec.Validate("Remaining Qty", Rec."Remaining Qty" - Rec."Qty to Add");
                    Rec.Validate("Qty Packed", xRec."Qty Packed" + Rec."Qty to Add");
                    ReadjustPacking.Reset();
                    ReadjustPacking.SetRange("Packing No", Rec."Packing No.");
                    ReadjustPacking.SetRange("Box ID", Rec."Temp. Box ID");
                    ReadjustPacking.SetRange("Line No.", Rec."Line No.");
                    if ReadjustPacking.FindFirst() then begin
                        ReadjustPacking.Validate("Qty to pack in this Box", ReadjustPacking."Qty to pack in this Box" + Rec."Qty to Add");
                        ReadjustPacking.Modify();
                    end
                    else begin
                        ReadjustPacking.Init();
                        ReadjustPacking.Validate("Packing No", Rec."Packing No.");
                        ReadjustPacking.Validate("Box ID", Rec."Temp. Box ID");
                        ReadjustPacking.Validate("Line No.", Rec."Line No.");
                        ReadjustPacking.Validate("Item No.", Rec."Item No.");
                        ReadjustPacking.Validate("Item Description", Rec."Item Description");
                        ReadjustPacking.Validate("Sales UoM", Rec."Sales UoM");
                        ReadjustPacking.Validate("Total Qty", Rec."Total Qty");
                        ReadjustPacking.Validate("Qty to Remove", 0);
                        ReadjustPacking.Validate(SourceLineNo, Rec.SourceLineNo);
                        ReadjustPacking.Validate("Qty to pack in this Box", Rec."Qty to Add");
                        ReadjustPacking.Insert();
                        SubPackingLines.Reset();
                        SubPackingLines.SetRange("Packing No.", Readjust."Packing No");
                        if SubPackingLines.FindSet() then;
                        SubPackingLinesPage.Activate(true);
                    end;
                    PackingAdjustment.Reset();
                    PackingAdjustment.SetRange("Packing No", Rec."Packing No.");
                    PackingAdjustment.SetFilter("Box ID", Rec."Temp. Box ID");
                    if PackingAdjustment.FindFirst() then begin
                        Item.Get(Rec."Item No.");
                        // BoxMaster.Get(PackingAdjustment."Box ID");
                        PackingAdjustment."Qty Packed in this Box" := PackingAdjustment."Qty Packed in this Box" + Rec."Qty to Add";
                        PackingAdjustment.Validate("Total Item Wt", PackingAdjustment."Total Item Wt" + (Rec."Qty to Add" * Item."Gross Weight"));
                        PackingAdjustment.Validate("Total Gross Ship Wt", PackingAdjustment."Additional Wt" + PackingAdjustment."Total Item Wt" + PackingAdjustment."Box Wt");
                        PackingAdjustment.Modify();
                    end;
                    SubPackingLines.Reset();
                    SubPackingLines.SetRange("Packing No.", Rec."Packing No.");
                    SubPackingLines.SetRange("Box Sr ID/Packing No.", Rec."Temp. Box ID");
                    if SubPackingLines.FindFirst() then begin
                        // SubPackingLines.Validate("Qty Packed", PackingAdjustment."Qty Packed in this Box/");
                        // SubPackingLines.Modify();
                        Readjust.Reset();
                        Readjust.SetRange("Packing No", Rec."Packing No.");
                        Readjust.SetRange("Box ID", Rec."Temp. Box ID");
                        if Readjust.FindSet() then begin
                            Rec."Qty in this Box" := Readjust."Qty to pack in this Box";
                            SubPackingLines3.Reset();
                            SubPackingLines3.SetRange("Packing No.", Rec."Packing No.");
                            SubPackingLines3.SetRange("Box Sr ID/Packing No.", Rec."Temp. Box ID");
                            if SubPackingLines3.FindFirst() then begin
                                SubPackingLines3.Validate("Insurance price", 0);
                                SubPackingLines3."Qty Packed" := 0;
                                SubPackingLines3.Modify();
                                repeat
                                    SubPackingLines2.Reset();
                                    SubPackingLines2.SetRange("Packing No.", ReAdjustPacking."Packing No");
                                    SubPackingLines2.SetRange("Box Sr ID/Packing No.", ReAdjustPacking."Box ID");
                                    if SubPackingLines2.FindFirst() then begin
                                        SubPackingLines2."Insurance price" += Readjust."Insurance Price";
                                        SubPackingLines2."Qty Packed" += Readjust."Qty to pack in this Box";
                                        SubPackingLines2.Modify();
                                    end;
                                until Readjust.Next() = 0;
                            end;
                        end;
                    end;
                    Rec."Qty to Add" := 0;
                    Rec.Modify();
                    SubPackingLinesPage.Update(true);
                end;
            end;
        }
        field(14; "Temp. Box ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(15; "SourceLineNo"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(16; "Qty in this Box"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Packing No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
