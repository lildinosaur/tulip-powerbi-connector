// Use this file to write queries to test your data connector
/*let
    result = Tulip.Contents()
in
    result
*/
/*
TulipImpl = (TulipTableId as text, instance as text) =>

let
Query = #table( type table [#"table" = text], { {TulipTableId}}),
Function = Table.AddColumn(Query, "Offset", Number.Round(Json.Document(Web.Contents("https://"&instance&"/api/v3/tables/"& TulipTableId &"/count"))/100)),
ExpandedOffset =Table.ExpandListColumn(Function, "Offset"),
NbLoop=Number.Round(Json.Document(Web.Contents("https://"&instance&"/api/v3/tables/"& TulipTableId &"/count"))/100),
TableOffset=Table.FromList(List.Transform({0..NbLoop},each Number.ToText(_*100))),
TableOffset1=Table.RenameColumns(TableOffset,{{"Column1", "Offset"}}),
TulipTable= Table.AddColumn(TableOffset1, "Records", each Table.FromRecords(Json.Document(Web.Contents("https://"&instance&"/api/v3/tables/" & TulipTableId & "/records?limit=100&offset="& [Offset] &"&sortBy=_sequenceNumber&sortDir=asc"))))

in
TulipTable*/