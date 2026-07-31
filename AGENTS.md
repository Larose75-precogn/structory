# Structory

Structory est une organisation fille de PreCogn dédiée à la structuration universelle des organisations sur la base de la partie double.

La première implémentation de Structory repose sur le journal (Ledger CLI), qui constitue le socle de représentation des événements d'une organisation.

Structory repose sur les principes fondamentaux de PreCogn :

- Object
- Flow
- Rule
- Time

Structory simplifie l'utilisation de ces briques grâce au journal en partie double, qui constitue une représentation universelle des événements et regroupe ces dimensions dans une structure équilibrée et traçable.

Le journal constitue une source de vérité immuable.

Les données et traitements restent sous le contrôle de l'organisation (BYOS).

## Principe fondamental

Le journal en partie double constitue la première implémentation de Structory.

Il représente une trace universelle, équilibrée et structurée des événements d'une organisation.

Tout événement doit pouvoir être représenté par une écriture équilibrée :

- Débit = Crédit
- Entrée / Sortie
- Input / Output
- Sens inverse et opérations de reverse

Le journal constitue une base permettant de construire tout ce que souhaite l'organisation :

- applications ;
- workflows ;
- automatisations ;
- analyses ;
- services métier.

## Architecture

Structory utilise les outils et principes d'architecture PreCogn.

Il s'appuie notamment sur :

- Navigator pour la visualisation et l'exploration ;
- Communicator pour les échanges entre composants ;
- Connectors pour les intégrations ;
- Analyzor pour la compréhension documentaire ;
- Intelligence pour les capacités d'analyse assistées par LLM.

## Règles de développement

Toute évolution Structory doit respecter :

- la cohérence du journal en partie double ;
- la traçabilité des événements ;
- la séparation entre données sources et compréhension ;
- la réversibilité des transformations ;
- les principes PreCogn.
