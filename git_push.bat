@echo off
cd /d %~dp0

echo Running: git add .
git add .

echo Running: git commit -m "testing"
git commit -m "testing"

echo Running: git push
git push

pause

