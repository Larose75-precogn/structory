# Structory — Quickstart (15 minutes)

*Comprendre et voir tourner Structory : d'abord les démos publiques (0 installation), puis le principe reproduit en local en 5 minutes. Tout ce qui est référencé existe ; rien n'a été créé pour ce document.*

## 0. Le principe en une phrase

> Une organisation = un **journal** texte en partie double, dans **son propre** stockage. Tout le reste — balance, grand livre, bilan, FEC, patrimoine, chronologie — est **recalculé** à la demande. Les connecteurs (banques, documents, chat, agents) ne font qu'**ajouter des événements** au journal.

## 1. Démos publiques — une seule règle, la même pour toutes les applications

> **La règle** : chaque application a sa page sur structory.ai, avec un bouton **Démo** qui ouvre Navigator sur une organisation de démonstration (données anonymisées). Aucune installation, aucun compte.

| Application | Page | Démo |
|---|---|---|
| **Structory Compta** | structory.ai/compta | Navigator, org `structory_demo` — journal au centre, Objects (comptes réels du ledger), Flows (balance, grand livre, FEC), Rules, Time, chat intégré |
| **Suivre mes comptes** | structory.ai/smc | Navigator, org `smcdemo` — patrimoine multi-comptes/devises, points de solde, chronologie |
| **Compta Copro** | structory.ai/comptacopro | même règle — démo en cours d'ouverture publique |
| **Journal de Banque** | structory.ai/jdb | même règle — démo en cours d'ouverture publique |

Bonus visuel : structory.ai/game — le journal d'une organisation animé en « rivière » de flux.

## 2. L'exemple minimal, tracé dans le code (~5 min de lecture)

Chaîne **entrée → Flow → invocation → Executor → événement → journal / storage**, telle qu'elle existe :

| Étape | Ce qui se passe | Code |
|---|---|---|
| 1. Entrée | L'utilisateur tape « point de solde LCL » dans le chat | `communicator/Code.js:318` |
| 2. Compréhension | Regex déterministes, sinon LLM : embeddings → intent structuré | `analyzor/understand.py` |
| 3. Invocation | Le chat invoque l'Executor | `bibliotheque/ConnectorExecutor.js` → `POST /api/executor/balance-point` |
| 4. Executor | Demande aux **règles** quel connecteur utiliser, puis interroge la banque | `executor/app.py:1224`, `analyzor/config_resolver.py` |
| 5. Événement | Écriture d'ajustement, taguée avec l'email de l'utilisateur | `ledger_api/app.py:959`, `pcg_rules.py` |
| 6. Journal / storage | Ajout au `journal.ledger`, puis mise à jour du fichier **dans le Drive de l'org** | `ledger_api/app.py:133` |

Variante écriture manuelle : chat → `POST /api/ledger/entry` (clé de service + email + rôle exigés) → journal.

## 3. Reproduire le principe en local (~5 min, sans les services)

Seul ledger-cli suffit pour vérifier « journal → états recalculés » :

```bash
# Debian/Ubuntu : sudo apt install ledger   |   macOS : brew install ledger
cat > journal.ledger <<'EOF'
2026-03-12 * Facture EDF #2214
    Charges:Energie              182.40 EUR
    Fournisseurs:EDF

2026-03-14 * Appel de fonds T2
    Creances:Lot-12              431.00 EUR
    Produits:Charges

2026-03-15 * Encaissement banque
    Actif:Banque                 431.00 EUR
    Creances:Lot-12
EOF

ledger -f journal.ledger balance                # bilan instantané, jamais stocké
ledger -f journal.ledger register Actif         # grand livre d'un compte
ledger -f journal.ledger bal --end 2026-03-13   # l'état À UNE DATE = rejeu du journal
```

C'est exactement ce que fait le service : `ledger -f orgs/<org>/journal.ledger <commande>` en sous-processus (`ledger_api/app.py:407`).

## 4. Faire tourner un service en local (~5 min)

```bash
git clone https://github.com/Larose75-precogn/ledger_api && cd ledger_api
python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt
mkdir -p orgs/demo && cp ../journal.ledger orgs/demo/journal.ledger
python app.py                                    # :8080

curl -s http://127.0.0.1:8080/api/health
curl -s -X POST http://127.0.0.1:8080/api/ledger/query \
     -H 'Content-Type: application/json' \
     -d '{"orgId":"demo","command":"balance"}'
```

La lecture est ouverte ; l'écriture (`/api/ledger/entry`) exige une clé de service, l'email de l'utilisateur et un rôle `editor|owner` — sans le service d'identité en local, elle est refusée (comportement voulu, fail-closed).

## 5. Aller plus loin

L'onboarding BYOS complet (création d'une organisation dans le Drive du testeur, lien magique, Stripe en mode test) se fait en session guidée sur demande. Détail des limites connues : `DUE_DILIGENCE.md`.
