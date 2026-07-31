# Déploiement PreCogn sur Cloudflare

## Fichiers prêts

Les fichiers HTML5 sont dans `worker/public/` :
- `index.html` - Page principale
- `index.js` - JavaScript Godot
- `index.wasm` - WebAssembly (38MB)
- `index.pck` - Ressources du jeu
- `index.png`, `index.icon.png` - Icônes
- `index.audio.worklet.js` - Audio

## Déploiement

### Option 1 : Depuis ta machine Windows

```powershell
# 1. Récupérer le projet
cd "D:\Users\Stéphane PLAISSY\Google Drive\Projets\structory"
git pull

# 2. Copier les fichiers exportés
Copy-Item -Path export\web\* -Destination worker\public\ -Recurse -Force

# 3. Déployer
cd worker
npm install
npx wrangler login
npx wrangler deploy
```

### Option 2 : Upload manuel sur Cloudflare

Si tu ne veux pas utiliser wrangler :

1. Va sur https://dash.cloudflare.com
2. Workers & Pages → Create → Upload assets
3. Nom : `precogn`
4. Upload tous les fichiers de `worker/public/`
5. Deploy

### Option 3 : Utiliser le Worker existant

Si tu as déjà un Worker sur precogn.org :

```powershell
cd worker
npx wrangler deploy
```

## Vérification

Après déploiement, visite https://precogn.org

Tu verras :
1. **Phase 1** : Flow blanc respirant + "Everything starts with a flow"
2. **Phase 2** (clic) : 4 atomes colorés en orbite
3. **Phase 3** (+2s) : Contenu PreCogn complet

## Problèmes

### Le site ne charge pas

Vérifie que les headers COOP/COEP sont bien envoyés :
```bash
curl -I https://precogn.org
```

Tu dois voir :
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

### Erreur SharedArrayBuffer

Godot Web nécessite ces headers pour fonctionner. Le Worker les ajoute automatiquement.

## Structure Worker

```
worker/
├── src/index.js          ← Worker avec headers
├── wrangler.toml         ← Config Cloudflare
├── package.json
└── public/               ← Fichiers Godot exportés
    ├── index.html
    ├── index.js
    ├── index.wasm
    └── ...
```
