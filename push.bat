@echo off
cd /d "C:\Users\gui\Desktop\data\Nouveau dossier\velocity-bike-analytics"
echo === GIT STATUS ===
git status
echo.
echo === GIT ADD ===
git add -A
echo.
echo === GIT COMMIT ===
git commit -m "docs: add all TP deliverables (README, automation, SQL, CI, validation)"
echo.
echo === GIT PUSH ===
git push origin feature/docker-infrastructure
echo.
echo === FINAL STATUS ===
git log --oneline -3
echo Done!
pause
