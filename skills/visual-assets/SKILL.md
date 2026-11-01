---
name: visual-assets
description: "Raster and media assets for websites: choosing the source of each image (real photo, screenshot, stock, illustration, AI), formats and sizes, a reproducible image pipeline with sharp (AVIF/WebP, responsive widths, art direction, stripped metadata), placeholders while loading, consistent photo art direction and stock licenses, AI-generated images through an image-generation MCP server or API (when to use them, a reusable style brief, honesty rules, licenses, disclosure, alt text), device and browser mockups from real screenshots, background and content video and replacing GIFs, Lottie/dotLottie and Rive animations, canvas/WebGL/3D scenes with fallbacks, and an asset log with provenance. Use when a page needs images, photos, a hero visual, mockups, video, animated assets or a 3D scene, or when the user asks to generate images with AI. SVG is in svg-graphics; LCP rules and budgets in web-performance; OG images in seo-metadata; app icons in pwa-mobile; motion rules in magic-animations."
triggers:
  - "hero image / photos / images for the website"
  - "generate an image with AI / AI illustration"
  - "product mockup / screenshot in a device frame"
  - "background video / replace a GIF"
  - "Lottie / Rive / 3D / three.js / WebGL scene"
  - "obrázky na web / vygeneruj obrázek / fotky"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Visual assets

Images decide whether a site feels real. Generated sites fall back on the same choices:
generic stock (a handshake, a laptop on a desk), AI faces presented as customers, fake
dashboard screenshots, a 4 MB PNG hero, a GIF where a video would be ten times smaller, and
a WebGL background that drains the phone battery. This skill picks the right source for each
asset, produces it through a repeatable pipeline and records where it came from.

## Process

1. **List the assets** each page needs (hero, sections, product, people, backgrounds) and pick the source of each (section 1). **Real beats generated:** real product screenshots, real team photos.
2. **Produce** them through the pipeline (section 2) within the budgets in `web-performance`.
3. **Art-direct** them consistently (section 3); AI images follow the style brief (section 4).
4. **Write alt text** and record source and license in the asset log (section 9).
5. **Check** LCP, CLS, both themes and mobile crops.

---

## 1. Choosing the source

| Need | Best source | Avoid |
|------|-------------|-------|
| The product | real screenshots in a frame (section 5) | AI-generated UI, stock "dashboard" photos |
| People: team, customers, testimonials | real photos, with consent | stock or AI faces presented as real people |
| Atmosphere, hero background, texture | a photo, an AI image (section 4), a gradient or noise in SVG (`svg-graphics`) | the same stock photo every competitor uses |
| Illustrations | SVG (`svg-graphics`), an illustration library with a clear license, a designer, AI with a fixed style | three illustration styles on one site |
| Data | a real chart | a picture of a chart |
| Places, events, results | real photos | AI images that look like a real place or event |

## 2. Formats and the pipeline

| Content | Format |
|---------|--------|
| Photos | **AVIF** (smallest), WebP as the universal fallback, JPEG only for email and legacy targets |
| Screenshots with UI text | WebP or AVIF at a higher quality, or PNG — low quality blurs text |
| Transparency | AVIF, WebP or PNG |
| Logos, icons, illustrations | SVG (`svg-graphics`) |
| Animation | video (section 6), Lottie or Rive (section 7) — **never GIF** |

- **Content images** go through the framework's image component, which resizes and converts: `next/image`, Astro `<Image>` / `<Picture>` (`web-performance` covers priority, `sizes` and LCP).
- **Assets outside the framework** (email images, OG image sources, downloads, CMS imports) go through a script, so the result is reproducible:

```js
// scripts/build-images.mjs — npm i -D sharp; run: node scripts/build-images.mjs
import { mkdir, readdir } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const SOURCE_DIR = "assets/photos";
const OUTPUT_DIR = "public/images";
const WIDTHS = [640, 960, 1280, 1920];

await mkdir(OUTPUT_DIR, { recursive: true });
for (const file of await readdir(SOURCE_DIR)) {
  if (!/\.(jpe?g|png|tiff?)$/i.test(file)) continue;
  const name = path.parse(file).name;
  for (const width of WIDTHS) {
    // rotate() applies the EXIF orientation; sharp drops the metadata (incl. GPS) from the output by default
    const image = sharp(path.join(SOURCE_DIR, file)).rotate().resize({ width, withoutEnlargement: true });
    await image.clone().avif({ quality: 50 }).toFile(path.join(OUTPUT_DIR, `${name}-${width}.avif`));
    await image.clone().webp({ quality: 75 }).toFile(path.join(OUTPUT_DIR, `${name}-${width}.webp`));
  }
}
```

- **Originals stay outside `public/`** (`assets/`, the CMS or a storage bucket); outputs are generated from them.
- **Metadata:** photos from phones contain GPS coordinates — never publish originals; the pipeline strips them.
- **Art direction:** a different crop for mobile and desktop uses `<picture>` with `<source media>` (Next.js `getImageProps()`, Astro `getImage()`), not one desktop crop squeezed onto a phone.
- **Placeholders:** reserve the space first (width/height or `aspect-ratio` — CLS rules in `web-performance`), then a dominant-color background or a tiny blurred preview: `placeholder="blur"` in `next/image`; Astro has none built in — generate a ThumbHash or BlurHash at build time or use the dominant color.

## 3. Photos and art direction

- **One treatment across the site:** the same color grading, crop style (tight or wide), light (bright or moody), grain or duotone. Write it into `DESIGN.md` next to the aesthetic direction (`frontend-design-guide`).
- **Text over photos** only with a scrim or overlay that keeps the contrast thresholds in `a11y-auditor` — check the worst part of the image, not the average.
- **Responsive crops:** keep the subject inside a safe area so the mobile crop still works; faces looking towards the content, not off the page.
- **Stock licenses:** read them. Common free licenses (Unsplash, Pexels) allow commercial use without attribution but forbid, for example, selling unaltered copies; editorial-only images can't be used in marketing; recognizable people, brands and buildings may need releases. Record the source in the asset log (section 9).
- Never use images from a search engine, strip watermarks or "borrow" from competitors.

## 4. AI-generated images

**Good uses:** hero and section backgrounds, abstract and atmospheric images, textures,
concept illustrations in one fixed style, mood boards, clearly marked placeholders in
concepts.

**Not:** product screenshots and UI, real people (team, customers, testimonials), real places,
events or results presented as real, logos (trademarks, and they must be vectors), images
with text in them (often garbled — put text in HTML).

**Tooling.** Claude Code does not generate images itself. Use an image-generation MCP server
or API from a provider the user has an account with (for example, Replicate publishes an
official MCP server, `replicate-mcp`). Before using one, check the price per image, the
model's license and commercial-use terms, and what happens to uploaded reference images.
Keys go into environment variables, never into the repository.

**Style brief** — write it once, store it in `DESIGN.md`, reuse it in every prompt:

```markdown
## Image style (AI)
- Medium: soft-light photography, shallow depth of field / flat vector illustration with grain
- Palette: deep forest green and warm off-white with one coral accent (from the tokens)
- Light and mood: morning light, calm, no dramatic contrast
- Composition: subject on the right third, quiet space on the left for the headline
- Always: no text, no logos, no watermarks, no people unless requested
- Aspect ratios: hero 16:9 (mobile crop 4:5), cards 4:3
```

- **Compose for the slot:** the aspect ratio of the layout, empty space where the headline sits, the subject inside the mobile crop.
- **Generate several, choose, post-process:** crop, correct the colors towards the tokens, upscale only when needed, then run the pipeline (section 2).
- **Inspect every image** for artifacts: hands, faces, garbled letters, impossible geometry, wrong product details.
- **Disclosure** `[LEGAL: check the current EU AI Act transparency timeline and national rules]`: realistic images that could be mistaken for real people, places or events must be labeled as AI-generated (`ai-features`); decorative abstract images generally don't need a label. Never present AI images as real customers or real results.
- **Copyright** `[LEGAL: protection of AI-generated works in the target jurisdictions]`: purely generated images are often not protected by copyright, so others may reuse them. Commission brand-critical visuals.
- **Provenance:** provider, model, prompt and date go into the asset log; alt text describes content and purpose like for any image.

## 5. Mockups from real screenshots

- **Screenshots with Playwright** at 2× scale, with realistic demo data — no real customer data, no lorem ipsum:

```ts
// scripts/screenshots.ts — run against the dev server: npx tsx scripts/screenshots.ts
import { chromium } from "playwright";

const browser = await chromium.launch();
for (const colorScheme of ["light", "dark"] as const) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, colorScheme });
  await page.goto("http://localhost:3000/dashboard?demo=1");
  await page.screenshot({ path: `assets/screens/dashboard-${colorScheme}.png` });
  await page.close();
}
await browser.close();
```

- **Frames:** browser and device frame components (Safari or iPhone mockups in registries — `component-registries`) or a simple CSS frame, not raster mockup templates with outdated devices.
- **Keep them current:** a `screenshots` script in `package.json`, regenerated when the UI changes; light and dark variants if the site has both themes.
- **Crop to the story** (the one panel that matters) and put callouts in HTML, not baked into the image.

## 6. Video

Background or hero video — short (5–15 s), silent, decorative:

```html
<video autoplay muted loop playsinline poster="/media/hero-poster.avif" width="1280" height="720" aria-hidden="true">
  <source src="/media/hero.webm" type="video/webm" />
  <source src="/media/hero.mp4" type="video/mp4" />
</video>
```

- **The poster is the LCP element** — optimize it like a hero image.
- **Reduced motion and mobile data:** with `prefers-reduced-motion` show the poster only; consider the poster only on small screens.
- **A pause control** for any moving content that starts automatically and lasts more than 5 seconds (WCAG 2.2.2 — `a11y-auditor`).
- **Content video** (demos, tutorials): captions and a transcript; long videos through a video platform or adaptive streaming (HLS); YouTube or Vimeo behind a facade (`web-performance`) and consent (`gdpr-privacy`).
- **Replace GIFs** — a video is typically several times smaller:

```bash
ffmpeg -i demo.gif -movflags +faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" demo.mp4
ffmpeg -i demo.gif -c:v libvpx-vp9 -b:v 0 -crf 40 demo.webm
```

- **Compress background video** without audio: `ffmpeg -i hero.mov -c:v libx264 -crf 28 -preset slow -an -movflags +faststart hero.mp4`.

## 7. Lottie, Rive and other animated assets

| Format | Use for | Notes |
|--------|---------|-------|
| Lottie / dotLottie (`@lottiefiles/dotlottie-react`, `@lottiefiles/dotlottie-web`) | designer-made animated illustrations (After Effects exports) | `.lottie` is a zipped, smaller package than JSON; the player costs JavaScript — load it lazily |
| Rive (`@rive-app/react-canvas`) | interactive animations with states: toggles, mascots, onboarding | needs the Rive editor; test performance on mid-range phones |
| CSS / SVG animation | simple loops, line drawing, icons | `svg-graphics` |
| Video | photographic or very complex motion | section 6 |

```tsx
"use client";
import { DotLottieReact } from "@lottiefiles/dotlottie-react";
import { useReducedMotion } from "motion/react";

export function SuccessAnimation() {
  const reduceMotion = useReducedMotion();
  // With reduced motion the first frame is shown as a still — make sure it works on its own
  return <DotLottieReact src="/animations/success.lottie" autoplay={!reduceMotion} loop={false} />;
}
```

- No endless loops next to text people read; pause when off-screen; motion rules and budget in `magic-animations`.

## 8. Canvas, WebGL and 3D

- **Only as the page's signature moment** (`component-registries`) and only when it explains something — the product in 3D, a globe for global reach. Not as decoration behind text.
- **three.js / React Three Fiber** (`@react-three/fiber`, `@react-three/drei`):
  - a **static image first** — it is the LCP element and the fallback; the scene loads lazily (dynamic import, Astro `client:visible`);
  - cap the pixel ratio (`dpr={[1, 2]}`), use `frameloop="demand"` for scenes that don't animate constantly, pause when off-screen, dispose geometries and textures on unmount;
  - **mobile:** a simpler model or the static image; **reduced motion:** the static image.
- **Assets:** compress models — `npx @gltf-transform/cli optimize input.glb output.glb --texture-compress webp` (Draco or Meshopt geometry, smaller textures).
- Measure INP and LCP with the scene on a mid-range phone (`web-performance`, `chrome-devtools`).

## 9. Asset log

A small file in the repository keeps provenance for licenses, renewals and disclosure:

```markdown
<!-- docs/assets.md -->
| File | Source | License / terms | Author / model | Date | Notes |
|------|--------|-----------------|----------------|------|-------|
| public/images/hero-forest-*.avif | AI (provider, model) | provider terms: commercial use allowed | prompt in docs/prompts/hero.md | 2026-11-01 | abstract, no label needed |
| public/images/team-01.avif | own photo | consent on file | photographer | 2026-10-12 | |
| public/images/office.avif | Unsplash | Unsplash License | photographer | 2026-10-20 | |
```

---

## Checklist

- [ ] Every asset has a deliberate source; product images are real screenshots; people are real and consented.
- [ ] No AI or stock image is presented as a real customer, place, event or result.
- [ ] Formats: AVIF/WebP for photos, SVG for vectors, video instead of GIF.
- [ ] Originals outside `public/`; outputs generated by the framework component or a script; metadata stripped.
- [ ] Space reserved for every image and video; LCP image or poster prioritized (`web-performance`).
- [ ] One photo and illustration treatment across the site; AI images follow the style brief.
- [ ] Text over images keeps the contrast thresholds; no text baked into images.
- [ ] Alt text written for meaningful images; decorative images `alt=""`.
- [ ] Video: muted autoplay only for decorative loops, pause control over 5 s, captions for content video, reduced motion respected.
- [ ] Lottie, Rive and 3D load lazily, have a static fallback and respect reduced motion.
- [ ] Sources, licenses and AI provenance recorded in `docs/assets.md`.

## Anti-patterns

- Stock clichés: handshakes, a laptop on a desk, a team high-fiving in an office.
- AI faces in testimonials, AI "screenshots" of the product, AI photos of an event that never happened.
- A 4 MB PNG hero or a 1920 px image in a 400 px card.
- GIF demos.
- Text baked into images: it doesn't translate, scale or pass contrast checks.
- Five photo styles and three illustration styles on one site.
- A WebGL background behind body text on mobile.
- Images copied from search results or competitors.

## Output format

```markdown
## Asset plan: / (direction: "calm, natural, product-first")

| Slot | Source | Format and sizes | Alt text | Status |
|------|--------|------------------|----------|--------|
| Hero | dashboard screenshot (light + dark) in a browser frame | AVIF/WebP 960–1920 px, priority | "Invoice dashboard showing three overdue invoices" | ✅ generated by scripts/screenshots.ts |
| Hero background | AI texture per style brief | AVIF 1920 px, decorative | "" | ✅ logged in docs/assets.md |
| Team | own photos, consent on file | AVIF/WebP 640 px, 1:1 crop | names and roles | ⏳ waiting for photos |
| Demo | GIF → MP4 + WebM, poster AVIF | 1.8 MB → 240 KB | captions not needed (no speech) | ✅ |
```

## Related skills

- `svg-graphics` — icons, illustrations, patterns, logos and favicons in SVG.
- `web-performance` — budgets, LCP image priority, CLS and lazy loading.
- `frontend-design-guide` and `impeccable-workflow` — the aesthetic direction and `DESIGN.md`.
- `component-registries` — device and browser frames, the signature moment.
- `magic-animations` — motion rules; `a11y-auditor` — alt text, contrast, pause controls.
- `seo-metadata` — OG images; `pwa-mobile` — app icons; `ai-features` — AI disclosure; `gdpr-privacy` — embeds and consent.
