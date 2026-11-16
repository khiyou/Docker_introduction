# TP – Sécurisation d'une image et d'un conteneur Docker

Application : quiz Vite (fichiers statiques), conteneurisée puis sécurisée.

- **Dépôt Git :** _https://github.com/khiyou/Docker_introduction/_
- **Image publiée (Docker Hub) :** [`khiyou/quiz-docker:secure`](https://hub.docker.com/r/khiyou/quiz-docker), avec SBOM et provenance

## Livrables

| Livrable demandé | Emplacement |
|---|---|
| Dockerfile initial | [`Dockerfile.initial`](Dockerfile.initial) |
| Dockerfile sécurisé | [`Dockerfile`](Dockerfile), plus la variante Docker Hardened Images [`Dockerfile.dhi`](Dockerfile.dhi) (mission 4) |
| Fichier .dockerignore | [`.dockerignore`](.dockerignore) |
| Commandes de construction et d'exécution | [`COMMANDES.md`](COMMANDES.md) |
| Résultats des analyses avant / après | [`audit/analyses/`](audit/analyses/) : `1-initial`, `2-secure`, `3-dockerhub`, `4-dhi` |
| Tableau comparatif complété | Ci-dessous et dans [`audit/rapports/mission3-comparatif.pdf`](audit/rapports/mission3-comparatif.pdf) |
| Synthèse : améliorations et risques résiduels | Ci-dessous |
| Rapports détaillés par mission | [`audit/rapports/`](audit/rapports/) |
| Capture de l'application fonctionnelle | [`audit/captures/`](audit/captures/) |

## Tableau comparatif

| Critère | Initiale | Sécurisée | DHI |
|---|---|---|---|
| Image de base (exécution) | `node:27.0.0-alpha` (préversion) | `nginx-unprivileged:1.30-alpine-slim` + `apk upgrade` | `dhi.io/nginx:1.30-alpine3.23` |
| Outils de développement | node, npm, serve, apk | apk | aucun gestionnaire de paquets |
| `.dockerignore` | non | oui | oui |
| Multi-stage build | non | oui | oui |
| Utilisateur | root | 101 | 65532 |
| Système de fichiers | lecture / écriture | lecture seule | lecture seule |
| Capacités Linux | par défaut | toutes retirées | toutes retirées |
| `no-new-privileges` | non | oui | oui |
| Limitation des ressources | aucune | 128 Mo, 0,5 CPU, 100 processus | 128 Mo, 0,5 CPU, 100 processus |
| Accès au socket Docker | non | non | non |
| Taille (disque / compressée) | 308 Mo / 75,5 Mo | 33,3 Mo / 9,2 Mo | 16,7 Mo / 4,5 Mo |
| Paquets | 239 | 26 | 15 |
| CVE critiques | 1 | 0 | 0 |
| CVE élevées | 6 | 1 | 0 |
| CVE moyennes | 13 | 0 | 0 |
| CVE faibles | 1 | 0 | 0 |
| CVE non classées | 0 | 5 | 0 |
| SBOM / provenance | non | oui (à la publication) | fournis par Docker (14 attestations) |
| Politiques Docker Scout | 3/7, score D (50 %) | 5/7, score B (72 %) sur Docker Hub | 5/7, score B (78 %) en local |

## Synthèse

### Améliorations apportées

- **Build multi-étapes** : Node, npm, serve et les sources ne servent qu'au build. L'image finale ne contient que `dist/` (57 ko) et un serveur nginx. Cela retire 213 paquets et toutes les CVE des dépendances npm.
- **Image de base maintenue et minimale** : la préversion `node:27 alpha` est remplacée par nginx 1.30, la branche stable, en variante `alpine-slim`, avec `apk upgrade` au build. Une première tentative sur nginx 1.28, en fin de vie, avait fait monter l'image à 200 CVE. Elle a été corrigée.
- **Exécution non-root** (utilisateur 101) sur un port non privilégié (8080).
- **Restrictions d'exécution** : système de fichiers en lecture seule, `--cap-drop ALL`, `no-new-privileges`, limites de mémoire, de CPU et de processus, aucun accès au socket Docker.
- **Reproductibilité** : `npm ci`, image Node épinglée par digest, `.dockerignore`.
- **Chaîne d'approvisionnement** : publication avec SBOM et provenance SLSA.
- **Résultat** : de 21 CVE (1 critique, 6 élevées) à 1 CVE élevée, et une image 9 fois plus légère. Avec la Docker Hardened Image : 0 CVE et une image 18 fois plus légère.

### Risques résiduels

- **CVE restantes** dans l'image sécurisée : 1 élevée (musl) et 5 non classées (openssl). Leurs correctifs n'étaient pas encore publiés dans les dépôts Alpine au moment du build, il faudra reconstruire l'image.
- **Shell busybox présent**, ainsi qu'`apk` dans l'image sécurisée. Ils sont neutralisés par le non-root et la lecture seule, mais restent exploitables.
- **Vieillissement de l'image** : de nouvelles CVE paraissent chaque jour, donc il faut reconstruire et scanner régulièrement.
- **Restrictions dépendantes du lancement** : elles ne s'appliquent que si le conteneur est lancé avec les bonnes options (`docker run`, Compose ou orchestrateur).
- **Hors périmètre du TP** : la sécurité applicative (HTTPS, en-têtes HTTP), celle de l'hôte et celle du réseau.
- **Licences copyleft** présentes (busybox, musl…), à valider côté juridique.

**Recommandation pour la production :** utiliser la variante Docker Hardened Image, publiée avec SBOM et provenance, conserver les restrictions d'exécution, et automatiser la reconstruction et le scan Docker Scout en CI.

---

<details>
<summary>Énoncé d'origine de l'exercice</summary>

Ce repository contient une application Node.js, et vous devez la faire fonctionner dans un conteneur.
Aucune modification de l'application ne devrait être nécessaire, seules les modifications du Dockerfile dans ce répertoire sont requises.

</details>
