<#
.Synopsis
  This will scan a Microsoft Azure SQL Database for Indexes whose Index fragmentation is greater than the defined threshold percentage and will rebuild them sequentially.
.DESCRIPTION
   Be sure to rebuild fragmented indexes on a regular basis on Azure SQL Database. Fragmentation increases Index size and results in slower queries.
.EXAMPLE
   Start-SqlDatabaseIndexRebuild -Server '' -Database '' -User '' -Password ''
.EXAMPLE
   Start-SqlDatabaseIndexRebuild  -Server '' -Database '' -User '' -Password '' -FragmentationPercentageThreshold 10
#>
Function Start-SqlDatabaseIndexRebuild 
{
  [CmdletBinding()]
  Param
  (
    # SQL Database Server
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
    [string]
    $Server,

    # SQL Database Name
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
    [string]
    $Database,

    # SQL Database Username
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
    [string]
    $User,

    # SQL Database Password
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=3)]
    [string]
    $Password,

    # Fragmentation Percentage Threshold used to select indexes to defragment
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=4)]
    [int]
    $FragmentationPercentageThreshold = 10,

    # A flag used to skip tables created by Azure SQL DataSync
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=5)]
    [bool]
    $SkipSqlDataSyncTables = $true
  )

  $assemblies = (
    'System.Data',
    'System.Collections',
    'System.Data.DataSetExtensions',
    'System.Xml',
    'System.Linq'
  ) 

  $source = @'
    using System;
    using System.Linq;
    using System.Collections;
    using System.Collections.Generic;
    using System.Data;
    using System.Data.SqlClient;
    using System.Globalization;

    public class DbContext
    {
        public string Server { get; set; }
        public string Database { get; set; }
        public string User { get; set; }
        public string Password { get; set; }

        private string ConnectionString
        {
            get
            {
                return String.Format(CultureInfo.InvariantCulture,
                                     "Server=tcp:{0}.database.windows.net,1433;Database={1};User ID={2}@{0};Password={3};Trusted_Connection=False;Encrypt=True;Connection Timeout=3600;",
                                     Server,
                                     Database,
                                     User,
                                     Password);
            }
        }

        const string listTablesQuery = @"SELECT o.name AS [table_name]
                                            FROM  sys.objects AS o
                                            WHERE o.is_ms_shipped = 0 AND o.[type] = 'U'";
        public List<string> GetTableNames()
        {
            return Query(listTablesQuery)
                        .AsEnumerable()
                        .Select(r => r[0].ToString())
                        .ToList();
        }

        const string findFragmentedIndexesQuery = @"SELECT name, avg_fragmentation_in_percent
                                                    FROM sys.dm_db_index_physical_stats (
                                                            DB_ID(N'DatabaseName')
                                                            , OBJECT_ID('{0}')
                                                            , NULL
                                                            , NULL
                                                            , NULL) AS a
                                                    JOIN sys.indexes AS b
                                                    ON a.object_id = b.object_id AND a.index_id = b.index_id
                                                    WHERE avg_fragmentation_in_percent > {1}";

        public Hashtable GetFragmentedTableIndexes(string table, int fragmentationThreshold)
        {
            return ToIndexTableMap(table, Query(string.Format(CultureInfo.InvariantCulture,
                findFragmentedIndexesQuery,
                table,
                fragmentationThreshold)));
        }

        private static Hashtable ToIndexTableMap(string table, DataTable indexes)
        {
            var t = new Hashtable();
            foreach (var i in indexes.AsEnumerable())
                t.Add(i[0],i[1]);    

            return t;
        }

        private DataTable Query(string query)
        {
            using (var connection = new SqlConnection(ConnectionString))
            {
                connection.Open();

                var command = new SqlCommand(query, connection);
                var reader = new SqlDataAdapter(command);
                var table = new DataTable();
                reader.Fill(table);
                return table;
            }
        }

        const string rebuildIndex = "ALTER INDEX [{0}] ON [{1}] REBUILD WITH (ONLINE=ON);";

        public int RebuildIndex(string indexName, string table)
        {
            return Command(string.Format(CultureInfo.InvariantCulture, rebuildIndex, indexName, table));
        }

        private int Command(string cmd)
        {
            using (var connection = new SqlConnection(ConnectionString))
            {
                connection.Open();

                var command = new SqlCommand(cmd, connection);
                return command.ExecuteNonQuery();
            }
        }
    }
'@

  Add-Type -Language CSharp -TypeDefinition $source -ReferencedAssemblies $assemblies

  $db = New-Object DBContext
  $db.Server = $Server
  $db.Database = $Database
  $db.User = $User
  $db.Password = $Password    

  Write-Verbose 'Connecting'

  $tables = $db.GetTableNames()

  Write-Verbose $('Found ' + $tables.Count + ' Tables')

  $percent = 0
  $tableIndex = 0

  foreach($t in $tables){

    if($SkipSqlDataSyncTables -and $t.Contains('dss'))
    {
      Write-Warning $('Skipping  Table ' + $t)
      continue
    }

    $indexes = $db.GetFragmentedTableIndexes($t, $FragmentationPercentageThreshold)
    foreach($i in $indexes.Keys)
    {
      $message = 'Successful'
      try
      {
        $result = $db.RebuildIndex($i,$t)
      }
      catch
      {
        $message = 'Failed'
        Write-Warning $("Exception Message: $($_.Exception.Message)")
      }
      finally
      {
        Write-Verbose $($message + ' Rebuild > Table '+ $t+ ' Index ' + $i + ' fragmented @ '+ $indexes[$i] + '%')
      }
    }
    $tableIndex ++
    $percent = ($tableIndex/$tables.Count) * 100
    Write-Progress $t -PercentComplete $percent
  }
}