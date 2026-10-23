---
name: shadcn-ui
description: "Mandatory use of the shadcn/ui registry via the shadcn MCP server. Use whenever the user asks for a form, button, dialog, modal, menu, dropdown, table, card, select, combobox, tabs, toast, sheet, calendar or any other UI component in React/Next.js — Claude must not write the component from scratch, but must find it in and install it from the shadcn registry."
triggers:
  - "form / input / form validation"
  - "button"
  - "dialog / modal / alert dialog / sheet / drawer"
  - "menu / dropdown / navigation / command palette"
  - "table / data table / sortable list"
  - "select / combobox / date picker / tabs / toast"
  - "add a component / UI component"
metadata:
  type: external-mcp-server
  author: "shadcn (shadcn/ui)"
  recommended-by: "Colton Dean"
  source: "https://ui.shadcn.com/docs/mcp"
  repository: "https://github.com/shadcn-ui/ui"
  license: MIT
  wrapper-license: "MIT (claude-web-skills-toolkit)"
---

# shadcn/ui MCP — components from the registry only

| | |
|---|---|
| **Author / Source** | [shadcn](https://github.com/shadcn-ui/ui) — shadcn/ui and the official shadcn MCP server |
| **Recommended by** | Colton Dean |
| **License** | MIT (shadcn/ui) · this wrapper skill: MIT |
| **Type** | External MCP server (project-level, `.mcp.json`) |
| **Documentation** | https://ui.shadcn.com/docs/mcp |

## Installation

Prerequisite: a project with React and Tailwind CSS and an initialized shadcn/ui
(`components.json` in the root). If it is missing:

```bash
npx shadcn@latest init
```

Register the MCP server for Claude Code (run in the project root):

```bash
npx shadcn@latest mcp init --client claude
```

The command creates or extends `.mcp.json` in the project root. The file contains no
secrets and **belongs in the repository**, so the whole team gets the MCP. After installing,
restart Claude Code and check the status with `/mcp`.

Installation via the toolkit:

```bash
./install.sh --shadcn
```

## Configuration

`.mcp.json` (Claude Code project scope):

```json
{
  "mcpServers": {
    "shadcn": {
      "command": "npx",
      "args": ["shadcn@latest", "mcp"]
    }
  }
}
```

Optional third-party registries (including private ones) are configured in `components.json`.
The private registry token is read from an environment variable — never write it in directly:

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "ui": "@/components/ui",
    "utils": "@/lib/utils",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "registries": {
    "@acme": {
      "url": "https://registry.acme.com/r/{name}.json",
      "headers": {
        "Authorization": "Bearer ${ACME_REGISTRY_TOKEN}"
      }
    }
  }
}
```

## MCP server tools

| Tool | Purpose |
|------|---------|
| `get_project_registries` | Finds the registries configured in `components.json` |
| `list_items_in_registries` | Lists available components, blocks and examples |
| `search_items_in_registries` | Full-text / fuzzy search for a component |
| `view_items_in_registries` | Shows an item's details and source code |
| `get_item_examples_from_registries` | Finds usage examples (demo, example) |
| `get_add_command_for_items` | Returns the exact `npx shadcn@latest add …` command |
| `get_audit_checklist` | Checklist after adding components |

## Behavior rules — MUST

1. **No writing components from scratch.** When the user asks for a form, button, dialog, menu,
   table or another UI component, Claude **must not** write its own implementation
   (a custom `<div role="dialog">`, a hand-written dropdown, a custom sortable table).
2. **Workflow** for every requested component:
   1. `search_items_in_registries` — find matching items.
   2. `view_items_in_registries` + `get_item_examples_from_registries` — verify the API and usage patterns of the **current** version (do not write the API from memory).
   3. `get_add_command_for_items` — get the command and **run it** (`npx shadcn@latest add dialog form …`).
   4. Compose the domain component from the installed primitives in `components/ui/`.
   5. `get_audit_checklist` — go through the checklist (imports, dependencies, providers such as `<Toaster />`).
3. **Components already in the project** (`components/ui/*.tsx`) are not reinstalled — use them. You may overwrite them only with the user's consent (`add --overwrite`).
4. **Visual changes** via tokens in CSS and `cva` variants, not by copying and rewriting primitives.
5. **If the MCP is not available** (server not running, offline), use the CLI with the same workflow:
   `npx shadcn@latest search @shadcn -q "<query>"`, `npx shadcn@latest view @shadcn/<item>`,
   `npx shadcn@latest add <item>`. A custom implementation is acceptable only when the registry
   demonstrably does not contain the component — and you must say so explicitly.
6. **Registry security:** before installing components from third-party registries, review them (`view_items_in_registries`) — look for network calls, `dangerouslySetInnerHTML`, `eval`, external scripts and unexpected dependencies.

## Mapping requests to components

| Request | Registry components |
|---------|---------------------|
| Form with validation | `form` / `field`, `input`, `label`, `textarea`, `checkbox`, `select` + `react-hook-form` + `zod` |
| Button, button group | `button`, `button-group`, `toggle`, `toggle-group` |
| Dialog / confirmation / panel | `dialog`, `alert-dialog`, `sheet`, `drawer` |
| Menu | `dropdown-menu`, `navigation-menu`, `menubar`, `context-menu` |
| Search / command palette / combobox | `command` + `popover` |
| Table | `table` (static), the *Data Table* pattern with `@tanstack/react-table` (sorting, filters, pagination) |
| Date | `calendar` + `popover` (date picker) |
| Notifications | `sonner` |
| Loading | `skeleton`, `spinner`, `progress` |
| In-section navigation | `tabs`, `breadcrumb`, `pagination`, `sidebar` |
| Content blocks | `card`, `accordion`, `collapsible`, `separator`, `badge`, `avatar`, `tooltip`, `hover-card` |

## Example

Request: *"Add a dialog for closing a ticket with a confirmation."*

```text
1. search_items_in_registries  → query "alert dialog"
2. view_items_in_registries    → @shadcn/alert-dialog
3. get_add_command_for_items   → npx shadcn@latest add alert-dialog
4. Bash: npx shadcn@latest add alert-dialog button
5. Create components/tickets/close-ticket-dialog.tsx composed of AlertDialog* + Button
6. get_audit_checklist         → verify imports and the server action for closing the ticket
```

```tsx
// components/tickets/close-ticket-dialog.tsx
"use client";

import { useTransition } from "react";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { closeTicket } from "@/app/(app)/tickets/actions";

export function CloseTicketDialog({ ticketId }: { ticketId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>
        <Button variant="outline">Close ticket</Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Close this ticket?</AlertDialogTitle>
          <AlertDialogDescription>
            We will move the ticket to resolved. If the problem persists, you can reopen it within 7 days.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isPending}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            disabled={isPending}
            onClick={() =>
              startTransition(async () => {
                const result = await closeTicket(ticketId);
                if (result.ok) toast.success("The ticket has been closed");
                else toast.error("The ticket could not be closed. Please try again.");
              })
            }
          >
            {isPending ? "Closing…" : "Close ticket"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
```

## Related skills

- `frontend-design-guide` — tokens, component states and visual rules.
- `ux-laws` — Hick (one primary action), Feedback Loops (confirming destructive actions).
- `backend-security-auditor` — the `closeTicket` server action must verify ownership / role.
