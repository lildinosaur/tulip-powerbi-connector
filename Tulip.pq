[Version = "1.0.0"]
section Tulip;

api_base = "/api/v3";
get_tables_path = api_base & "/tables";
get_table_count_path = api_base & "/tables/#{0}/count";
get_table_records_path = api_base & "/tables/#{0}/records?limit=100&sortBy=_sequenceNumber&sortDir=asc";

[DataSource.Kind="Tulip", Publish="Tulip.Publish"]
shared Tulip.Contents = Value.ReplaceType(TulipNavTable, TulipType);

// Defines metadata in the form of parameter/function documentation
TulipType = type function (
    FactoryURL as (Uri.Type meta[
        Documentation.FieldCaption = Extension.LoadString("FactoryURLCaption"),
        Documentation.FieldDescription = Extension.LoadString("FactoryURLDescription"),
        Documentation.SampleValues = {Extension.LoadString("FactoryURLSampleValue")}
    ]),
    optional RecordsLimit as (type number meta [
        Documentation.FieldCaption = Extension.LoadString("LimitCaption"),
        Documentation.FieldDescription = Extension.LoadString("LimitDescription"),
        Documentation.SampleValues = {Extension.LoadString("LimitSampleValue")},
        Documentation.DefaultValue = 100
    ]))
    as table meta [
        Documentation.Name = "Tulip Data Connector",
        Documentation.LongDescription = "Tulip Data Connector"
    ];

TulipNavTable = (FactoryURL as text,optional RecordsLimit as number) as table =>
    let
        Credential = Extension.CurrentCredential(),
        FactoryURL = Text.Trim(FactoryURL),
        RecordsLimit = if RecordsLimit <> null then RecordsLimit else 100,
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Tulip Tables", "tables", GetTableNames(FactoryURL, RecordsLimit), "Folder", "Folder", false}
            }
        ),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable;

shared GetTableNames = (FactoryURL as text, optional RecordsLimit as number) => 
    let
        // Get tables from API
        tablesResponse = TulipRequest(FactoryURL, get_tables_path),
        
        // Transform response into navigation table
        tableRows = Table.TransformRows(
            tablesResponse,
            each {
                _[label], 
                _[id], 
                GetTableRecords(FactoryURL, _[id], RecordsLimit),
                "Tables",
                "Tables",
                true
            }
        ),
        
        innerTables = Table.FromRows(
            tableRows,
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}
        ),
        
        NavTable = Table.ToNavigationTable(
            innerTables, 
            {"Key"}, 
            "Name", 
            "Data", 
            "ItemKind", 
            "ItemName", 
            "IsLeaf"
        )
    in
        NavTable;

shared GetTableRecords = (factoryUrl as text, tableId as text, recordsLimit as number) as table => 
    let
        path = Text.Format(get_table_records_path, {tableId}) & "&limit=" & Text.From(recordsLimit),
        records = TulipRequest(factoryUrl, path)
    in
        records;

shared TulipRequest = (url as text, path as text) as table =>
    let
        credential = Extension.CurrentCredential(),
        apiKey = credential[Username],
        apiSecret = credential[Password],
        
        // Construct headers with authentication
        headers = [
            #"Authorization" = "Basic " & Binary.ToText(Text.ToBinary(apiKey & ":" & apiSecret), BinaryEncoding.Base64),
            #"Content-Type" = "application/json"
        ],
        
        // Construct full URL
        url = Text.Combine({url, path}),
        
        // Make the API request
        response = Web.Contents(
            url,
            [
                Headers = headers,
                ManualStatusHandling = {400, 401, 404, 500}
            ]
        ),
        
        // Parse JSON response
        responseJson = Json.Document(response),
        responseTable = Table.FromRecords(responseJson)
    in
        responseTable;
        
// Navigation Table Helper
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

// Data Source Kind description
Tulip = [
    TestConnection = (dataSourcePath) => { "Tulip.TestConnection" },
    Authentication = [
        UsernamePassword = [
            UsernameLabel = Extension.LoadString("ClientIdLabel"),
            PasswordLabel = Extension.LoadString("ClientSecretLabel"),
            Label = Extension.LoadString("ClientCredentialsLabel")     
        ]
    ],
    Required = true,  // This makes authentication mandatory
    Label = Extension.LoadString("DataSourceLabel")
];

Tulip.TestConnection = (dataSourcePath) =>
    let
        credential = Extension.CurrentCredential(),
        apiKey = credential[Username],
        apiSecret = credential[Password],
        // Add validation logic here
        result = if (apiKey <> null and apiSecret <> null) then
            true
        else
            error Extension.LoadString("CredentialsMissingError")
    in
        result;

// Data Source UI publishing description
Tulip.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Tulip.Icons,
    SourceTypeImage = Tulip.Icons
];

Tulip.Icons = [
    Icon16 = { Extension.Contents("Tulip16.png"), Extension.Contents("Tulip20.png"), Extension.Contents("Tulip24.png"), Extension.Contents("Tulip32.png") },
    Icon32 = { Extension.Contents("Tulip32.png"), Extension.Contents("Tulip40.png"), Extension.Contents("Tulip48.png"), Extension.Contents("Tulip64.png") }
];
