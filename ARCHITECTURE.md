# Structory — Architecture

*Architecture telle que le code la démontre (audit 2026-08-16). Quand le code diverge du schéma cible du deck, la divergence est indiquée.*

---

## 1. Les quatre couches

### Couche 1 — Own Storage : le stockage de chaque organisation (Google Drive)

C'est la fondation. Chaque organisation possède un dossier Drive **à elle**, qui contient toute sa vérité :

| Contenu du dossier de l'org | Rôle |
|---|---|
| `journal.ledger` | **La source de vérité** — journal comptable en partie double, texte brut |
| `Organisation_*.json`, `User_*.json`, `Compte_*.json`, `Rule_*.json` | Les briques (une brique = un fichier JSON) |
| `_releves/*.jsonl` | Relevés bancaires sanctuarisés, append-only, jamais réécrits |
| `_secrets/` | Secrets chiffrés (Fernet) avec une clé propre à l'org |

Le serveur Structory n'y accède que par un compte de service, en lecture et mise à jour. Il n'est jamais propriétaire.

### Couche 2 — Les services (VPS, systemd, tous actifs)

| Service | Port | Rôle | Code |
|---|---|---|---|
| **ledger_api** | 8080 | Le journal : écriture, requêtes, FEC, points temporels, règles PCG, contrôle des rôles | `ledger_api/app.py` |
| **analyzor** | 8000 | Le registre : orgs, briques, cascade de règles, Own Storage, secrets, Docling, LLM, journal technique | `analyzor/main.py` |
| **executor** | 8084 | L'orchestrateur : connecteurs bancaires, points de solde, patrimoine, rapports — **sans stockage propre** | `executor/app.py` |
| **subscriptions_api** | 8082 | L'identité : users, orgs, membres, rôles, connexion par lien magique, Stripe | `subscriptions_api/app.py` |
| **jdb_api** | 8086 | Journal de Banque : file de propositions → validation humaine → injection au journal | `jdb_api/app.py` |

À côté : Ollama (LLM local) et le binaire ledger-cli.

### Couche 3 — Les frontends (Google Apps Script)

| Frontend | Rôle |
|---|---|
| **Bibliotheque** | Library partagée : un fichier `Connector*.js` par service backend + `ConnectorIdentity.js` (briques, création d'org BYOS) |
| **Navigator** | L'« OS » : journal au centre, Objects / Flows / Rules / Time autour ; auth par lien magique + rôle |
| **Communicator** | Le chat : phrase libre → intent → action (écriture, solde, requête) ; intégrable en iframe |
| **org-onboarding** | Création d'org dans le Drive du visiteur, sous sa propre identité Google |
| **Add-ons Sheets** | `structory-sheets` (générique), `compta-copro-addon`, `structory-demo-addon`, SheetToCSV (Marketplace) |

### Couche 4 — Les sites (Cloudflare)

`structory.ai` (+ /smc, /comptacopro, /compta, /jdb, /game, 10 langues) · `precogn.org` · `llm.precogn.org` (routeur LLM). Le site fait aussi proxy `/api/*` vers Analyzor.

---

## 2. Le schéma du deck face au code

Le deck présente : **Core (Journal + Objects/Flows/Rules/Time) · Executor · Connectors · Navigator · Communicator · Own Storage**.

Verdict : **conceptuellement fidèle, physiquement transversal**. Il n'existe pas un package « Core » unique ; chaque brique vit là où elle sert :

| Brique du deck | Où elle vit dans le code | État |
|---|---|---|
| **Journal** | `ledger_api` (calcul) + Drive de l'org (stockage) | ✅ central, en production |
| **Objects** | enveloppe commune `ConnectorIdentity.js:33` + `analyzor/bricks.py` ; fichiers JSON dans le Drive | ✅ en production |
| **Rules** | cascade PreCogn → Structory → module → org, `analyzor/config_resolver.py` | ✅ en production |
| **Flows** | objets d'état `executor/core/flow.py` + chaînes câblées → journal | ⚠️ partiel — pas encore de registre générique |
| **Time** | vues dérivées du journal (`/time-points`, `/patrimoine-at`) | ⚠️ dérivé, pas de store |
| **Executor** | `executor/` — orchestration pure, zéro stockage | ✅ |
| **Connectors** | 2 agrégateurs (Powens, Enable Banking) + 2 API directes de banques d'orgs (Mercury, Qonto) + Docling + Ollama + Drive + email sortant | ✅ |
| **Navigator / Communicator** | Apps Script, org-agnostiques (tout est piloté par `orgId`) | ✅ |
| **Own Storage / BYOS** | Google Drive (seul backend aujourd'hui) | ✅ v1 |

---

## 3. Cinq flux, tracés de bout en bout dans le code

**Flux A — Créer une organisation (BYOS)**
1. L'utilisateur colle un lien vers son Drive (`org-onboarding`).
2. `identityCreateOrg` crée le sous-dossier, écrit les briques Organisation + User(owner), partage au compte de service, enregistre l'adresse (`ConnectorIdentity.js:82`).
3. Le journal est créé **sous l'identité de l'utilisateur** — le compte de service n'a pas le droit de créer des fichiers Drive, par conception.
4. L'org est enregistrée côté identité (`subscriptions_api`).

**Flux B — Écrire une opération par le chat**
1. Phrase libre dans Communicator (`Code.js:318`).
2. Compréhension : regex déterministes, sinon LLM (`analyzor/understand.py` : embeddings → intent structuré).
3. Écriture : `ledger_api /api/ledger/entry` — clé de service + email de l'utilisateur exigés.
4. Contrôle du rôle (viewer refusé), classification PCG par les règles, écriture taguée `structory_user`.
5. Le journal du Drive de l'org est mis à jour.

**Flux C — Point de solde bancaire**
1. Demande depuis Communicator ou Navigator.
2. `executor /api/executor/balance-point`.
3. L'Executor demande aux **règles** quel connecteur utiliser (`analyzor /api/connectors/resolve`) — il ne choisit jamais lui-même.
4. Le connecteur (Powens, Enable Banking, Mercury ou Qonto) rapporte le solde.
5. Écriture d'ajustement dans le journal → visible dans la chronologie (Time).

**Flux D — Journal de Banque (validation humaine)**
1. `jdb_api /pull` récupère les transactions via l'Executor.
2. Sanctuarisation : append au relevé intangible de l'org.
3. Mise en file comme **propositions**.
4. Un utilisateur editor/owner valide (contrepartie PCG suggérée automatiquement).
5. Injection au journal par `ledger_api /import`. Rien n'entre au journal sans validation.

**Flux E — Lire (Navigator)**
Balance, grand livre, FEC, patrimoine, chronologie : chaque vue relance le calcul sur le journal. Aucun état stocké, donc aucun état à synchroniser.

---

## 4. Construire une application au-dessus du Core

Une application Structory = **une org + un module de règles + (option) une UI**. Pas de base de données propre, pas de schéma propre.

| Pour ajouter… | Il faut… | Démontré par |
|---|---|---|
| une organisation | un dossier Drive + un journal + des briques | 12 orgs existantes |
| une verticale métier | un module de briques Rule (ex. PCG copro) | Compta Copro, SMC, JdB, Ma Compta |
| une banque | une brique Rule + un fichier `connector_<banque>.py` | Powens, Enable Banking, Mercury, Qonto |
| une UI | Navigator/Communicator paramétrés par `orgId`, ou un add-on Sheets | structory-sheets, compta-copro-addon |

C'est la démonstration du « un seul Core, des organisations multiples » du deck : quatre applications live partagent les cinq mêmes services et le même format de journal.

---

## 5. Les choix d'architecture et leur prix

| Choix | Ce qu'il apporte | Ce qu'il coûte |
|---|---|---|
| Journal texte dans le Drive du client | souveraineté, auditabilité, zéro lock-in | re-téléchargement à chaque appel (cache à venir) |
| État recalculé, jamais stocké | cohérence par construction | CPU proportionnel à la taille du journal |
| Executor sans stockage, piloté par les règles | connecteurs interchangeables | registre de flows générique encore à construire |
| Frontends Apps Script | identité Google et Drive natifs, coût nul | quotas Google, outillage limité |
| Secrets chiffrés par org, clé dans le Drive de l'org | une compromission ne touche qu'une org | bootstrap plus complexe |
| LLM local (Ollama) par défaut | aucune donnée envoyée à un tiers | qualité d'un petit modèle ; repli cloud prévu |

---

## 6. Ce qui reste à construire

Registre de flows invocables par nom · auth uniforme + TLS + pare-feu · API publiée et versionnée · backends Own Storage supplémentaires (S3, local) · tests + CI · conteneurisation.
