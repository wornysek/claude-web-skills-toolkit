# claude-web-skills-toolkit

**Čeština** · [English](README.md)

> Standardizovaná sada skillů, oficiálních pluginů, MCP serverů a auditních pravidel pro
> **Claude Code** a další AI agenty. Jeden příkaz a váš agent píše webový kód, který je
> **bezpečný, použitelný a nevypadá jako AI slop**.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Shell](https://img.shields.io/badge/install-bash-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-skills%20%2B%20MCP-orange)

```bash
git clone https://github.com/wornysek/claude-web-skills-toolkit.git ~/claude-web-skills-toolkit
cd ~/muj-projekt
bash ~/claude-web-skills-toolkit/install.sh --all
```

---

## Obsah

- [Proč tento toolkit](#proč-tento-toolkit)
- [Co je uvnitř](#co-je-uvnitř)
- [Tabulka skillů a nástrojů](#tabulka-skillů-a-nástrojů)
- [Instalace](#instalace)
- [Integrace do existujícího projektu](#integrace-do-existujícího-projektu)
- [Jak skilly fungují](#jak-skilly-fungují)
- [Hook: slop & secrets guard](#hook-slop--secrets-guard)
- [Bezpečnost toolkitu](#bezpečnost-toolkitu)
- [Aktualizace a odinstalace](#aktualizace-a-odinstalace)
- [Přispívání](#přispívání)
- [Licence a atribuce](#licence-a-atribuce)

---

## Proč tento toolkit

AI agenti dnes vygenerují funkční webovou aplikaci za pár minut. Bez pravidel ale
opakovaně produkují stejné typy problémů:

| Problém | Jak vypadá | Co s tím toolkit dělá |
|---------|------------|-----------------------|
| **AI slop v designu** | Fialovo-růžové gradienty, Inter všude, vycentrované všechno, emoji místo ikon, žádné loading/empty stavy, komponenty psané z nuly | `frontend-design-guide` zakazuje generické vzory a vynucuje tokeny, skeletony a empty states. `shadcn-ui` nutí agenta brát komponenty z registru. Oficiální plugin `frontend-design` dodá estetický směr. `magic-animations` přidá promyšlené animace s ohledem na výkon. `component-registries` staví každou sekci z promyšleného vzoru a osvědčených komponent z komunitních registrů místo stále stejných výchozích; Impeccable (`impeccable-workflow`) přidává příkazy shape, critique, audit a polish. |
| **Nebezpečný kód** | Tokeny v `localStorage`, chybějící kontrola vlastnictví (IDOR), `req.body` rovnou do DB, OAuth bez `state`, webhooky bez ověření podpisu, stack traces v produkci, API klíče vložené přímo do kódu | `backend-security-auditor` obsahuje striktní pravidla (MUSÍ) pro auth, IDOR, validaci, DB, API odpovědi, hlavičky a produkci včetně hotových bezpečných vzorů kódu a závěrečné „Security Gate“. Volitelný hlídací hook zablokuje tajné hodnoty dřív, než se zapíšou do souboru. |
| **Ignorování UX** | 4 stejně výrazná tlačítka, malé dotykové cíle, žádná zpětná vazba po kliknutí, formulář ztratí data po chybě | `ux-laws` převádí 20 zákonů UX (Hick, Fitts, Doherty < 400 ms, Peak-End…) na ověřitelné *Implementation Checks*. `vercel-web-guidelines` spouští automatizovaný design audit (spacing, grid, kontrast). |
| **AI slop v textech** | „Posuňte svou komunitu na další úroveň“, „Něco se pokazilo“, „Odeslat“, vymyšlené „10 000+ spokojených uživatelů“, emoji v nadpisech, „nejde jen o X, jde o Y“ | `ux-writing-en` / `ux-writing-cs` dávají pravidla pro tlačítka, chybové hlášky, empty states, texty landing page a lokalizaci; český skill navíc řeší skloňování, plurály, tykání a vykání a typografii. `deslop-en` / `deslop-cs` jsou korektury, které odstraní typické AI obraty a nezmění fakta. Hlídací hook je po každé úpravě označí automaticky. <!-- guard:allow --> |
| **Neviditelné nebo v rozporu s GDPR** | Jeden titulek pro celý web, žádné náhledy pro sdílení, indexované administrace a staging, analytika běžící před souhlasem, žádná možnost exportu dat ani smazání účtu | `seo-metadata` řeší titulky, kanonické URL, OG obrázky, sitemap, robots, hreflang a JSON-LD. `gdpr-privacy` řeší minimalizaci dat, souhlas bez manipulativních triků, práva subjektů údajů, dobu uchovávání a osobní údaje v logech. |

Kvalitu navíc **ověřuje v běhu**: `webapp-testing` generuje a spouští Playwright E2E
testy, `chrome-devtools` čte chyby z konzole skutečného prohlížeče, `superpowers-debugging`
vynucuje deterministický postup oprav bez maskování chyb a volitelný
[hlídací hook](#hook-slop--secrets-guard) kontroluje každý soubor, který Claude zapíše.

Toolkit dál pokrývá zbytek webového projektu — přístupnost, výkon, formuláře, přihlašování,
API, databáze, e-maily, AI funkce a nasazení — a skilly pro konkrétní typy webů: e-shopy,
obsahové weby, landing page, mobil/PWA a realtime aplikace.

## Co je uvnitř

```
claude-web-skills-toolkit/
├── README.md                      # dokumentace v angličtině
├── README.cs.md                   # dokumentace v češtině
├── LICENSE
├── .gitignore
├── .gitattributes                 # LF konce řádků pro install.sh i na Windows
├── install.sh                     # instalátor (interaktivní / --all)
├── hooks/
│   ├── slop-secrets-guard.sh      # hook pro Claude Code: blokuje tajné hodnoty, hlásí AI obraty
│   └── settings.example.json      # registrace hooku pro .claude/settings.json
└── skills/                        # 34 skillů, každý ve složce se SKILL.md (viz tabulky níže)
    ├── a11y-auditor/
    ├── ai-features/
    └── …
```

**Vlastní skilly** obsahují kompletní pravidla. **Wrapper skilly** pro externí nástroje
obsahují zdroj, autora, licenci, přesný postup instalace, JSON konfiguraci a hlavně
**pravidla chování** — kdy a jak má Claude daný nástroj použít. Samotný externí nástroj
(plugin, MCP server) se instaluje přes `install.sh` nebo ručně.

> **Poznámka k jazyku:** soubory skillů jsou psané anglicky. Claude je načte a použije
> bez ohledu na to, v jakém jazyce s ním komunikujete.

## Tabulka skillů a nástrojů

Všechny vlastní skilly jsou od claude-web-skills-toolkit pod licencí MIT. Jednotlivě je
nainstalujete příkazem `cp -R skills/<název> .claude/skills/`, všechny najednou přes `./install.sh --skills`.

### Design a UX

| Skill | Kdy použít |
|-------|-------------|
| [`ux-laws`](skills/ux-laws/SKILL.md) | Návrh nebo review UI podle 20 zákonů UX; formuláře, navigace, onboarding, nízká konverze (inspirováno *Laws of UX*, Jon Yablonski) |
| [`frontend-design-guide`](skills/frontend-design-guide/SKILL.md) | Nová stránka nebo komponenta, „udělej to hezčí“, fonty, barvy, skeletony, empty states |
| [`component-registries`](skills/component-registries/SKILL.md) | Weby, které vypadají jako všechny ostatní: nabídka vzorů pro každou sekci, komponenty z Magic UI, Aceternity, React Bits, 21st.dev a dalších registrů |
| [`a11y-auditor`](skills/a11y-auditor/SKILL.md) | Přístupnost (WCAG 2.2 AA, EAA): klávesnice, čtečky obrazovky, dialogy a vlastní widgety, prohlášení o přístupnosti |
| [`landing-page`](skills/landing-page/SKILL.md) | Landing page, úvodní, produktové a ceníkové stránky; konverze; A/B testy |
| [`pwa-mobile`](skills/pwa-mobile/SKILL.md) | Telefony a tablety, dotykové ovládání, manifest, offline režim, instalace, push notifikace |

### Texty a obsah

| Skill | Kdy použít |
|-------|-------------|
| [`ux-writing-en`](skills/ux-writing-en/SKILL.md) | Anglické texty v UI a na webu: tlačítka, chyby, empty states, landing page, e-maily |
| [`ux-writing-cs`](skills/ux-writing-cs/SKILL.md) | České texty v UI a na webu: tykání a vykání, skloňování, plurály, typografie |
| [`deslop-en`](skills/deslop-en/SKILL.md) | `/deslop-en <soubor>`, anglický text, který zní jako AI; README, dokumentace, popisy PR, commity |
| [`deslop-cs`](skills/deslop-cs/SKILL.md) | `/deslop-cs <soubor>`, český text, který zní jako AI nebo jako překlad |
| [`i18n-setup`](skills/i18n-setup/SKILL.md) | Druhý jazyk: routing podle jazyka, soubory s překlady, ICU plurály, formáty, přepínač jazyka |
| [`seo-metadata`](skills/seo-metadata/SKILL.md) | Veřejné stránky: metadata, OG obrázky, sitemap, robots, noindex, hreflang, JSON-LD |
| [`cms-content`](skills/cms-content/SKILL.md) | Blogy, dokumentace a marketingové weby: headless CMS, MDX, náhledy, redakční workflow |

### Architektura a funkce

| Skill | Kdy použít |
|-------|-------------|
| [`tech-stack-advisor`](skills/tech-stack-advisor/SKILL.md) | Nový projekt, „na čem to postavit?“, srovnání frameworků, databází, autentizace nebo hostingu |
| [`forms`](skills/forms/SKILL.md) | Jakýkoli formulář: sdílené schéma, server actions, chyby, ochrana proti spamu, uploady |
| [`auth-flows`](skills/auth-flows/SKILL.md) | Registrace, přihlášení, passkeys, magic linky, 2FA, reset hesla, obnova účtu |
| [`api-design`](skills/api-design/SKILL.md) | REST endpointy a veřejná API: chyby, stránkování, verzování, idempotence, odchozí webhooky |
| [`database-design`](skills/database-design/SKILL.md) | Schéma, relace, indexy, pomalé dotazy, bezpečné migrace, seed data |
| [`transactional-email`](skills/transactional-email/SKILL.md) | Ověřovací, resetovací a notifikační e-maily; React Email; SPF, DKIM, DMARC |
| [`ai-features`](skills/ai-features/SKILL.md) | Chat, asistenti, generování, RAG, prompt injection, náklady na AI |
| [`realtime`](skills/realtime/SKILL.md) | Chat, živé aktualizace, přítomnost uživatelů, společná editace, optimistické UI |
| [`ecommerce`](skills/ecommerce/SKILL.md) | E-shopy: košík, checkout, Stripe, předplatné, DPH v EU, spotřebitelské právo a právní stránky |

### Bezpečnost a soukromí

| Skill | Kdy použít |
|-------|-------------|
| [`backend-security-auditor`](skills/backend-security-auditor/SKILL.md) | API endpointy, server actions, kód autentizace, uploady, webhooky, „je to bezpečné?“ |
| [`frontend-security`](skills/frontend-security/SKILL.md) | XSS, Content Security Policy, skripty třetích stran, závislosti a supply chain |
| [`gdpr-privacy`](skills/gdpr-privacy/SKILL.md) | Osobní údaje, cookies a souhlas, analytika, export a smazání dat, doba uchovávání |

### Testy, výkon a provoz

| Skill | Kdy použít |
|-------|-------------|
| [`webapp-testing`](skills/webapp-testing/SKILL.md) | Playwright E2E testy formulářů a flow |
| [`web-performance`](skills/web-performance/SKILL.md) | Core Web Vitals, velikost JS, obrázky, fonty, cache, Lighthouse v CI |
| [`deploy-and-ops`](skills/deploy-and-ops/SKILL.md) | CI/CD, preview prostředí, proměnné prostředí, domény, monitoring, zálohy, incidenty |

### Externí nástroje, pluginy a hook

| Skill / nástroj | Typ | Původní autor · licence | Manuální instalace | Kdy použít (triggers) |
|-----------------|-----|-------------------------|--------------------|-----------------------|
| [Hlídací hook (slop & secrets guard)](hooks/slop-secrets-guard.sh) | Hook pro Claude Code | claude-web-skills-toolkit · MIT | `./install.sh --hooks` | Spouští se automaticky při každém Write/Edit: blokuje tajné hodnoty, hlásí AI obraty |
| `frontend-design` (plugin) | Oficiální Plugin | Anthropic (P. Rajasekaran, A. Bricken) · © Anthropic PBC, Commercial ToS | `claude plugin marketplace add anthropics/claude-code`<br>`claude plugin install frontend-design@claude-code-plugins` | Tvorba frontendu s výrazným estetickým směrem; doplňuje `frontend-design-guide` |
| [`superpowers-debugging`](skills/superpowers-debugging/SKILL.md) → `superpowers` | Oficiální Plugin | Jesse Vincent (obra) · MIT · distribuce: Anthropic `claude-plugins-official` | `claude plugin install superpowers@claude-plugins-official` | Bug, padající test, výjimka, regrese, „oprava nezabrala“ |
| [`shadcn-ui`](skills/shadcn-ui/SKILL.md) | Externí MCP Server | shadcn · MIT · doporučení: Colton Dean | `npx shadcn@latest mcp init --client claude` | Formulář, tlačítko, dialog, menu, tabulka, select, toast — jakákoli UI komponenta |
| [`vercel-web-guidelines`](skills/vercel-web-guidelines/SKILL.md) | Externí Agent Skill | Vercel Labs · MIT | `npx skills add vercel-labs/agent-skills` | Po vygenerování stránky; „review my UI“, „audit design“, spacing, grid, kontrast |
| [`chrome-devtools`](skills/chrome-devtools/SKILL.md) | Externí MCP Server | Google Chrome DevTools team · Apache-2.0 | `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest` | Stránka nefunguje, chyby v konzoli, selhané requesty, screenshot, výkon (LCP/CLS/INP) |
| [`magic-animations`](skills/magic-animations/SKILL.md) | Externí MCP Server | 21st.dev · ISC (magic-mcp) / MIT (CLI) · komerční služba s API klíčem | `npx @21st-dev/cli@latest init --client claude --write`<br>nebo `claude mcp add --transport http --scope user 21st https://21st.dev/api/mcp --header "x-api-key: $API_KEY_21ST"` | Interaktivní hero sekce, animované pozadí, animace tlačítek, „oživ stránku“ |
| [`impeccable-workflow`](skills/impeccable-workflow/SKILL.md) → `impeccable` | Externí Agent Skill | Paul Bakaus · Apache-2.0 | `npx impeccable install` | Designový proces: shape, critique, audit, polish, bolder/quieter; design, který působí generic |

> **Poznámka k 21st.dev:** Magic MCP byl upstreamem nahrazen jednotným 21st MCP a staré
> API klíče byly zneplatněny. Dříve uváděný příkaz
> `npx @21st-dev/cli@latest install claude --api-key <YOUR_API_KEY>` nahradil
> `npx @21st-dev/cli@latest init --client claude`. Nový klíč získáte na https://21st.dev/mcp.

## Instalace

### Požadavky

| Nástroj | Proč | Ověření |
|---------|------|---------|
| [Claude Code](https://claude.com/claude-code) | pluginy, registrace MCP serverů | `claude --version` |
| Node.js 20+ a `npx` | shadcn, Vercel skills, chrome-devtools-mcp | `node -v`, `npx -v` |
| Bash 3.2+ | `install.sh` a hlídací hook (macOS, Linux, Git Bash nebo WSL na Windows) | `bash --version` |
| Google Chrome | Chrome DevTools MCP | — |
| Node.js nebo Python 3 | jen pro sloučení hooku s existujícím `.claude/settings.json` | `node -v` / `python3 --version` |

`install.sh` kontroluje dostupnost `claude` a `npx` a komponenty, pro které nástroj chybí,
přeskočí s jasnou hláškou.

### Spuštění

Skript spouštějte **z kořene projektu**, do kterého toolkit integrujete — projektové
konfigurace (`.mcp.json`, `.claude/skills/`) vznikají v aktuálním pracovním adresáři.

```bash
# 1. Naklonujte toolkit (jednou)
git clone https://github.com/wornysek/claude-web-skills-toolkit.git ~/claude-web-skills-toolkit

# 2. Přejděte do svého projektu
cd ~/projekty/moje-webova-aplikace

# 3a. Interaktivní výběr komponent
bash ~/claude-web-skills-toolkit/install.sh

# 3b. Nebo vše najednou bez dotazů
bash ~/claude-web-skills-toolkit/install.sh --all
```

Na macOS/Linuxu můžete skript spouštět i přímo (`chmod +x install.sh && ./install.sh`).

### Volby `install.sh`

| Volba | Co udělá |
|-------|----------|
| *(bez voleb)* | Interaktivní menu s výběrem komponent |
| `--all` | Nainstaluje vše, na otázky odpoví ANO (existující skilly nepřepisuje bez `--force`) |
| `--plugins` | Přidá marketplace `anthropics/claude-code` a nainstaluje `frontend-design@claude-code-plugins` a `superpowers@claude-plugins-official` |
| `--chrome` | `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest` |
| `--shadcn` | `npx shadcn@latest mcp init --client claude` (zapíše `.mcp.json` v projektu) |
| `--vercel` | `npx skills add vercel-labs/agent-skills` (neinteraktivně: `web-design-guidelines`, `react-best-practices`, `writing-guidelines` pro Claude Code) |
| `--magic` | Registruje 21st.dev MCP (klíč z `API_KEY_21ST`, jinak skrytý dotaz; bez klíče přeskočí) |
| `--mcp` | Zkratka pro `--chrome --shadcn --magic` |
| `--skills` | Zkopíruje `skills/*` do `./.claude/skills/` |
| `--hooks` | Nainstaluje hlídací hook do `./.claude/hooks/` a zaregistruje ho v `./.claude/settings.json` (sloučí, se zálohou `.bak`) |
| `--impeccable` | Nainstaluje Impeccable pro Claude Code do projektu (`npx impeccable install --providers=claude --scope=project`); pak spusťte `/impeccable init` |
| `--global` | S `--skills`: kopíruje do `~/.claude/skills/` (dostupné ve všech projektech) |
| `--force` | Přepíše již existující skilly (i upravený skript hooku) |
| `-y`, `--yes` | Na všechny otázky odpoví ANO |
| `--dry-run` | Jen vypíše příkazy, nic nespustí |
| `-h`, `--help` / `-v`, `--version` | Nápověda / verze |

Příklady:

```bash
# Jen markdown skilly do projektu, přepsat starší verze
bash ~/claude-web-skills-toolkit/install.sh --skills --force

# Podívat se, co by se stalo
bash ~/claude-web-skills-toolkit/install.sh --all --dry-run

# Pluginy a Chrome DevTools, skilly globálně pro všechny projekty
bash ~/claude-web-skills-toolkit/install.sh --plugins --chrome --skills --global

# CI / neinteraktivní prostředí (klíč z CI secret proměnné)
API_KEY_21ST="$CI_SECRET_21ST" bash ~/claude-web-skills-toolkit/install.sh --all
```

Skript je **idempotentní**: již registrované marketplace, pluginy a MCP servery přeskočí.
Na konci vypíše souhrn a při jakékoli chybě skončí s nenulovým exit kódem.

### Ověření instalace

Restartujte Claude Code a v projektu spusťte:

```text
/plugin      → frontend-design, superpowers
/mcp         → chrome-devtools, shadcn, 21st (stav: connected)
/skills      → ux-laws, backend-security-auditor, frontend-design-guide, webapp-testing, impeccable, …
/hooks       → záznamy PreToolUse a PostToolUse pro slop-secrets-guard.sh
```

## Integrace do existujícího projektu

1. **Spusťte instalátor v kořeni projektu:**

   ```bash
   cd ~/projekty/moje-webova-aplikace
   bash ~/claude-web-skills-toolkit/install.sh --all
   ```

2. **Commitněte sdílené konfigurace**, aby je měl celý tým:

   ```bash
   git add .claude/skills .claude/hooks .claude/settings.json .mcp.json
   git commit -m "chore: add claude-web-skills-toolkit skills, hooks and MCP config"
   ```

   `.mcp.json` vytvořený shadcn neobsahuje tajemství. Pokud do něj přidáváte server s klíčem
   (např. 21st.dev), použijte expanzi proměnné `${API_KEY_21ST}` — nikdy hodnotu klíče.

3. **Povolte pluginy pro tým** v `.claude/settings.json`:

   ```json
   {
     "extraKnownMarketplaces": {
       "claude-code-plugins": {
         "source": { "source": "github", "repo": "anthropics/claude-code" }
       }
     },
     "enabledPlugins": {
       "frontend-design@claude-code-plugins": true,
       "superpowers@claude-plugins-official": true
     },
     "permissions": {
       "allow": ["WebFetch(domain:raw.githubusercontent.com)"]
     }
   }
   ```

4. **Přidejte standardy do `CLAUDE.md`** projektu, aby je agent dodržoval i bez explicitní zmínky:

   ```markdown
   ## Standardy kvality (claude-web-skills-toolkit)

   - O stacku nových projektů a velkých nových závislostech rozhoduj podle `tech-stack-advisor` a zapiš rozhodnutí do `docs/adr/`.
   - UI: řiď se skilly `frontend-design-guide` a `ux-laws`; komponenty výhradně ze shadcn registru (`shadcn-ui`).
   - Po vygenerování nebo úpravě stránky spusť audit `vercel-web-guidelines`.
   - Texty pro uživatele piš podle `ux-writing-en` nebo `ux-writing-cs` (podle jazyka) a pak je projeď skillem `deslop-en` / `deslop-cs`. Nikdy si nevymýšlej čísla ani reference.
   - Každá veřejná stránka má metadata podle `seo-metadata`; každá funkce pracující s osobními údaji se řídí `gdpr-privacy`.
   - Žádné natvrdo zapsané texty pro uživatele: překlady, plurály a formátování podle `i18n-setup`.
   - Každý endpoint, server action, webhook a upload projde `backend-security-auditor` včetně Security Gate.
   - Formuláře a kritické flow ověř Playwright testy podle `webapp-testing` a testy skutečně spusť.
   - Chyby řeš podle `superpowers-debugging`: reprodukce → příčina → čistá oprava → ověření.
   - Runtime chyby ověřuj v prohlížeči přes `chrome-devtools`.
   - Nové stránky podle `impeccable-workflow`: `/impeccable shape` → stavba s `component-registries` → `/impeccable critique` a `audit` → kontroly toolkitu → `/impeccable polish`.
   - Každá změna UI projde `a11y-auditor`; stránky drží rozpočty z `web-performance`.
   - Frontendový kód a závislosti se řídí `frontend-security`; nasazení `deploy-and-ops`.
   - Používej odpovídající skill pro danou funkci: `forms`, `auth-flows`, `api-design`, `database-design`, `transactional-email`, `ai-features`, `realtime`, `ecommerce`, `cms-content`, `landing-page`, `pwa-mobile`.
   ```

5. **Doplňte `.gitignore` projektu** o lokální a tajné soubory (inspirace v [`.gitignore`](.gitignore) toolkitu):

   ```gitignore
   .env
   .env.*
   !.env.example
   .claude/settings.local.json
   CLAUDE.local.md
   playwright/.auth/
   # Impeccable: doplňte blok pro .impeccable/ z jeho README
   ```

6. **Nastavte tajné hodnoty** jen jako proměnné prostředí (např. `API_KEY_21ST` v profilu
   shellu nebo ve správci tajemství), nikdy do repozitáře.

## Jak skilly fungují

Každý skill je složka se souborem `SKILL.md`, který začíná YAML hlavičkou:

```yaml
---
name: backend-security-auditor
description: "Strict security audit and rules for full-stack backends ... Use whenever you write or review an API endpoint ..."
triggers:
  - "API endpoint / route handler / server action"
  - "sign-in / OAuth2 / OpenID Connect / session / cookies / passwords"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
---
```

- **`name`** a **`description`** jsou pole, podle kterých Claude Code skill načítá. Claude
  vidí popisy všech skillů a celý obsah skillu si načte, když úloha odpovídá popisu. Proto
  popisy obsahují i klíčová slova spouštěčů.
- **`triggers`** je doplňkové pole toolkitu: lidsky čitelný seznam situací pro dokumentaci
  a pro agenty/nástroje, které s ním umí pracovat. Claude Code ho ignoruje, nevadí mu.
- Skill lze vyvolat i explicitně: *„Použij skill backend-security-auditor na app/api.“*
  nebo jako slash příkaz: `/deslop-cs README.cs.md`.
- **Jazykové skilly** jsou v párech (`ux-writing-en` / `ux-writing-cs`, `deslop-en` / `deslop-cs`).
  Každý je samostatný a jeho popis říká, pro jaký jazyk je určený, takže agent vybere ten
  správný podle jazyka textu. Instrukce všech skillů jsou anglicky; české skilly mají české příklady.
- Umístění: `./.claude/skills/<name>/SKILL.md` (projekt, sdílené přes git) nebo
  `~/.claude/skills/<name>/SKILL.md` (osobní, všechny projekty).

## Hook: slop & secrets guard

Skilly jsou pravidla, která agent čte. Hook je kód, který se spustí při každé úpravě, ať si
agent pravidla pamatuje, nebo ne. [`hooks/slop-secrets-guard.sh`](hooks/slop-secrets-guard.sh)
registruje dvě kontroly pro nástroje `Write`, `Edit` a `MultiEdit`:

| Kontrola | Událost | Co dělá |
|----------|---------|---------|
| `secrets` | `PreToolUse` | **Zablokuje** úpravu, pokud nový text obsahuje něco, co vypadá jako tajná hodnota: privátní klíče, tokeny AWS/GitHub/GitLab/Slack/Stripe/Google/OpenAI/Anthropic/SendGrid/npm, JWT, hesla v connection stringu, natvrdo zapsané přihlašovací údaje. Lokální `.env` soubory přeskakuje, `.env.example` kontroluje. Hodnoty nikdy nevypisuje, jen typ a maskovaný začátek. |
| `slop` | `PostToolUse` | **Nahlásí** Claudovi anglické a české AI obraty v Markdownu, HTML, textech, UI kódu a souborech s překlady; Claude je pak přepíše podle `deslop-en` / `deslop-cs`. Jednotlivá slova kontroluje jen v textových souborech, takže identifikátory v kódu jako `unlock()` ho nespustí. |

- **Falešné poplachy:** přidejte na řádek `guard:allow` (např. `<!-- guard:allow -->` nebo `// guard:allow`).
  Soubor obsahující `slop-guard: off` kontrola AI obratů přeskočí; soubory `SKILL.md` přeskakuje vždy.
- **Závislosti:** jen Bash, `grep` a `awk` — za běhu nepotřebuje Node.js ani `jq`.
- **Instalace:** `./install.sh --hooks`, nebo zkopírujte skript do `.claude/hooks/` a blok `hooks`
  z [`hooks/settings.example.json`](hooks/settings.example.json) do `.claude/settings.json`.
- Je to pojistka, ne náhrada skenování tajných hodnot v CI (např. gitleaks, GitHub secret scanning).

## Bezpečnost toolkitu

- `install.sh` **nestahuje ani nespouští** nic jiného než oficiální příkazy uvedené v tabulce
  výše; všechny příkazy vypisuje před spuštěním (`--dry-run` je jen vypíše).
- API klíč 21st.dev se čte z proměnné prostředí nebo skrytým vstupem, ve výstupu je maskovaný
  a ukládá se jen do uživatelské konfigurace Claude Code (`~/.claude.json`), nikdy do projektu.
- Skript nikdy nepřepisuje existující skilly bez `--force` nebo potvrzení a maže jen cílovou
  složku skillu uvnitř `.claude/skills/`.
- `--hooks` sloučí konfiguraci s existujícím `.claude/settings.json`, nesahá na ostatní klíče,
  ponechá zálohu `settings.json.bak` a nevalidní JSON nechá beze změny.
- Pluginy a MCP servery mohou spouštět kód (hooky, příkazy). Instalujte jen to, čemu
  důvěřujete, a před aktualizací si projděte změny upstreamu.
- MCP servery pracující s prohlížečem nebo webem (chrome-devtools, 21st.dev) zpracovávají
  nedůvěryhodný obsah — wrapper skilly obsahují pravidla proti prompt injection.

## Aktualizace a odinstalace

```bash
# Aktualizace toolkitu a skillů v projektu
git -C ~/claude-web-skills-toolkit pull
bash ~/claude-web-skills-toolkit/install.sh --skills --force

# Aktualizace Impeccable
npx impeccable update

# Aktualizace katalogů pluginů (samotné pluginy pak aktualizujete v Claude Code přes /plugin)
claude plugin marketplace update claude-code-plugins
claude plugin marketplace update claude-plugins-official

# Odinstalace pluginů
claude plugin uninstall frontend-design@claude-code-plugins
claude plugin uninstall superpowers@claude-plugins-official

# Odebrání MCP serverů
claude mcp remove chrome-devtools --scope user
claude mcp remove 21st --scope user
# shadcn: odstraňte záznam "shadcn" z .mcp.json projektu

# Odebrání hlídacího hooku (pak smažte jeho dva záznamy z "hooks" v .claude/settings.json)
rm .claude/hooks/slop-secrets-guard.sh

# Odebrání markdown skillů toolkitu z projektu
for skill in ~/claude-web-skills-toolkit/skills/*/; do rm -rf ".claude/skills/$(basename "$skill")"; done
```

## Přispívání

1. Forkněte repozitář a vytvořte větev (`feat/novy-skill`).
2. Přidejte složku `skills/<nazev-skillu>/SKILL.md` s YAML hlavičkou (`name` shodné s názvem
   složky, malá písmena a pomlčky; `description` s jasnými spouštěči; `triggers`; `metadata`
   s autorem a licencí).
3. U externích nástrojů uveďte původního autora, licenci, přesný instalační příkaz, JSON
   konfiguraci a pravidla chování. Instalační příkazy ověřte proti aktuální dokumentaci upstreamu.
4. Pokud skill vyžaduje instalaci, doplňte krok do `install.sh` (idempotentní, s `--dry-run`).
5. Ověřte skript: `bash -n install.sh` a `bash install.sh --all --dry-run`.
6. Otevřete Pull Request s popisem, jaký problém skill řeší.

## Licence a atribuce

Kód a vlastní skilly tohoto repozitáře jsou pod licencí [MIT](LICENSE). Wrapper skilly
popisují nástroje třetích stran, které se instalují z jejich oficiálních zdrojů a řídí
se vlastními licencemi:

| Nástroj | Autor | Licence | Zdroj |
|---------|-------|---------|-------|
| frontend-design (plugin) | Anthropic | © Anthropic PBC, Commercial Terms of Service | https://github.com/anthropics/claude-code |
| claude-plugins-official (marketplace) | Anthropic | Apache-2.0 | https://github.com/anthropics/claude-plugins-official |
| superpowers | Jesse Vincent (obra) a přispěvatelé | MIT | https://github.com/obra/superpowers |
| shadcn/ui + shadcn MCP | shadcn | MIT | https://github.com/shadcn-ui/ui |
| agent-skills (web-design-guidelines) | Vercel Labs | MIT | https://github.com/vercel-labs/agent-skills |
| skills CLI | Vercel Labs | MIT | https://github.com/vercel-labs/skills |
| chrome-devtools-mcp | Google Chrome DevTools team | Apache-2.0 | https://github.com/ChromeDevTools/chrome-devtools-mcp |
| 21st MCP / magic-mcp | 21st.dev | ISC (magic-mcp), MIT (@21st-dev/cli) | https://github.com/21st-dev/magic-mcp |
| Impeccable | Paul Bakaus | Apache-2.0 | https://github.com/pbakaus/impeccable |
| Registry komponent (Magic UI, Aceternity UI, React Bits, …) | jejich autoři | podle registru — viz `component-registries` | https://ui.shadcn.com/r/registries.json |
| Laws of UX (inspirace pro `ux-laws`) | Jon Yablonski | obsah webu © autor; skill je vlastní formulace | https://lawsofux.com |

Názvy produktů a ochranné známky patří jejich vlastníkům. Tento projekt není oficiálně
spojen s Anthropic, Vercel, Google, shadcn ani 21st.dev.
