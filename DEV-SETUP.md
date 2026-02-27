# Development environment setup — noyahazzan-art/OpenHands

סטטוס והנחיות להרצת סביבת הפיתוח (בענן ומקומי).

---

## Cursor תקוע שעות על "setting up development environment"?

אם Cursor נתקע על "Cursor is setting up its development environment" **שעות**:

### אפשרות א' – Quick Dev Container (פתיחה מהירה)

1. **סגור את Cursor** לגמרי.
2. הרץ מתוך תיקיית הפרויקט:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/use-quick-devcontainer.ps1
   ```
   (ב-Linux/macOS: `bash scripts/use-quick-devcontainer.sh`)
3. **פתח מחדש** את הפרויקט ב-Cursor ובחר **Reopen in Container**.
4. ה-Container ייפתח תוך דקה־שתיים (בלי setup אוטומטי).
5. **בתוך ה-Container** פתח טרמינל והרץ:
   ```bash
   poetry config virtualenvs.in-project true && poetry install
   ```

### אפשרות ב' – עבודה בלי Container (מקומי Windows)

1. **סגור את Cursor**.
2. פתח את הפרויקט כ-**Folder** (לא Reopen in Container): **File → Open Folder** → בחר את `OpenHands`.
3. הרץ: `powershell -ExecutionPolicy Bypass -File scripts/setup-venv-windows.ps1`
4. בחר **Python: Select Interpreter** → `.venv\Scripts\python.exe`.

פרטים: [SETUP-WINDOWS.md](SETUP-WINDOWS.md).

---

## בענן (GitHub Codespaces / Dev Container / Cursor)

1. **פתח את הפרויקט ב-Dev Container**
   - ב-Cursor: **Dev Containers: Reopen in Container**
   - ב-VS Code: **Reopen in Container**
   - ה-Container מריץ אוטומטית את `.devcontainer/setup.sh`.

2. **מה ה-setup עושה**
   - מגדיר `poetry config virtualenvs.in-project true`
   - מתקין `nc`, `uv`, `uvx`
   - מריץ `.openhands/setup.sh` (poetry install, pre-commit וכו')
   - Playwright מדולג בהתקנה הראשונית (להאצה). להתקנה: `poetry run playwright install chromium`

3. **אם ה-IDE מתלונן על Python / Pyright**
   - אם `.venv` חסר: הרץ `make setup-venv` (או `scripts/setup-venv-windows.ps1` ב-Windows).
   - וודא שנבחר interpreter: **Python: Select Interpreter** → `.venv/bin/python` (או `.venv\Scripts\python.exe` ב-Windows).
   - אין צורך ב-`extraPaths` / `stubPath` — הוגדרו ב-`.vscode/settings.json` רק נתיב ה-interpreter.

4. **טסטים**
   - `make test` — בקאנד + פרונט
   - `make test-backend` — `poetry run pytest tests/`
   - טסטי E2E עם Playwright רצים רק כשמריצים דרך Poetry (יש skip אם playwright לא מותקן).

---

## מקומי (Linux / macOS)

```bash
# התקנה מלאה (כולל .venv בפרויקט)
make build

# או רק Python + .venv ל-IDE
make setup-venv
```

אחר כך: **Python: Select Interpreter** → `.venv/bin/python`.

---

## מקומי (Windows)

```powershell
# סקריפט מומלץ
powershell -ExecutionPolicy Bypass -File scripts/setup-venv-windows.ps1
```

אחר כך: **Python: Select Interpreter** → `.venv\Scripts\python.exe`.

פרטים: [SETUP-WINDOWS.md](SETUP-WINDOWS.md).

---

## קבצי תצורה רלוונטיים

| קובץ | תפקיד |
|------|--------|
| `.devcontainer/devcontainer.json` | תמונת Python 3.12, Poetry, Node; `postCreateCommand`: `.devcontainer/setup.sh` |
| `.devcontainer/devcontainer-quick.json` | גרסה מהירה – בלי setup (לשימוש כש-Cursor תקוע שעות) |
| `scripts/use-quick-devcontainer.ps1` / `.sh` | מחליף ל-Quick config; אחרי: סגור Cursor ו-Reopen in Container |
| `scripts/use-full-devcontainer.ps1` / `.sh` | מחזיר את ה-config המלא |
| `.devcontainer/setup.sh` | poetry config in-project, nc/uv/uvx, `.openhands/setup.sh` (poetry install דרך make install-pre-commit-hooks) |
| `.vscode/settings.json` | interpreter: `${workspaceFolder}/.venv/bin/python`, בלי stubPath/extraPaths |
| `pyrightconfig.json` | include: openhands, tests, scripts, skills; exclude: frontend, node_modules, .venv וכו' — מקצר סריקה |
| `Makefile` | `make setup-venv`, `make test`, `make test-backend`, `make build` |
| `scripts/setup-venv-windows.ps1` | Windows: in-project .venv + poetry install |

---

## בדיקה מהירה

```bash
# וידוא interpreter
poetry env info

# איסוף טסטים (בלי להריץ)
poetry run pytest tests/ --collect-only -q

# הרצת אפליקציה
make run
```

**גישה:** עם `make run` – פתח http://localhost:3001 בדפדפן (frontend dev server). Backend על 3000.

## Troubleshooting

| בעיה | פתרון |
|------|-------|
| Pyright איטי / Enumeration >10s | פתח **רק** את תיקיית OpenHands. וודא `pyrightconfig.json`, `files.exclude`, `python.analysis.diagnosticMode: openFilesOnly` |
| `stubPath is not a valid directory` | הרץ `make setup-venv`; בחר `.venv/bin/python` כ-interpreter |
| Frontend build חסר | `cd frontend && npm run build` |
| Backend crash על startup | וודא `frontend/build` קיים לפני `make start-backend` |
| Agent Execution Timed Out | Reload Window; פתח תיקיית פרויקט בלבד |
| Failed to push / GitHub auth | `gh auth login` או SSH key. ב-Windows: Settings → Accounts → GitHub |

---

**Repository:** [noyahazzan-art/OpenHands](https://github.com/noyahazzan-art/OpenHands)
