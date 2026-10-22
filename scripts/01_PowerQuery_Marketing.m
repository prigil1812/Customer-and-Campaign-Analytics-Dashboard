// =====================================================================
// POWER QUERY (M) SCRIPTS: Marketing / Customer Personality project
// How to use: Home > Get Data > Blank Query > Advanced Editor.
// Paste ONE block per query and name it exactly as in each header.
// Update the FilePath in stgMarketing. The file is TAB-delimited.
// =====================================================================


// ---------------------------------------------------------------------
// QUERY 1: stgMarketing   (right-click > untick "Enable load")
// ---------------------------------------------------------------------
let
    FilePath = "C:\Users\YourName\Downloads\marketing_campaign.csv",

    Source = Csv.Document(
        File.Contents(FilePath),
        [Delimiter = "#(tab)", Columns = 29, Encoding = 65001, QuoteStyle = QuoteStyle.None]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // Z_CostContact (always 3) and Z_Revenue (always 11) are constants with
    // no documented meaning, so they are dropped.
    Dropped = Table.RemoveColumns(Promoted, {"Z_CostContact", "Z_Revenue"}),

    // Dates in the file are day-month-year, so use the en-GB culture
    Typed = Table.TransformColumnTypes(Dropped, {
        {"ID", Int64.Type}, {"Year_Birth", Int64.Type},
        {"Education", type text}, {"Marital_Status", type text},
        {"Income", type number}, {"Kidhome", Int64.Type}, {"Teenhome", Int64.Type},
        {"Dt_Customer", type date}, {"Recency", Int64.Type},
        {"MntWines", Int64.Type}, {"MntFruits", Int64.Type},
        {"MntMeatProducts", Int64.Type}, {"MntFishProducts", Int64.Type},
        {"MntSweetProducts", Int64.Type}, {"MntGoldProds", Int64.Type},
        {"NumDealsPurchases", Int64.Type}, {"NumWebPurchases", Int64.Type},
        {"NumCatalogPurchases", Int64.Type}, {"NumStorePurchases", Int64.Type},
        {"NumWebVisitsMonth", Int64.Type},
        {"AcceptedCmp1", Int64.Type}, {"AcceptedCmp2", Int64.Type},
        {"AcceptedCmp3", Int64.Type}, {"AcceptedCmp4", Int64.Type},
        {"AcceptedCmp5", Int64.Type}, {"Complain", Int64.Type}, {"Response", Int64.Type}
    }, "en-GB"),

    Renamed = Table.RenameColumns(Typed, {
        {"ID", "CustomerID"}, {"Year_Birth", "YearBirth"},
        {"Marital_Status", "MaritalStatus"}, {"Dt_Customer", "EnrollmentDate"},
        {"Kidhome", "KidsHome"}, {"Teenhome", "TeensHome"},
        {"MntWines", "Wines"}, {"MntFruits", "Fruits"}, {"MntMeatProducts", "Meat"},
        {"MntFishProducts", "Fish"}, {"MntSweetProducts", "Sweets"}, {"MntGoldProds", "Gold"},
        {"NumDealsPurchases", "DealsPurchases"}, {"NumWebPurchases", "WebPurchases"},
        {"NumCatalogPurchases", "CatalogPurchases"}, {"NumStorePurchases", "StorePurchases"},
        {"NumWebVisitsMonth", "WebVisitsMonth"},
        {"AcceptedCmp1", "Cmp1"}, {"AcceptedCmp2", "Cmp2"}, {"AcceptedCmp3", "Cmp3"},
        {"AcceptedCmp4", "Cmp4"}, {"AcceptedCmp5", "Cmp5"}, {"Response", "Cmp6"}
    }),

    NoDupes = Table.Distinct(Renamed, {"CustomerID"}),

    // Data quality fixes (all documented in the build guide):
    //  - Income: 24 blanks stay blank; one 666,666 outlier becomes blank
    //  - YearBirth: 3 impossible years (1893 to 1900) become blank
    //  - Education: "Graduation" -> "Graduate"; "2n Cycle" = 2nd-cycle (Master level)
    //  - MaritalStatus: "Alone" -> "Single"; "Absurd" and "YOLO" -> "Other"
    Cleaned = Table.TransformColumns(NoDupes, {
        {"Income", each if _ <> null and _ > 200000 then null else _, type nullable number},
        {"YearBirth", each if _ <> null and _ < 1920 then null else _, Int64.Type},
        {"Education", each let t = Text.Trim(_) in
            if t = "Graduation" then "Graduate" else if t = "2n Cycle" then "Master" else t, type text},
        {"MaritalStatus", each let t = Text.Trim(_) in
            if t = "Alone" then "Single" else if t = "Absurd" or t = "YOLO" then "Other" else t, type text}
    }),

    // Reference date = most recent enrollment (used for Age and Tenure)
    RefDate = List.Max(Cleaned[EnrollmentDate]),

    AddAge = Table.AddColumn(Cleaned, "Age",
        each if [YearBirth] = null then null else Date.Year(RefDate) - [YearBirth], Int64.Type),
    AddAgeGroup = Table.AddColumn(AddAge, "AgeGroup",
        each if [Age] = null then "Unknown"
             else if [Age] < 35 then "Under 35"
             else if [Age] < 45 then "35-44"
             else if [Age] < 55 then "45-54"
             else if [Age] < 65 then "55-64"
             else "65+", type text),
    AddAgeOrder = Table.AddColumn(AddAgeGroup, "AgeGroupOrder",
        each List.PositionOf({"Under 35", "35-44", "45-54", "55-64", "65+", "Unknown"}, [AgeGroup]) + 1, Int64.Type),

    AddIncomeBand = Table.AddColumn(AddAgeOrder, "IncomeBand",
        each if [Income] = null then "Unknown"
             else if [Income] < 35000 then "Low (<35K)"
             else if [Income] <= 70000 then "Middle (35-70K)"
             else "High (>70K)", type text),
    AddIncomeOrder = Table.AddColumn(AddIncomeBand, "IncomeBandOrder",
        each List.PositionOf({"Low (<35K)", "Middle (35-70K)", "High (>70K)", "Unknown"}, [IncomeBand]) + 1, Int64.Type),

    AddEduOrder = Table.AddColumn(AddIncomeOrder, "EducationOrder",
        each List.PositionOf({"Basic", "Graduate", "Master", "PhD"}, [Education]) + 1, Int64.Type),

    AddRelationship = Table.AddColumn(AddEduOrder, "Relationship",
        each if [MaritalStatus] = "Married" or [MaritalStatus] = "Together" then "Partnered"
             else if [MaritalStatus] = "Other" then "Unknown"
             else "Not partnered", type text),

    AddChildren = Table.AddColumn(AddRelationship, "Children", each [KidsHome] + [TeensHome], Int64.Type),
    AddHasChildren = Table.AddColumn(AddChildren, "HasChildren", each if [Children] > 0 then "Yes" else "No", type text),

    AddTotalSpend = Table.AddColumn(AddHasChildren, "TotalSpend",
        each [Wines] + [Fruits] + [Meat] + [Fish] + [Sweets] + [Gold], Int64.Type),
    AddTotalPurchases = Table.AddColumn(AddTotalSpend, "TotalPurchases",
        each [WebPurchases] + [CatalogPurchases] + [StorePurchases], Int64.Type),
    AddCampaigns = Table.AddColumn(AddTotalPurchases, "CampaignsAccepted",
        each [Cmp1] + [Cmp2] + [Cmp3] + [Cmp4] + [Cmp5] + [Cmp6], Int64.Type),
    AddEver = Table.AddColumn(AddCampaigns, "EverAccepted",
        each if [CampaignsAccepted] > 0 then "Yes" else "No", type text),
    AddTenure = Table.AddColumn(AddEver, "TenureDays",
        each Duration.Days(RefDate - [EnrollmentDate]), Int64.Type),

    // 3 customers report more discount purchases than total purchases
    AddDealsCheck = Table.AddColumn(AddTenure, "DealsCheck",
        each if [DealsPurchases] > [TotalPurchases] then "Inconsistent" else "OK", type text)
in
    AddDealsCheck


// ---------------------------------------------------------------------
// QUERY 2: DimCustomer   (one row per customer)
// ---------------------------------------------------------------------
let
    Source = stgMarketing,
    Removed = Table.RemoveColumns(Source, {
        "Wines", "Fruits", "Meat", "Fish", "Sweets", "Gold",
        "WebPurchases", "CatalogPurchases", "StorePurchases",
        "Cmp1", "Cmp2", "Cmp3", "Cmp4", "Cmp5", "Cmp6"
    })
in
    Removed


// ---------------------------------------------------------------------
// QUERY 3: FactSpend   (one row per customer per product category)
// ---------------------------------------------------------------------
let
    Source = stgMarketing,
    Selected = Table.SelectColumns(Source, {"CustomerID", "Wines", "Fruits", "Meat", "Fish", "Sweets", "Gold"}),
    Unpivoted = Table.UnpivotOtherColumns(Selected, {"CustomerID"}, "Category", "Amount"),
    Labelled = Table.TransformColumns(Unpivoted, {{"Category", each if _ = "Gold" then "Gold Products" else _, type text}}),
    Typed = Table.TransformColumnTypes(Labelled, {{"Amount", Int64.Type}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY 4: FactChannel   (one row per customer per purchase channel)
// ---------------------------------------------------------------------
let
    Source = stgMarketing,
    Selected = Table.SelectColumns(Source, {"CustomerID", "WebPurchases", "CatalogPurchases", "StorePurchases"}),
    Unpivoted = Table.UnpivotOtherColumns(Selected, {"CustomerID"}, "Channel", "Purchases"),
    Labelled = Table.TransformColumns(Unpivoted, {{"Channel", each Text.Replace(_, "Purchases", ""), type text}}),
    Typed = Table.TransformColumnTypes(Labelled, {{"Purchases", Int64.Type}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY 5: FactCampaign   (one row per customer per campaign, 6 campaigns)
// Campaign 6 is the "Response" column (the last campaign).
// ---------------------------------------------------------------------
let
    Source = stgMarketing,
    Selected = Table.SelectColumns(Source, {"CustomerID", "Cmp1", "Cmp2", "Cmp3", "Cmp4", "Cmp5", "Cmp6"}),
    Unpivoted = Table.UnpivotOtherColumns(Selected, {"CustomerID"}, "Campaign", "Accepted"),
    AddNo = Table.AddColumn(Unpivoted, "CampaignNo", each Number.FromText(Text.End([Campaign], 1)), Int64.Type),
    AddLabel = Table.AddColumn(AddNo, "CampaignLabel",
        each if [CampaignNo] = 6 then "Campaign 6 (Last)" else "Campaign " & Text.From([CampaignNo]), type text),
    Final = Table.RemoveColumns(AddLabel, {"Campaign"}),
    Typed = Table.TransformColumnTypes(Final, {{"Accepted", Int64.Type}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY 6: DimDate   (calendar covering the enrollment period)
// ---------------------------------------------------------------------
let
    Source = stgMarketing,
    StartD = Date.StartOfMonth(List.Min(Source[EnrollmentDate])),
    EndD = Date.EndOfMonth(List.Max(Source[EnrollmentDate])),
    Dates = List.Dates(StartD, Duration.Days(EndD - StartD) + 1, #duration(1, 0, 0, 0)),
    ToTable = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    Typed = Table.TransformColumnTypes(ToTable, {{"Date", type date}}),
    AddYear = Table.AddColumn(Typed, "Year", each Date.Year([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddYear, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddMonthNo = Table.AddColumn(AddQuarter, "MonthNo", each Date.Month([Date]), Int64.Type),
    AddMonth = Table.AddColumn(AddMonthNo, "Month", each Date.ToText([Date], "MMM"), type text),
    AddYM = Table.AddColumn(AddMonth, "YearMonth", each Date.ToText([Date], "yyyy-MM"), type text)
in
    AddYM
