.ONESHELL:
RAILS = ./bin/rails

.PHONY: server
server:
	$(RAILS) server -b 0.0.0.0

.PHONY: console
console:
	$(RAILS) console

.PHONY: tailwind
tailwind:
	$(RAILS) tailwindcss:watch
