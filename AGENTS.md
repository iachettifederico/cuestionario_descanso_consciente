# Agent Coding Guidelines

## Commands

- **Development server**: `make server` or `bin/rails server -b 0.0.0.0`
- **Console**: `make console` or `bin/rails console`
- **Tailwind watch**: `make tailwind` or `bin/rails tailwindcss:watch`
- **Tests**: `bin/rails test` (run all tests) or `bin/rails test test/specific_test.rb` (single test)
- **Lint**: `bin/rubocop` (check) or `bin/rubocop -a` (auto-fix)
- **Security scan**: `bin/brakeman`

## Code Style

- Follow .rubocop.yml
- Extract complex logic to private methods with clear names
- Use guard clauses for early returns (`return [] unless responses_param`)
- Prefer explicit parentheses in method definitions with parameters
- Use `freeze` on constants containing mutable objects
- Handle edge cases gracefully (nil checks, empty collections)
- Use descriptive variable names (`category_responses` not `cr`)
- **Use only Tailwind CSS for all styling** - no custom CSS or other CSS frameworks

## Context and Collaborators

En diferentes computadoras trabajamos de forma distinta:
- **En olivia**: Trabajando con Gime, psicóloga sin experiencia en programación. Explicar conceptos de manera simple, como para alguien que no sabe programar, y aconsejar cuando se observe un error o mejora necesaria.
- **En azula**: Trabajando con Fede, programador Ruby experimentado.

## Build/Test/Lint Commands
- **Test all**: `bundle exec rspec` or `bin/rails spec`  
- **Test single file**: `bundle exec rspec spec/models/story_spec.rb`
- **Lint**: `bundle exec rubocop` (auto-fix: `bundle exec rubocop -a`)
- **Build assets**: `bin/rails tailwindcss:build` or `bin/rails assets:precompile`
- **Watch CSS**: `bin/rails tailwindcss:watch`
- **Database**: `bin/rails db:migrate` (setup: `bin/rails db:setup`)

## Code Style Guidelines
- **Frozen strings**: All Ruby files start with `# frozen_string_literal: true`
- **String literals**: Use double quotes (`"hello"`) not single quotes
- **Hash syntax**: Use hash rockets (`{ :key => value }`) not new syntax
- **Naming**: snake_case for files/directories, PascalCase for modules/classes
- **Module structure**: Organize by feature namespace (e.g., `ColorOfTheDay::HomeController`)
- **Error handling**: Use Rails conventions, `rescue` specific exceptions
- **Imports**: Standard Ruby `require` statements, Rails auto-loading via modules

## Guiding Principles

* **Simplicity > features:** A few sharp tools that feel effortless.
* **Hotwire‑first:** Prefer **Turbo Frames/Streams**; **Stimulus only for page interactions** (never for backend calls).
* **Accessibility, clarity, calm:** WCAG‑minded defaults, no visual noise.
* **Feature slices:** Deliver in vertical slices with visible user impact.
* **Performance by design:** Fast actions, progressive enhancement, minimal JS.

## Hotwire / Stimulus Rules (Important)

* **DO:** Use **Turbo** for navigation, CRUD, optimistic UI, broadcasts.
* **DO:** Use **Stimulus** for **pure client‑side interactions** (toggles, keyboard shortcuts, inline validations) that **don’t call the backend**.
* **DON’T:** Put `fetch`, `axios`, or `Rails.ajax` inside Stimulus controllers.
* **DON’T:** Duplicate server state in client JS; the server is source of truth.
* **Pattern:** Controllers render HTML partials; updates stream via `turbo_stream`.

## Documentos

* Tenemos una carpeta llamada docs donde están los documentos importantes
