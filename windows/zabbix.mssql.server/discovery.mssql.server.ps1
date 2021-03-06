# Разработано Diego Cavalcante - 06/12/2017
# Мониторинг Windows SQLServer
# Версия: 1.1.0
# Создан = Версия 1.0.0 29.08.2017 (базовый сценарий).
# Обновление = Версия 1.1.0 01/02/2018 (Спасибо @bernardolankheet, JOBSTATUS вернул N = 5 Никогда не запускался).

# Параметры

Param(
  [string]$select,
  [string]$2
)

# Логин SQLSERVER
$usuario = "sqlusuario"
$senha   = "sqlsenha"

# Создаем JSON с именем всех баз данных.
if ( $select -eq 'JSONDB' ) 
{
$database = sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;SELECT name FROM master..sysdatabases"
$idx = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($db in $database)
{
    if ($idx -lt $database.Count)
    {
        $line= "{ `"{#MSSQLDBNAME}`" : `"" + $db + "`" },"
        write-host $line
    }
    elseif ($idx -ge $database.Count)
    {
    $line= "{ `"{#MSSQLDBNAME}`" : `"" + $db + "`" }"
    write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
} 

# Проверка состояния базы данных.
if ( $select -eq 'STATUS' )
{
sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;SELECT coalesce(max(state),7) from sys.databases where name = '$2'"
}

# Проверка количества соединений в базе данных.
if ( $select -eq 'CONN' )
{
sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;DECLARE @AllConnections TABLE(
    SPID INT,
    Status VARCHAR(MAX),
    LOGIN VARCHAR(MAX),
    HostName VARCHAR(MAX),
    BlkBy VARCHAR(MAX),
    DBName VARCHAR(MAX),
    Command VARCHAR(MAX),
    CPUTime INT,
    DiskIO INT,
    LastBatch VARCHAR(MAX),
    ProgramName VARCHAR(MAX),
    SPID_1 INT,
    REQUESTID INT
)
INSERT INTO @AllConnections EXEC sp_who2
SELECT count(*) FROM @AllConnections WHERE DBName = '$2'"
}

# Создаем JSON с названием всех заданий.
if ( $select -eq 'JSONJOB' )
{
$jobname = sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;SELECT [name] FROM msdb.dbo.sysjobs"
$idx = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($job in $jobname)
{
    if ($idx -lt $jobname.Count)
    {
        $line= "{ `"{#MSSQLJOBNAME}`" : `"" + $job + "`" },"
        write-host $line
    }
    elseif ($idx -ge $jobname.Count)
    {
    $line= "{ `"{#MSSQLJOBNAME}`" : `"" + $job + "`" }"
    write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
}

# Проверка статуса последнего запуска задания.
if ( $select -eq 'JOBSTATUS' )
{
sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;WITH last_hist_rec AS
(
SELECT ROW_NUMBER() OVER
(PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS [RowNum]
, job_id
, run_date AS [last_run_date]
, run_time AS [last_run_time]
, CASE run_status
WHEN 0 THEN '0'
WHEN 1 THEN '1'
WHEN 2 THEN '2'
WHEN 3 THEN '3'
WHEN 4 THEN '4'
END AS [status]
FROM msdb.dbo.sysjobhistory
)
SELECT jobs.name AS [job_name]
, hist.status
FROM msdb.dbo.sysjobs jobs
LEFT JOIN last_hist_rec hist ON hist.job_id = jobs.job_id
AND hist.RowNum = 1
WHERE jobs.name = '$2'" | % {$_.substring($_.length-1) -replace ''} | ForEach-Object {$_ -Replace "N", "5"}
}

# Проверка версии SQLServer.
if ( $select -eq 'VERSION' )
{
sqlcmd -d Master -U $usuario -P $senha -h -1 -W -Q "set nocount on;SELECT
   SERVERPROPERTY ( 'ProductVersion' ),
   SERVERPROPERTY ( 'Edition' ),
   SERVERPROPERTY ( 'ProductLevel' )"
}

