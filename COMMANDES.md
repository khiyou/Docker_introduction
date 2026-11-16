# Commandes utilisées

Environnement : Windows, PowerShell, Docker Desktop (linux/amd64).
Les sorties des commandes d'analyse sont dans [`audit/analyses/`](audit/analyses/).

## 1. Image initiale (`Dockerfile.initial`)

```powershell
# Construction
docker build -f Dockerfile.initial -t quiz-docker:initial .

# Exécution (aucune restriction)
docker run -d --name quiz-initial -p 3000:3000 quiz-docker:initial

# Audit
docker images quiz-docker                                  # taille
docker history --no-trunc quiz-docker:initial              # couches
docker inspect --format "{{.Config.User}}" quiz-docker:initial   # utilisateur
docker scout quickview quiz-docker:initial                 # résumé CVE + politiques
docker scout cves quiz-docker:initial                      # détail des CVE
```

## 2. Image sécurisée (`Dockerfile`)

```powershell
# Construction (images de base à jour)
docker build --pull --no-cache -t quiz-docker:secure .

# Exécution avec restriction des privilèges et des ressources
docker run -d --name quiz-secure -p 3001:8080 `
  --read-only --tmpfs /tmp `
  --cap-drop ALL `
  --security-opt no-new-privileges `
  --memory 128m --cpus 0.5 --pids-limit 100 `
  quiz-docker:secure

# Analyse
docker scout quickview quiz-docker:secure
docker scout cves quiz-docker:secure
docker scout compare quiz-docker:secure --to quiz-docker:initial
```

## 3. Publication sur Docker Hub (avec SBOM et provenance)

```powershell
docker login
docker buildx create --name secure-builder --driver docker-container --use
docker buildx build --pull --sbom=true --provenance=mode=max `
  -t khiyou/quiz-docker:secure --push .
docker buildx imagetools inspect khiyou/quiz-docker:secure
docker scout quickview registry://khiyou/quiz-docker:secure

# Exécution depuis le registre
docker run -d --name quiz-hub -p 3001:8080 `
  --read-only --tmpfs /tmp --cap-drop ALL `
  --security-opt no-new-privileges `
  --memory 128m --cpus 0.5 --pids-limit 100 `
  khiyou/quiz-docker:secure
```

## 4. Docker Hardened Image (`Dockerfile.dhi`)

```powershell
docker login dhi.io
docker build -f Dockerfile.dhi -t quiz-docker:dhi .

docker run -d --name quiz-dhi -p 3002:8080 --read-only `
  --tmpfs /tmp `
  --tmpfs /var/cache/nginx:uid=65532,gid=65532 `
  --tmpfs /var/run:uid=65532,gid=65532 `
  --cap-drop ALL --security-opt no-new-privileges `
  --memory 128m --cpus 0.5 --pids-limit 100 `
  quiz-docker:dhi

docker scout quickview quiz-docker:dhi
docker scout cves quiz-docker:dhi
docker scout compare quiz-docker:dhi --to quiz-docker:secure
docker scout attest list dhi.io/nginx:1.30-alpine3.23

# Atelier officiel Docker
docker compose -p labspace -f oci://dockersamples/labspace-dhi-node up -d   # http://localhost:3030
docker compose -p labspace down
```

## Vérifications communes

```powershell
# Outils présents dans l'image
docker run --rm --entrypoint sh <image> -c "which node npm serve curl apk"

# Restrictions réellement appliquées au conteneur
docker inspect --format "User={{.Config.User}} ReadOnly={{.HostConfig.ReadonlyRootfs}} CapDrop={{.HostConfig.CapDrop}} SecOpt={{.HostConfig.SecurityOpt}} Memory={{.HostConfig.Memory}} NanoCpus={{.HostConfig.NanoCpus}} Pids={{.HostConfig.PidsLimit}} Mounts={{json .Mounts}}" <conteneur>
```
