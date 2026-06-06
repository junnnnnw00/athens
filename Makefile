# Athens — common commands. Public client config lives in app/config/app_config.json
# (Supabase URL + publishable key + Spotify client id — all client-safe).
# Server secrets live ONLY in Supabase edge-function secrets, never here.

APP        := app
WEB        := web
DEFINE     := --dart-define-from-file=config/app_config.json
DEFINE_DEV := --dart-define-from-file=config/app_config_dev.json
SEED       := --dart-define=DEV_SEED=true

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n",$$1,$$2}'

# ---- Flutter app (talks to the HOSTED Supabase; no local stack needed) ----
.PHONY: run run-seed run-dev run-dev-seed analyze test itest goldens
run: ## Run the app on the default device against hosted production backend
	cd $(APP) && flutter run $(DEFINE)
run-seed: ## Run with sample data seeded into the local Drift cache (production config)
	cd $(APP) && flutter run $(DEFINE) $(SEED)
run-dev: ## Run the app against development backend (app_config_dev.json)
	cd $(APP) && flutter run $(DEFINE_DEV)
run-dev-seed: ## Run with sample data seeded against development backend
	cd $(APP) && flutter run $(DEFINE_DEV) $(SEED)
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

# ---- Android (sideload / USB) ----
ADB := /opt/homebrew/share/android-commandlinetools/platform-tools/adb
DEFINE_ANDROID := --dart-define-from-file=config/app_config.json

.PHONY: android-run android-apk android-aab android-install android-logs
android-run: ## Run debug build on USB-connected Android device
	cd $(APP) && flutter run -d $(shell $(ADB) devices | awk 'NR==2{print $$1}') $(DEFINE_ANDROID)
android-apk: ## Build signed release APK → app/build/app/outputs/flutter-apk/app-release.apk
	cd $(APP) && flutter build apk --release $(DEFINE_ANDROID)
	@echo "✅  APK: $(APP)/build/app/outputs/flutter-apk/app-release.apk"
android-aab: ## Build Play Store App Bundle (.aab) — STORE_BUILD disables the in-app updater
	cd $(APP) && flutter build appbundle --release $(DEFINE_ANDROID) --dart-define=STORE_BUILD=true
	@echo "✅  AAB (Play Store, no self-update): $(APP)/build/app/outputs/bundle/release/app-release.aab"
android-apk-store: ## Play Store APK variant (STORE_BUILD=true; no in-app updater)
	cd $(APP) && flutter build apk --release $(DEFINE_ANDROID) --dart-define=STORE_BUILD=true
	@echo "✅  Store APK: $(APP)/build/app/outputs/flutter-apk/app-release.apk"
android-aab-store: android-aab ## Alias of android-aab (kept for back-compat)
android-install: android-apk ## Build + install release APK to USB device
	$(ADB) install -r $(APP)/build/app/outputs/flutter-apk/app-release.apk
	@echo "✅  Installed on device"
android-logs: ## Stream logcat from connected device (filter by athens)
	$(ADB) logcat | grep -i athens

.PHONY: macos-zip
macos-zip: ## Build macOS release + zip Athens.app → attach .zip to the GitHub Release (in-app updater asset)
	cd $(APP) && flutter build macos --release $(DEFINE)
	cd $(APP)/build/macos/Build/Products/Release && ditto -c -k --keepParent Athens.app "$(CURDIR)/$(APP)/build/athens-macos.zip"
	@echo "✅  macOS zip: $(APP)/build/athens-macos.zip"
	@echo "    ⚠️  EVERY release needs a .zip asset or macOS in-app update breaks (downloads the release HTML page instead). Upload with: gh release upload vX.Y.Z app/build/athens-macos.zip"


# ---- Unified web app (Next.js host: / landing, /u/[handle] profile, /app Flutter) ----
# Deploy pipeline: flutter build web → copy → vercel deploy --prod → re-pin aliases.
# Always use `make web-deploy` — never run `vercel deploy` directly (aliases won't update).
.PHONY: web-dev web-flutter web-flutter-dev web-build web-deploy web-deploy-dev
web-dev: ## Run the host site locally (needs `make web-flutter` first for /app)
	cd $(WEB) && npm run dev
web-flutter: ## Build the Flutter web app into web/public/app (base-href /app/)
	cd $(APP) && flutter build web --base-href /app/ $(DEFINE)
	rm -rf $(WEB)/public/app
	mkdir -p $(WEB)/public/app
	cp -R $(APP)/build/web/. $(WEB)/public/app/
web-flutter-dev: ## Build the Flutter web app with dev config into web/public/app
	cd $(APP) && flutter build web --base-href /app/ $(DEFINE_DEV)
	rm -rf $(WEB)/public/app
	mkdir -p $(WEB)/public/app
	cp -R $(APP)/build/web/. $(WEB)/public/app/
web-build: web-flutter ## Full production build: Flutter bundle + Next.js (local verify)
	cd $(WEB) && npm ci && npm run build
web-deploy: ## Build Flutter bundle + deploy to Vercel + re-pin athens.vercel.app alias
	@bash scripts/deploy-web.sh
web-deploy-dev: ## Build Flutter bundle (dev config) + deploy to Vercel (Preview build)
	@bash scripts/deploy-web-dev.sh


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
	supabase functions deploy verify-play-purchase

# ---- SQL lint ----
.PHONY: sqlfluff
sqlfluff: ## Lint Postgres migrations
	sqlfluff lint supabase/migrations supabase/seed.sql
