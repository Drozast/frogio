.PHONY: mobile-run mobile-attach

# Run the Flutter mobile app on the first available device/emulator
mobile-run:
	bash scripts/run-mobile.sh

# Attach to a running Flutter app (useful if already launched from IDE)
mobile-attach:
	bash scripts/run-mobile.sh --attach

