param(
    [string]$PgUser = "postgres",
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$DbName = "postgres",
    [string]$SqlPath = "docker\init\backup.sql"
)

Write-Output "Vérification de la présence de psql..."
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Error "psql introuvable dans le PATH. Assure-toi que PostgreSQL est installé et que \"...\\bin\" est dans PATH."
    exit 1
}

$fullPath = Join-Path (Get-Location) $SqlPath
if (-not (Test-Path $fullPath)) {
    Write-Error "Fichier SQL introuvable : $fullPath"
    exit 1
}

Write-Output "Import du fichier : $fullPath vers la base $DbName@${PgHost}:${PgPort} en tant que $PgUser"

# Si tu veux éviter la demande interactive du mot de passe, définis la variable d'environnement PGPASSWORD
# $env:PGPASSWORD = 'ton_mot_de_passe'

& psql -U $PgUser -h $PgHost -p $PgPort -d $DbName -f $fullPath

Write-Output "Import terminé. Vérifie les logs ci‑dessous si des erreurs ont eu lieu."
param(
    [string]$PgUser = "postgres",
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$DbName = "postgres",
    [string]$SqlPath = "docker\init\backup.sql"
)

Write-Output "Vérification de la présence de psql..."
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Error "psql introuvable dans le PATH. Assure-toi que PostgreSQL est installé et que \"...\\bin\" est dans PATH."
    exit 1
}

$fullPath = Join-Path (Get-Location) $SqlPath
if (-not (Test-Path $fullPath)) {
    Write-Error "Fichier SQL introuvable : $fullPath"
    exit 1
}

Write-Output "Import du fichier : $fullPath vers la base $DbName@${PgHost}:${PgPort} en tant que $PgUser"

# Si tu veux éviter la demande interactive du mot de passe, définis la variable d'environnement PGPASSWORD
# $env:PGPASSWORD = 'ton_mot_de_passe'

& psql -U $PgUser -h $PgHost -p $PgPort -d $DbName -f $fullPath

Write-Output "Import terminé. Vérifie les logs ci‑dessous si des erreurs ont eu lieu."
