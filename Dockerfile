# ---------- Étape 1 : build ----------
# Node 24 LTS, épinglé par digest (contenu figé)
FROM node:24-alpine@sha256:116b800c3754b440ee0aa3ed2f20f5bf3d99a554bfd9adeea09ea8017f6e85f5 AS build
WORKDIR /app

# Dépendances d'abord (cache), installation exacte du lockfile
COPY package.json package-lock.json ./
RUN npm ci

# Sources (filtrées par .dockerignore), puis build
COPY . .
RUN npm run build

# ---------- Étape 2 : exécution ----------
# nginx 1.30 = branche stable maintenue ; variante "slim" = sans curl ni modules inutiles
FROM nginxinc/nginx-unprivileged:1.30-alpine-slim

# Applique les derniers correctifs de sécurité Alpine (nécessite root, le temps de cette étape)
USER root
RUN apk upgrade --no-cache

# Seul le résultat du build est copié (fichiers appartenant à root : non modifiables par nginx)
COPY --from=build /app/dist /usr/share/nginx/html

# Retour à l'utilisateur non privilégié
USER 101
EXPOSE 8080
