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

# ---- Web profile site (Next.js) ----
.PHONY: web-dev web-build web-deploy
web-dev: ## Run the public profile site locally
	cd $(WEB) && npm run dev
web-build: ## Production build of the web site
	cd $(WEB) && npm ci && npm run build
web-deploy: ## Deploy the web site to Vercel (prod)
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

# ---- SQL lint ----
.PHONY: sqlfluff
sqlfluff: ## Lint Postgres migrations
	sqlfluff lint supabase/migrations supabase/seed.sql
