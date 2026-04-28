<!--
SOURCE: reconstructed on 2026-04-27 from:
  - Terminal Boy's session conversation summary
    (preserves prompt content and structure per sub-pod with high fidelity)
  - commit history and commit messages
  - recon reports under recon/
  - canonical document references (RECONSTITUTION.md, ARCHAEOLOGY.md, DEFERRED.md)
Original prompt-as-given may have varied in detail. Structure is preserved
with high fidelity to the executed work; specific phrasing should not be
treated as authoritative.
-->

# CodebookOS — Pod 0.2 Coder Prompt

## Extract auryn.asm — Framebuffer Renderer

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.2 of 10.9 — Foundation Lock, Section 2
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`.
**Prerequisite:** Pod 0.1 committed (4f02dcd). defines.asm extracted.

---

## Mission

Extract the auryn framebuffer renderer functions from `boot/boot.asm`
into `boot/auryn.asm`. The extraction covers the four core framebuffer
functions: `auryn_fill`, `auryn_scroll`, `auryn_paint`, `auryn_putc`.

Note: `auryn_puts` was identified as living in `morla.asm` (non-contiguous
in the original monolith). This was documented in auryn.asm's header
rather than moved — the move is deferred to Pod 0.7.

---

## What was extracted

- `auryn_fill` — fills the framebuffer with a solid color
- `auryn_scroll` — scrolls the framebuffer up by one text row
- `auryn_paint` — paints a single pixel at (x, y)
- `auryn_putc` — renders a single character at the cursor position

Header format established:
```nasm
; =============================================================
; Auryn — Framebuffer Renderer
; The amulet of Fantastica. Turns memory into visible reality.
; Functions: auryn_fill, auryn_scroll, auryn_paint, auryn_putc
; (auryn_puts lives in morla.asm — non-contiguous in original monolith)
; Depends: fb_base, fb_width, fb_height, fb_ppsl, cursor_x, cursor_y,
;          current_color, font_data (in data.asm, extracted Pod 0.7)
; Extracted from boot.asm (Pod 0.2)
; =============================================================
```

---

## Verification

- `tools/verify_binary.sh` must report `OK: binary matches reference`
- `boot/auryn.asm` contains the four auryn functions (220 lines)
- `boot/boot.asm` `%include`s auryn.asm in the correct position

---

## Commit

```
pod0.2: extract auryn.asm — framebuffer renderer
```

Landed at commit `4489d01`.
