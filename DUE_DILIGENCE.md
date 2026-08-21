# Structory — Due diligence technique (Q&A)

*Questions qu'un CTO / investisseur technique / fonds Pre-Seed posera, avec la réponse **telle que le code la démontre** (audit 2026-08-16), le fichier de référence, et — explicitement — ce qui n'est pas encore démontré. Légende : ✅ démontré · ⚠️ partiel · ❌ pas encore.*

## Architecture & journal

**Q1. Quelle est la source de vérité ?** ✅ Un `journal.ledger` (ledger-cli, partie double, texte) par organisation, stocké dans le Drive de l'org ; ledger_api n'en garde qu'une copie de travail retéléchargée à chaque appel — `ledger_api/app.py:96-133`.
**Q2. Les états sont-ils stockés ?** ✅ Non : balance/register/FEC/patrimoine/time-points sont recalculés par `ledger` en sous-processus à chaque requête — `app.py:407,876,1180`.
**Q3. Pourquoi ledger-cli et pas une base ?** ✅ Choix documenté (texte durable, auditable, Git-friendly, sans lock-in) — `projects/structory/AGENTS.md`, `projects/precogn/AGENTS.md`. Coût : latence de re-téléchargement Drive, CPU linéaire au journal (⚠️ non mesuré à grande échelle).
**Q4. Le modèle Objects/Flows/Rules/Time est-il dans le code ou dans le deck ?** ⚠️ Objects (enveloppe + briques Drive : `bibliotheque/ConnectorIdentity.js:33`, `analyzor/bricks.py`) et Rules (cascade : `analyzor/config_resolver.py`) sont réels et utilisés. Flows = objets d'état (`executor/core/flow.py`) + chaînes câblées. Time = vues dérivées. Il n'y a **pas** de package Core unifiant les quatre.
**Q5. Existe-t-il des flows invocables par nom ?** ❌ Non. Aucun registre/dispatch (`grep invocable|flow_registry|dispatch` → 1 commentaire). Deux chaînes complètes câblées existent (voir `QUICKSTART.md` §2). C'est un objectif du Pre-Seed.
**Q6. Comment les Connectors invoquent-ils des Flows ?** ⚠️ Entrants : Powens/Enable Banking/Docling produisent des événements normalisés → sanctuarisés → proposés (JdB) ou injectés (`ledger_api /import`). Sélection du connecteur = brique Rule (`resolve_connectors()`). Sortant : email via `communicator/Code.js:149`. Généralisation ❌.

## Scalabilité & exécution

**Q7. Combien d'orgs / d'écritures aujourd'hui ?** ✅ 12 orgs sur le VPS (4 tests, 4 démos, 3-4 réelles) ; journaux de 300-1 500 lignes ; ~250 requêtes ledger/7 j. ❌ Aucun test de charge.
**Q8. Que se passe-t-il à 10 000 orgs ?** ❌ Non démontré. Points d'attention connus : re-téléchargement Drive par appel (`app.py:96`), quotas Apps Script/Drive, ledger-cli mono-process. Levier : cache journal (existe pour les comptes : `/api/org/{id}/comptes/invalidate-cache`), file d'écriture, backends Own Storage alternatifs.
**Q9. Concurrence d'écriture ?** ⚠️ Verrou par org côté jdb_api (`jdb_api/app.py`), rien d'équivalent documenté dans ledger_api (Flask threadé). À vérifier.
**Q10. Observabilité ?** ⚠️ Journal technique append-only par org + Doc master (`analyzor/journal.py`, `journal_master.py`), logs systemd, `daily_report.sh` (executor), webhook d'alerte LLM (`llmprecogn/monitoring`). ❌ Pas de métriques/tracing/alerting structurés.

## Sécurité

**Q11. Comment sont authentifiés les appels ?** ⚠️ Écritures ledger/jdb : `X-Service-Key` + rôle résolu via subscriptions (`ledger_api/app.py:37-51`). **Mais** : une seule clé statique partagée entre tous les services et frontends, **en dur** dans du code versionné (`bibliotheque/ConnectorAccount.js:15`, `communicator/Code.js:147`, `navigator/Code.js:2921`, `executor/app.py:24`, `analyzor/main.py:424`) et dans les unités systemd. Rotation + Script Properties/env **prévues avant publication**.
**Q12. Les services sont-ils exposés ?** ❌ Oui : `0.0.0.0`, `ufw` inactif, HTTP sans TLS, et Analyzor :8000 sans auth sur `ownstorage/journal` (GET/POST), `releve/append`, `org/{id}/comptes`, `demo/reset` (`analyzor/main.py:1280,1291`). Executor :8084 sans auth. **Chantier n°1** : pare-feu, TLS (Cloudflare/nginx), clé sur toutes les routes d'écriture.
**Q13. Routes d'admin ?** ❌ Navigator expose `adminAction=copySheet|createCoproMenu|…` (`Code.js:154-191`) avant `authGate`, sur une web app anonyme exécutée sous l'identité du déployeur. À protéger.
**Q14. Secrets clients ?** ✅ Chiffrés Fernet avec une clé **par org** stockée dans le Drive de l'org (`analyzor/org_secrets.py`) ; jamais stockés côté Apps Script.
**Q15. Y a-t-il des secrets dans git ?** ⚠️ Pas de clés OpenAI/Anthropic/Stripe live/GitHub. Mais : la clé de service (Q11), 2 backups `subscriptions.db.bak.*` suivis et dans l'historique, `wrangler-account.json`, une clé Google Picker (navigateur, à vérifier restreinte), emails réels, ids d'orgs clientes dans les `CLAUDE.md`. Liste complète : `AUDIT_REPOSITORY.md` §3.
**Q16. Données personnelles ?** ⚠️ Données d'orgs (`ledger_api/orgs/`) et service account correctement hors git ; mais journal_tech (`analyzor/journals/`, transcripts) est suivi. Post-mortem d'une fuite corrigée (`smcdemo`, 2026-08-02) documenté.

## Multi-user, multi-organisation, permissions

**Q17. Multi-org ?** ✅ Une org = un slug + un dossier Drive + un journal ; hiérarchie `parent_org_id` ; accès inter-orgs sur demande (`subscriptions_api/app.py` `access/*`).
**Q18. Multi-user & rôles ?** ✅ `owner|editor|viewer` (`subscriptions_api/db.py:57-64`) ; **appliqués** à l'écriture dans ledger_api et jdb_api (viewer → 403) ; tag `structory_user` sur chaque écriture. ⚠️ Non appliqués au niveau DB (commentaire « pas encore appliqué ») ni sur les lectures.
**Q19. Authentification utilisateur ?** ✅ Magic-link email (`login_tokens`, `sessions`), `Session.getActiveUser` côté Apps Script, Navigator fail-closed si subscriptions injoignable (`navigator/Code.js:415`).
**Q20. Permissions fines (par compte, par brique) ?** ❌ `rights: "internal"` sur les briques, commentaire explicite « pas de droits fins aujourd'hui ».

## Persistence, BYOS, migration, lock-in

**Q21. Où sont les données ?** ✅ Drive de l'org (journal, briques, relevés, secrets) ; VPS : copies temporaires, `subscriptions.db` (SQLite), registres JSON Analyzor, staging JdB. **Q22. Autres backends que Drive ?** ❌ Non (`connector_ownstorage.py` = Drive seul ; 3 folder ids codés en dur `config_resolver.py:22-38`).
**Q23. Migration / sortie ?** ✅ Le client possède déjà tout en texte brut ledger + JSON + FEC ; lock-in structurellement minimal. ⚠️ Pas d'outil d'export « une commande ».
**Q24. Sauvegardes ?** ⚠️ Drive (versions Google) + `.bak` manuels ; ❌ pas de stratégie formalisée.
**Q25. Historique / auditabilité ?** ✅ Journal append, tag utilisateur, relevés « intangibles » append-only, journal technique par org avec acteurs `session:`/`git-commit:`.

## APIs, connecteurs, extensibilité

**Q26. API publique ?** ⚠️ ~100 routes JSON internes ; OpenAPI auto pour Analyzor (FastAPI `/docs`), pas pour Flask ; ❌ pas de versionnement, pas de doc publiée.
**Q27. Ajouter un connecteur ?** ✅ Un `connector_<x>.py` normalisant `{date, montant_signe, devise, libelle, source_id}` + une brique Rule (`etablissement`, `nature_couverte`) — pattern démontré quatre fois : deux agrégateurs (Powens, Enable Banking) et deux API directes de banques d'organisations (Mercury, Qonto), chacun isolé dans son fichier (« si la banque change son API, seul ce fichier change »).
**Q28. Ajouter une organisation verticale ?** ✅ Un module de briques Rule + une org + Navigator/Communicator paramétrés — 4 applications live le prouvent.
**Q29. Modules partenaires (deck) ?** ❌ Pas d'API/SDK partenaire ni Stripe Connect dans le code ; Stripe seat + PARTNER 1 € existent en **test mode** (`subscriptions_api/app.py:27-28` refuse `sk_live`).

## LLM & agents

**Q30. Quels modèles, où ?** ✅ Ollama local (`qwen2.5-coder:3b`, `nomic-embed-text`) par défaut (`analyzor/connector_ollama.py`), repli routeur cloud `llm.precogn.org` (groq→cerebras→deepseek→google, `projects/llmprecogn/worker/worker.js`). ❌ Aucun SDK OpenAI/Anthropic. **Q31. Que fait le LLM ?** ✅ `understand.py` : retrieval de briques par embeddings → intent structuré `{intent, libelle, montant, sens, compteNom}` ; Docling pour les documents. **Q32. Les agents écrivent-ils dans le journal ?** ⚠️ Via Communicator oui (sous rôle) ; les actions d'agents de code sont tracées dans le journal technique, pas dans le journal comptable. **Q33. MCP ?** ⚠️ Serveur MCP FastMCP existe (`llmprecogn/connector-mcp/server.py`), non déployé (`mcp.precogn.org` absent).

## Open source, licences, dépendances

**Q34. Licence ?** ❌ Aucune aujourd'hui (0/25 dépôts, GitHub `licenseInfo: null`) ; dépôts privés. Choix à faire avant publication (Apache-2.0 recommandé, AGPL à discuter). **Q35. Dépendances ?** ✅ 100 % permissives (MIT/BSD/Apache ; ledger-cli BSD-3 ; Docling MIT ; `certifi` MPL) — aucun copyleft fort. **Q36. Reproductibilité ?** ❌ `requirements.txt` seulement pour `executor` et `llmprecogn/connector-mcp` ; pas de lockfile, pas de conteneur, pas de CI. **Q37. Qu'est-ce qui reste commercial ?** ✅ Voir `AUDIT_REPOSITORY.md` §2 : opération de la plateforme, BYOS accompagné, verticales, connecteurs, enterprise, place de marché modules (1 €/brique).

## Tests & qualité

**Q38. Couverture de tests ?** ❌ 0 test backend (pytest absent) ; une vraie suite uniquement `projects/sheettocsv/Tests.js` (12 tests) ; smoke Godot. **Q39. Process de déploiement ?** ⚠️ Édition en place sur le VPS + `clasp push/deploy` (`release-structory.sh`) ; `.bak` à côté du code live ; `jdb_api` non versionné. **Q40. Post-mortems ?** ✅ Deux incidents documentés (fuite `smcdemo` 2026-08-02 ; écrasement du Worker prod 2026-08-03) avec cause et correctif.

## Modèle économique (côté code)

**Q41. Facturation implémentée ?** ⚠️ Stripe seats = (#orgs) + (#users) − 1, 4 paliers pays + FREE + PARTNER 1 € (`subscriptions_api/app.py`, `country_tiers.py`) — cohérent avec le deck (1 € = 1 org + 1 user, +1 €/brique) — **en test mode uniquement**. **Q42. Coût marginal par org ?** ✅ Structurellement bas (services partagés, Ollama local, stockage chez le client) ; ❌ non chiffré.

---

## Les 10 questions les plus dures (et la réponse honnête)

1. **« Pourquoi Analyzor est-il ouvert sur Internet sans auth ? »** — Dette opérationnelle, pas conceptuelle ; corrigée en priorité 1 avec le Pre-Seed (pare-feu/TLS/clé partout).
2. **« Une clé partagée en dur dans 5 fichiers ? »** — Oui, décision documentée à l'époque ; rotation + externalisation avant publication.
3. **« Où sont les tests ? »** — Il n'y en a pas côté backend ; le Pre-Seed finance tests + CI (ligne prestataires).
4. **« Le “Core Objects/Flows/Rules/Time” existe-t-il vraiment ? »** — Objects et Rules oui, Flows partiellement, Time dérivé ; pas de package unifié ; le registre de flows est l'objectif 2026.
5. **« Google Drive comme seul Own Storage, c'est du BYOS ? »** — C'en est la première implémentation ; l'abstraction vers S3/local est prévue, le format (texte + JSON) la rend triviale.
6. **« Ça tient à 10 000 orgs ? »** — Pas mesuré ; le re-téléchargement par appel devra être remplacé par un cache.
7. **« Pourquoi Apps Script pour les frontends ? »** — Identité Google et Drive gratuits et natifs, adaptés au BYOS ; coût : quotas et outillage ; migrable.
8. **« Un seul fondateur, code livré par agents — qui maintient ? »** — Doctrine et post-mortems écrits, architecture lisible ; le Pre-Seed finance une équipe de prestataires déjà en stand-by.
9. **« Open source sans licence, dépôts privés : c'est open source ? »** — Pas encore juridiquement ; c'est précisément l'un des livrables de la publication (licence, nettoyage, README).
10. **« Qu'est-ce qui empêche un concurrent de tout copier ? »** — Rien côté code, par choix ; la valeur capturée est l'opération, le réseau d'orgs/modules/connecteurs et la confiance née de la promesse « les données de chaque organisation restent chez elle ».
