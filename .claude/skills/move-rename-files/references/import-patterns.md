# Import & Reference Patterns

Use these grep patterns with the Grep tool (`output_mode: "files_with_matches"`) to batch-discover all files referencing a given name.

## JS / TS

| What to find   | Pattern                       |
| -------------- | ----------------------------- |
| Static import  | `from ['"].*FileName`         |
| Dynamic import | `import\(['"].*FileName`      |
| Require        | `require\(['"].*FileName`     |
| Re-export      | `export.*from ['"].*FileName` |

**Tip:** grep for the bare name without extension (e.g., `UserCard`) to catch `.vue`, `.ts`, `.tsx`, etc.

## CSS / SCSS

| What to find | Pattern             |
| ------------ | ------------------- |
| @import      | `@import.*filename` |
| url()        | `url\(.*filename`   |

## Broad Search Strategy

When unsure what reference patterns exist in the codebase, start wide:

```
Grep pattern="ComponentName" path="src/" output_mode="files_with_matches"
```

Then inspect matched files to identify which specific patterns need updating.
