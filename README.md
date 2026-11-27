# 🏋️ FORGE Fitness Platform

A complete fitness & gym management ecosystem — including the public marketing website, multi-role SaaS portal, member digital pass PWA, super-admin console, and Node/MongoDB REST API.

---

## 📦 Project Structure

| App | Path | Live URL | Description |
| :--- | :--- | :--- | :--- |
| **Public Website** | `forge-gym/web/website` | [demo-web-forge-gym.onrender.com](https://demo-web-forge-gym.onrender.com/) | High-converting landing page & membership calculator |
| **SaaS Portal** | `forge-gym/web/saas` | [demo-web-gym-saas.onrender.com](https://demo-web-gym-saas.onrender.com/) | Multi-role management console (Owner, Staff, Trainer) |
| **Member App** | `forge-gym/web/member` | [demo-web-gym-member.onrender.com](https://demo-web-gym-member.onrender.com/) | Digital gym pass, QR check-in, and workout tracking |
| **Admin Console** | `forge-gym/web/admin` | — | Super-admin platform management |
| **REST API** | `forge-gym/api` | [forge-gym-api.onrender.com](https://forge-gym-api.onrender.com/) | Express + MongoDB backend service |
| **Mobile App** | `forge-gym/app` | — | Flutter mobile client |

---

## 🚀 Local Development

Run commands from the repository root:

```bash
# Start all services together (API + Web + SaaS + Admin + Member)
npm run dev

# Or run individual apps
npm run dev:api
npm run dev:web
npm run dev:saas
npm run dev:member
npm run dev:admin
```

### Build Commands
```bash
npm run build:web
npm run build:saas
npm run build:member
npm run build:admin
```

---

## ☁️ Deployment (Render)

Configured via [`render.yaml`](./render.yaml). Each web app deploys as a static site with its own `rootDir` (e.g. `forge-gym/web/website`), `npm install && npm run build`, and `dist` publish directory.
