#!/usr/bin/env powershell
<#
.SYNOPSIS
    Script complet du TP : Import du backup → Transformations medallion → Sécurité → Validation
.DESCRIPTION
    Exécute le pipeline complet : import SQL, transformations (silver/gold), RLS, et validation Python.
    Produit des logs dans logs/ et un rapport de validation logs/validation_report.txt.
.PARAMETER PgPassword
    Mot de passe PostgreSQL (défaut: 'postgres')
.PARAMETER PgUser
    Utilisateur PostgreSQL (défaut: 'postgres')
.PARAMETER PgHost
    Hôte PostgreSQL (défaut: 'localhost')
.PARAMETER PgPort
    Port PostgreSQL (défaut: 5432)
.EXAMPLE
    .\run_full_pipeline.ps1 -PgPassword 'my_password'
    .\run_full_pipeline.ps1 -PgPassword 'postgres' -PgUser 'postgres' -PgHost 'localhost'
#>

param(
    [string]$PgPassword = 'postgres',
    [string]$PgUser = 'postgres',
    [string]$PgHost = 'localhost',
    [int]$PgPort = 5432
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logsDir = Join-Path $ProjectRoot 'logs'

# Créer le répertoire logs s'il n'existe pas
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
    Write-Host "✓ Répertoire logs créé" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TP - Pipeline Complet" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Fonction pour exécuter et logger une commande
function Invoke-WithLog {
    param(
        [string]$Description,
        [scriptblock]$Command,
        [string]$LogFile
    )
    Write-Host "► $Description..." -ForegroundColor Yellow
    try {
        $output = & $Command 2>&1
        $output | Tee-Object -FilePath $LogFile
        Write-Host "✓ $Description réussie" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur : $_" -ForegroundColor Red
        exit 1
    }
}

# 1. Vérifier psql et python
Write-Host "`n[1/6] Vérification des outils..." -ForegroundColor Cyan
try {
    $psqlVersion = & psql --version
    Write-Host "  ✓ psql : $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ psql non trouvé. Installez PostgreSQL ou lancez Docker." -ForegroundColor Red
    exit 1
}

try {
    $pythonVersion = & python --version
    Write-Host "  ✓ python : $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ python non trouvé. Installez Python 3.7+." -ForegroundColor Red
    exit 1
}

# 2. Import du backup
Write-Host "`n[2/6] Import du backup SQL..." -ForegroundColor Cyan
$env:PGPASSWORD = $PgPassword
$backupPath = Join-Path $ProjectRoot 'docker' 'init' 'backup.sql'
if (-not (Test-Path $backupPath)) {
    Write-Host "  ✗ backup.sql non trouvé à $backupPath" -ForegroundColor Red
    exit 1
}
Invoke-WithLog -Description "Import du backup" -Command {
    & psql -h $PgHost -p $PgPort -U $PgUser -f $backupPath
} -LogFile (Join-Path $logsDir 'import_output.txt')

# 3. Transformations (silver -> gold)
Write-Host "`n[3/6] Appliquer transformations (silver → gold)..." -ForegroundColor Cyan
$transformPath = Join-Path $ProjectRoot 'sql' '04_transformations.sql'
if (-not (Test-Path $transformPath)) {
    Write-Host "  ✗ 04_transformations.sql non trouvé" -ForegroundColor Red
    exit 1
}
Invoke-WithLog -Description "Transformations medallion" -Command {
    & psql -h $PgHost -p $PgPort -U $PgUser -f $transformPath
} -LogFile (Join-Path $logsDir 'transform_output.txt')

# 4. Sécurité (RLS)
Write-Host "`n[4/6] Appliquer sécurité (rôles + RLS)..." -ForegroundColor Cyan
$securityPath = Join-Path $ProjectRoot 'sql' '05_security.sql'
if (-not (Test-Path $securityPath)) {
    Write-Host "  ✗ 05_security.sql non trouvé" -ForegroundColor Red
    exit 1
}
Invoke-WithLog -Description "Sécurité (RLS)" -Command {
    & psql -h $PgHost -p $PgPort -U $PgUser -f $securityPath
} -LogFile (Join-Path $logsDir 'security_output.txt')

# 5. Vérification SQL
Write-Host "`n[5/6] Vérification rapide..." -ForegroundColor Cyan
Invoke-WithLog -Description "Vérif SQL (COUNT gold_daily_activity)" -Command {
    & psql -h $PgHost -p $PgPort -U $PgUser -c "SELECT COUNT(*) FROM analytics_velocity.gold_daily_activity;"
} -LogFile (Join-Path $logsDir 'verify_sql.txt')

# 6. Validation Python
Write-Host "`n[6/6] Lancer la validation Python..." -ForegroundColor Cyan
$env:PGHOST = $PgHost
$env:PGPORT = $PgPort
$env:PGUSER = $PgUser
$env:PGPASSWORD = $PgPassword
$env:PGDATABASE = 'postgres'

Write-Host "  • Installation des dépendances..." -ForegroundColor Yellow
& python -m pip install -q -r (Join-Path $ProjectRoot 'requirements.txt') 2>&1 | Out-Null
Write-Host "  ✓ Dépendances installées" -ForegroundColor Green

Write-Host "  • Exécution du script de validation..." -ForegroundColor Yellow
try {
    & python (Join-Path $ProjectRoot 'notebooks' 'validate_db.py')
    Write-Host "  ✓ Validation complétée" -ForegroundColor Green
    
    # Afficher le rapport
    $reportPath = Join-Path $logsDir 'validation_report.txt'
    if (Test-Path $reportPath) {
        Write-Host "`n  Rapport de validation :" -ForegroundColor Cyan
        Get-Content $reportPath | ForEach-Object { Write-Host "    $_" }
    }
} catch {
    Write-Host "  ✗ Erreur de validation : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✓ Pipeline complet réussi !" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
Write-Host "Logs générés dans: $logsDir" -ForegroundColor Yellow
Write-Host "Rapport: $(Join-Path $logsDir 'validation_report.txt')" -ForegroundColor Yellow

# Optionnel : git add + commit + push
Write-Host "`nSouhaitez-vous pousser les artefacts vers GitHub ? (oui/non) : " -ForegroundColor Cyan -NoNewline
$reply = Read-Host
if ($reply -eq 'oui' -or $reply -eq 'o' -or $reply -eq 'yes' -or $reply -eq 'y') {
    Write-Host "`n→ Préparation du push..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    try {
        git add .github/workflows/ci-pipeline.yml notebooks/validate_db.py scripts/import_backup_fixed.ps1 scripts/import_backup.ps1 scripts/run_full_pipeline.ps1 requirements.txt sql/04_transformations.sql sql/05_security.sql README_TP.md logs/ 2>&1 | Out-Null
        git commit -m "feat(tp): pipeline complet + validation + documentation; logs de la dernière exécution" 2>&1 | Out-Null
        git push --set-upstream origin feature/docker-infrastructure
        Write-Host "✓ Push réussi vers feature/docker-infrastructure" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors du push : $_" -ForegroundColor Red
        Write-Host "→ Essayez manuellement : git push --set-upstream origin feature/docker-infrastructure" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

Write-Host "`nExécution terminée à $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
