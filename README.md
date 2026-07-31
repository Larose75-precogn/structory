# PreCogn - Interactive Homepage

Homepage interactive réalisée avec Godot 4.7.

## Architecture

```
Phase 1 (idle)          Phase 2 (clic)           Phase 3 (+2s)
┌─────────────┐        ┌─────────────┐         ┌─────────────┐
│ Flow blanc  │  clic  │ Explosion   │  2s     │ PreCogn     │
│ respirant   │───────→│ 4 atomes    │────────→│ Universal   │
│ "Everything │        │ orbite+halo │         │ Objects...  │
│ starts with │        │             │         │ Let's play  │
│ a flow"     │        │             │         │             │
└─────────────┘        └─────────────┘         └─────────────┘
```

## Fichiers

| Fichier | Rôle |
|---------|------|
| `constants.gd` | Autoload - constantes globales (couleurs, timings, rayons) |
| `main.gd` | Orchestrateur - machine à états Phase 1 → 2 → 3 |
| `flow.gd` | Flow respirant organique, explosion, signal |
| `atom.gd` | Atomes en orbite avec halo coloré |
| `ui.gd` | UI - affichage progressif du contenu |
| `Main.tscn` | Scène principale |
| `flow.tscn` | Scène Flow |
| `Atom.tscn` | Scène Atome |

## Export HTML5

### Prérequis

- Godot 4.7 installé
- Templates d'export téléchargés (Editor → Manage Export Templates → Download)

### Build

```bash
./build.sh
```

Ou manuellement :

```bash
# Import
godot --headless --import

# Export
godot --headless --export-release "Web"
```

Les fichiers seront générés dans `export/web/` :
- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`
- `index.icon.png`
- `index.apple-touch-icon.png`

## Déploiement Cloudflare Worker

### Structure Worker

```
worker/
├── wrangler.toml
├── package.json
├── src/
│   └── index.js
└── public/          ← copier ici les fichiers export/web/
```

### Déploiement

```bash
# 1. Copier l'export dans worker/public/
cp -r export/web/* worker/public/

# 2. Installer les dépendances
cd worker
npm install

# 3. Déployer
npx wrangler deploy
```

### Headers requis

Le Worker ajoute automatiquement les headers nécessaires pour Godot Web :
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

Ces headers sont requis pour `SharedArrayBuffer` utilisé par Godot.

## Développement

### Tester localement

```bash
# Ouvrir dans Godot
godot

# Ou exporter et servir avec un serveur HTTP
./build.sh
cd export/web
python3 -m http.server 8000
# Ouvrir http://localhost:8000
```

### Modifier les constantes

Éditer `constants.gd` pour ajuster :
- Couleurs (`COLOR_*`)
- Rayon du Flow (`FLOW_BASE_RADIUS`)
- Vitesse de respiration (`FLOW_BREATH_SPEED`)
- Rayon d'orbite des atomes (`ATOM_ORBIT_RADIUS`)
- Timing Phase 2 → 3 (`PHASE2_TO_PHASE3_DELAY`)

## Licence

PreCogn - Universal Flow Engine
