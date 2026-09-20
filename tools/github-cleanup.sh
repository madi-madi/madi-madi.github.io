#!/usr/bin/env bash
# Clean up the public GitHub profile: hide learning repos, fix language
# detection, describe and pin what's left.
#
#   ./github-cleanup.sh          # dry run — prints the plan, changes nothing
#   ./github-cleanup.sh --apply  # actually does it
#
# Requires: gh auth login -s repo,delete_repo,read:user

set -uo pipefail
OWNER="madi-madi"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

c(){ printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
run(){ if (( APPLY )); then "$@"; else c '2;37' "      would run: $*"; fi; }

command -v gh >/dev/null || { c '1;31' "gh is not installed. See the README."; exit 1; }
gh auth status >/dev/null 2>&1 || { c '1;31' "Not logged in. Run: gh auth login -s repo,delete_repo,read:user"; exit 1; }

# Repos that stay public. Everything else public and non-forked goes private.
KEEP=(
  madi-madi
  madi-madi.github.io
  laravel_nuxt_api
  laravel-with-docker
  Laravel-with-Firebase
  fcmapp
  quran-app
  Design-House-Nuxtjs
  ecommerce-shopping
)

# Descriptions worth reading. A repo with no description reads as abandoned.
declare -A DESC=(
  [laravel_nuxt_api]="Laravel REST API with a Nuxt.js front end — token auth, resource controllers, SPA consumption."
  [laravel-with-docker]="Dockerised Laravel stack: PHP-FPM, Nginx, MySQL and Redis in one compose file."
  [Laravel-with-Firebase]="Laravel integrated with Firebase — realtime data and authentication."
  [fcmapp]="Firebase Cloud Messaging push notifications from Laravel, including topic and device targeting."
  [quran-app]="Quran reader for Android, written in Kotlin."
  [Design-House-Nuxtjs]="Nuxt.js marketing site — SSR, routing and component structure."
  [ecommerce-shopping]="E-commerce store in Laravel and Vue with Pusher for realtime cart and order events."
)

declare -A TOPICS=(
  [laravel_nuxt_api]="laravel php nuxtjs vuejs rest-api"
  [laravel-with-docker]="laravel docker docker-compose php nginx"
  [Laravel-with-Firebase]="laravel firebase php realtime"
  [fcmapp]="laravel firebase fcm push-notifications php"
  [quran-app]="kotlin android quran"
  [Design-House-Nuxtjs]="nuxtjs vuejs ssr javascript"
  [ecommerce-shopping]="laravel vuejs pusher ecommerce php"
)

in_keep(){ local n=$1; for k in "${KEEP[@]}"; do [[ $k == "$n" ]] && return 0; done; return 1; }

c '1;36' "Reading $OWNER's repositories…"
mapfile -t ROWS < <(gh repo list "$OWNER" --limit 200 \
  --json name,isPrivate,isFork,isArchived,description \
  --jq '.[] | [.name, .isPrivate, .isFork, .isArchived, (.description // "")] | @tsv')
c '2;37' "  ${#ROWS[@]} repositories"
echo

TO_PRIVATE=(); FORKS=(); KEPT=()
for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r name priv fork arch _d <<<"$row"
  [[ $priv == "true" ]] && continue
  if in_keep "$name"; then KEPT+=("$name")
  elif [[ $fork == "true" ]]; then FORKS+=("$name")
  else TO_PRIVATE+=("$name"); fi
done

(( APPLY )) || c '1;33' "DRY RUN — nothing will change. Re-run with --apply.\n"

# ---- 1. hide the noise ------------------------------------------------------
c '1;36' "1. Making ${#TO_PRIVATE[@]} learning repos private (reversible any time)"
for n in "${TO_PRIVATE[@]}"; do
  echo "   · $n"
  run gh repo edit "$OWNER/$n" --visibility private --accept-visibility-change-consequences
done
echo

# ---- 2. forks ---------------------------------------------------------------
# GitHub will not let a fork of a public repo become private, so these can only
# be deleted. Deleting a fork loses nothing — upstream still exists.
c '1;36' "2. Forks that add nothing to the profile (${#FORKS[@]})"
for n in "${FORKS[@]}"; do echo "   · $n"; done
if (( ${#FORKS[@]} )); then
  if (( APPLY )); then
    read -rp "   Delete these forks? This cannot be undone. [y/N] " ans
    if [[ $ans == [yY] ]]; then
      for n in "${FORKS[@]}"; do gh repo delete "$OWNER/$n" --yes && echo "   deleted $n"; done
    else
      c '2;37' "   skipped"
    fi
  else
    c '2;37' "      would prompt before deleting"
  fi
fi
echo

# ---- 3. fix language detection ---------------------------------------------
# Laravel repos show up as "HTML" or "CSS" because committed vendor and build
# output outweighs the PHP. .gitattributes tells Linguist to ignore them.
c '1;36' "3. Fixing detected language on the repos that stay"
GITATTR='public/** linguist-vendored
vendor/** linguist-vendored
node_modules/** linguist-vendored
resources/views/** linguist-language=Blade
*.blade.php linguist-language=Blade
dist/** linguist-generated
*.lock linguist-generated
'
B64=$(printf '%s' "$GITATTR" | base64 -w0)
for n in "${KEPT[@]}"; do
  [[ $n == "madi-madi" || $n == "madi-madi.github.io" ]] && continue
  echo "   · $n"
  if (( APPLY )); then
    if gh api "repos/$OWNER/$n/contents/.gitattributes" >/dev/null 2>&1; then
      c '2;37' "      already has .gitattributes — skipped"
    else
      gh api "repos/$OWNER/$n/contents/.gitattributes" -X PUT \
        -f message="Ignore vendored and generated files in language stats" \
        -f content="$B64" >/dev/null && c '2;32' "      added"
    fi
  else
    c '2;37' "      would add .gitattributes"
  fi
done
echo

# ---- 4. descriptions and topics --------------------------------------------
c '1;36' "4. Descriptions and topics"
for n in "${KEPT[@]}"; do
  [[ -z "${DESC[$n]:-}" ]] && continue
  echo "   · $n"
  run gh repo edit "$OWNER/$n" --description "${DESC[$n]}"
  if [[ -n "${TOPICS[$n]:-}" ]]; then
    for t in ${TOPICS[$n]}; do run gh repo edit "$OWNER/$n" --add-topic "$t"; done
  fi
done
echo

# ---- 5. pin the survivors ---------------------------------------------------
c '1;36' "5. Pinning the profile repositories"
PIN=(madi-madi.github.io laravel_nuxt_api ecommerce-shopping laravel-with-docker fcmapp quran-app)
IDS=""
for n in "${PIN[@]}"; do
  id=$(gh api "repos/$OWNER/$n" --jq .node_id 2>/dev/null) || continue
  IDS="$IDS\"$id\","
done
IDS="[${IDS%,}]"
echo "   ${PIN[*]}"
if (( APPLY )); then
  gh api graphql -f query="mutation{ replaceRepositoryPins(input:{repositoryIds:$IDS}){ clientMutationId } }" \
    >/dev/null && c '2;32' "   pinned"
else
  c '2;37' "      would pin via GraphQL"
fi
echo

c '1;32' "Done."
(( APPLY )) || c '1;33' "That was a dry run. Re-run with --apply to make it real."
