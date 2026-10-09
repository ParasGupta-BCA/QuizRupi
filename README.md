# QuizRupi - Native Flutter Web Applications

This folder contains the complete, production-ready **Native Flutter Web** deployment for **QuizRupi**, pre-configured for instant **Vercel** deployment and **GitHub** publishing.

---

## 🌟 Dual Flutter Web Architecture

Both Flutter applications are configured to run seamlessly under a single Vercel deployment:

| Path | Application | Description |
| :--- | :--- | :--- |
| **`/`** | **QuizRupi Customer Web App** | The official customer app where users can register, play daily GK quizzes, join 1v1 arenas, track coins, and redeem physical books. |
| **`/admin/`** | **QuizRupi Admin Portal** | The responsive administrative dashboard for managing quizzes, questions, book inventory, user accounts, and remote app controls. |

---

## 📁 Repository Structure

```
Website Code/
├── 📱 Customer Web Distribution (Live at /):
│   ├── index.html                   # Customer Flutter Web entrypoint (base href="/")
│   ├── flutter.js                   # Flutter engine web loader
│   ├── flutter_bootstrap.js         # Flutter initialization script
│   ├── flutter_service_worker.js    # PWA service worker
│   ├── main.dart.js                 # Compiled customer Dart Web bundle (~3.4 MB)
│   ├── manifest.json                # PWA manifest
│   ├── favicon.png                  # App icon
│   ├── canvaskit/                   # CanvasKit WebAssembly rendering engine
│   ├── icons/                       # Touch & PWA icons
│   └── assets/                      # Fonts, images & Supabase assets
│
├── 🛡️ Admin Web Distribution (Live at /admin/):
│   └── admin/
│       ├── index.html               # Admin Flutter Web entrypoint (base href="/admin/")
│       ├── flutter.js
│       ├── flutter_bootstrap.js
│       ├── flutter_service_worker.js
│       ├── main.dart.js             # Compiled admin Dart Web bundle (~3.6 MB)
│       ├── manifest.json
│       ├── favicon.png
│       ├── canvaskit/
│       ├── icons/
│       └── assets/
│
├── 📦 source_code/                  # Full Flutter Source Code for both apps
│   ├── QuizRupi_Admin/              # Complete Flutter project for Admin (lib/, web/, pubspec.yaml)
│   └── Quiz_Customers/              # Complete Flutter project for Customer (lib/, web/, pubspec.yaml)
│
├── ⚙️ Deployment & CI/CD Config:
│   ├── vercel.json                  # Single-Page Application (SPA) rewrites for / and /admin/
│   ├── package.json                 # Static Node / Vercel project configuration
│   ├── .gitignore                   # Preserves compiled web distribution for Vercel
│   └── .github/workflows/deploy.yml # Optional GitHub Actions CI/CD workflow
└── 📄 README.md                     # Documentation & deployment guide
```

---

## 🚀 Step 1: Push Code to GitHub

Open **PowerShell** or **Command Prompt** inside this folder:
```powershell
cd "C:\Users\PARAS\Desktop\Paras Gupta\QuizRupi\Website Code"
```

Initialize your Git repository, commit, and push to GitHub:
```powershell
# 1. Initialize git
git init -b main

# 2. Add all files
git add .

# 3. Commit
git commit -m "Initial commit: QuizRupi Native Flutter Web (Customer + Admin)"

# 4. Link to your GitHub repository (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/quizrupi-flutter-web.git

# 5. Push to GitHub
git push -u origin main
```

---

## 🚀 Step 2: Deploy to Vercel

### Method A: Via Vercel Web Dashboard (1-Click & Recommended)
1. Go to [vercel.com](https://vercel.com) and log in.
2. Click **"Add New..."** → **"Project"**.
3. Select and import your newly created GitHub repository (`quizrupi-flutter-web`).
4. In the Project Configuration:
   - **Framework Preset**: `Other` (or leave default)
   - **Root Directory**: `./` (leave default)
   - **Build Command**: Leave empty / toggle OFF (files are already pre-compiled!)
   - **Output Directory**: Leave empty / toggle OFF
5. Click **"Deploy"**.
6. Within **10–15 seconds**, your Flutter website will be live across Vercel's global edge network!

### Method B: Via Vercel CLI
```powershell
cd "C:\Users\PARAS\Desktop\Paras Gupta\QuizRupi\Website Code"
npx vercel --prod
```

---

## 🔄 How to Re-compile Web Builds After Source Changes

If you modify Dart code in `source_code/`, re-compile the web distributions using Flutter:

### Re-compile Customer App (`/`):
```powershell
cd "C:\Users\PARAS\Desktop\Paras Gupta\QuizRupi\Website Code\source_code\Quiz_Customers"
flutter build web --release --base-href "/"
# Copy to root:
Copy-Item -Path "build\web\*" -Destination "..\..\" -Recurse -Force
```

### Re-compile Admin Portal (`/admin/`):
```powershell
cd "C:\Users\PARAS\Desktop\Paras Gupta\QuizRupi\Website Code\source_code\QuizRupi_Admin"
flutter build web --release --base-href "/admin/"
# Copy to admin folder:
Copy-Item -Path "build\web\*" -Destination "..\..\admin" -Recurse -Force
```

Then commit and push to GitHub:
```powershell
cd "C:\Users\PARAS\Desktop\Paras Gupta\QuizRupi\Website Code"
git add .
git commit -m "Update Flutter web builds"
git push
```
Vercel will automatically re-deploy your latest build!
