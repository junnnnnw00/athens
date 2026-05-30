# Athens — common commands. Public client config lives in app/config/app_config.json
# (Supabase URL + publishable key + Spotify client id — all client-safe).
# Server secrets live ONLY in Supabase edge-function secrets, never here.

APP        := app
WEB        := web
DEFINE     := --dart-define-from-file=config/app_config.json
SEED       := --dart-define=DEV_SEED=true

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n",$$1,$$2}'

# ---- Flutter app (talks to the HOSTED Supabase; no local stack needed) ----
.PHONY: run run-seed analyze test itest goldens
run: ## Run the app on the default device against hosted backend
	cd $(APP) && flutter run $(DEFINE)
run-seed: ## Run with sample data seeded into the local Drift cache
	cd $(APP) && flutter run $(DEFINE) $(SEED)
analyze: ## flutter analyze
	cd $(APP) && flutter analyze
test: ## Unit + widget + golden tests
	cd $(APP) && flutter test
itest: ## Integration core-loop test (needs a device/display)
	cd $(APP) && flutter test integration_test
goldens: ## Regenerate committed golden screens
	cd $(APP) && flutter test --update-goldens test/golden/golden_test.dart

# ---- Builds ----
.PHONY: build-apk build-web
build-apk: ## Debug APK (needs JDK + Android SDK)
	cd $(APP) && flutter build apk --debug
build-web: ## Flutter web build
	cd $(APP) && flutter build web

# ---- Unified web app (Next.js host: / landing, /u/[handle] profile, /app Flutter) ----
.PHONY: web-dev web-flutter web-build web-deploy
web-dev: ## Run the host site locally (needs `make web-flutter` first for /app)
	cd $(WEB) && npm run dev
web-flutter: ## Build the Flutter web app into web/public/app (base-href /app/)
	cd $(APP) && flutter build web --base-href /app/ $(DEFINE)
	rm -rf $(WEB)/public/app
	mkdir -p $(WEB)/public/app
	cp -R $(APP)/build/web/. $(WEB)/public/app/
web-build: web-flutter ## Full production build: Flutter bundle + Next.js (local verify)
	cd $(WEB) && npm ci && npm run build
# Deploy via REMOTE build: Vercel injects the real (sensitive) NEXT_PUBLIC_* env
# vars at build time — local `vercel build` only sees empty pulled values. The Flutter
# bundle in public/app is gitignored, so `.vercelignore` (which omits it) ensures the
# CLI still uploads it for the remote `next build` to serve.
web-deploy: web-flutter ## Build the Flutter bundle and deploy the unified site to Vercel (prod)
	cd $(WEB) && vercel deploy --prod

# ---- Supabase (LOCAL is only for testing migrations; app uses hosted) ----
.PHONY: db-reset-local sb-stop deploy-functions
db-reset-local: ## Apply migrations + seed to the LOCAL Docker stack
	supabase db reset --local
sb-stop: ## Stop the local Supabase Docker stack
	supabase stop
deploy-functions: ## Deploy edge functions to the linked remote project
	supabase functions deploy spotify-app-token --no-verify-jwt
	supabase functions deploy lastfm-proxy --no-verify-jwt
	supabase functions deploy musicbrainz-proxy --no-verify-jwt

# ---- SQL lint ----
.PHONY: sqlfluff
sqlfluff: ## Lint Postgres migrations
	sqlfluff lint supabase/migrations supabase/seed.sql
