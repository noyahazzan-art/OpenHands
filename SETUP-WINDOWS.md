# OpenHands - התקנה מקומית ב-Windows

## Cursor תקוע שעות על "setting up development environment"?

אם Cursor נתקע על "Cursor is setting up its development environment" **שעות**:

1. **סגור את Cursor** לגמרי.
2. הרץ מתוך תיקיית הפרויקט:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/use-quick-devcontainer.ps1
   ```
3. פתח מחדש את Cursor ובחר **Reopen in Container** – ה-Container ייפתח מהר.
4. בתוך ה-Container: `poetry config virtualenvs.in-project true; poetry install`

**או** עבוד בלי Container: **File → Open Folder** (לא Reopen in Container), ואז הרץ `scripts/setup-venv-windows.ps1`.

---

## התקנת הכל (WSL + Docker) – הרצה כמנהל

אם אתה רוצה Dev Containers (Docker), הרץ **פעם אחת** כמנהל:

1. לחץ ימני על `scripts\install-all-windows.ps1`
2. בחר **Run with PowerShell**
3. אם מופיעה אזהרה – בחר "Run anyway" או הפעל קודם:  
   `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
4. אם נדרש – הפעל מחדש את המחשב והרץ את הסקריפט שוב עד ש-Docker מותקן.

---

## שלב 1: בדיקת דרישות מקדימות ✅

| כלי | גרסה נדרשת | סטטוס |
|-----|------------|-------|
| Python | 3.12.x | ✅ מותקן |
| Node.js | 22+ | ✅ מותקן |
| Poetry | 1.8+ | ✅ מותקן |

## שלב 2: התקנת תלויות Python

(כדי שה-IDE ו-Pyright ימצאו את הסביבה, מומלץ ליצור `.venv` בתוך הפרויקט.)

**אפשרות א' – סקריפט (מומלץ):** הרץ מתוך תיקיית הפרויקט:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-venv-windows.ps1
```

**אפשרות ב' – ידני:**

```powershell
cd C:\Users\nchma\OpenHands
poetry config virtualenvs.in-project true
poetry env use "C:\Users\nchma\AppData\Local\Programs\Python\Python312\python.exe"
poetry install --with dev,test,runtime
```

אחרי ההתקנה: ב-Cursor/VS Code בחר **Python: Select Interpreter** ובחר `.venv\Scripts\python.exe`.

## שלב 3: התקנת Playwright (אופציונלי - לדפדפן)

```powershell
poetry run playwright install chromium
```

## שלב 4: התקנת תלויות Frontend

```powershell
cd frontend
npm install
npm run build
cd ..
```

## שלב 5: הרצת האפליקציה

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-windows.ps1
```

או בשני טרמינלים נפרדים:

**טרמינל 1 - Backend:**
```powershell
poetry run uvicorn openhands.server.listen:app --host 127.0.0.1 --port 3000
```

**טרמינל 2 - Frontend:**
```powershell
cd frontend
$env:VITE_BACKEND_HOST="127.0.0.1:3000"
$env:VITE_FRONTEND_PORT="3001"
npm run dev -- --port 3001 --host 127.0.0.1
```

## גישה לאפליקציה

פתח בדפדפן: **http://localhost:3001**

---

## אחרי התקנת Docker

- **Docker Desktop** הופעל – חכה עד שהאייקון בתחתית המסך יהיה ירוק.
- **Reopen in Container:** סגור את Cursor/VS Code, פתח מחדש את התיקייה, ובחר "Reopen in Container" (או: Command Palette → `Dev Containers: Reopen in Container`).
- אם `docker` לא מזוהה בטרמינל – פתח טרמינל חדש או הפעל מחדש את Cursor.
