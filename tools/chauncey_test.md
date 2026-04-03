# Chauncey Hardware Test Plan
**Test Machine**: Dell x86_64 (Chauncey)
**Image**: `codebook.img` (64MB, FAT32)
**Boot Mode**: Legacy BIOS (disable UEFI)

---

## **🔧 Prerequisites**
1. Flash `codebook.img` to USB:
   ```bash
   sudo dd if=codebook.img of=/dev/sdX bs=4M status=progress
   sync
```

2. Boot Chauncey with:
   - USB as first boot device.
   - Legacy BIOS (CSM) enabled.
   - Secure Boot disabled.

---

## **🧪 Test Cases**

| # | Test Case | Expected Result | Notes |
|---|-----------|-----------------|-------|
| 1 | Power-on + Splash Screen | Codebook logo appears. | Check for GPU/display initialization. |
| 2 | Bastian Home Menu | Menu renders with all 12 app names. | Press arrows to navigate. |
| 3 | Gmork Terminal | Commands execute (e.g., ls, help). | Test keyboard input (PS/2 scancodes). |
| 4 | ls Command | Lists files in FAT32 partition. | Verify demo.cbc exists. |
| 5 | load demo.cbc | Runs demo app. | Check for success message. |
| 6 | Atreyu Editor | Accepts input and saves files. | Type text, save test.txt, reboot, ls. |
| 7 | Auryn Display Integration | Windows render correctly. | Open multiple windows. |
| 8 | Network (Falkor) | Connects to Wi-Fi/Ethernet. | Test ping or falkor app. |
| 9 | Reboot | System reboots cleanly. | Check for filesystem corruption. |
| 10 | Power-off | System shuts down cleanly. | No kernel panics. |

---

## **🔍 Hardware-Specific Checks**

| Issue | Debug Steps |
|-------|-------------|
| Dell PS/2 Scancodes | Patch keyboard.asm for Dell scancodes. |
| Intel iGPU Framebuffer | Validate fb_base in gpu_intel.asm. |
| USB xHCI Timeout | Check fat32_read_sector PIO timings. |
| RAM/ACPI Errors | Audit mmap_buf for reserved regions. |
| Legacy BIOS vs. UEFI Quirks | Disable UEFI in BIOS, use CSM. |

---

## **📝 Test Log Template**

| Timestamp | Test Case | Result | Notes | Repro Steps |
|-----------|-----------|--------|-------|-------------|
| 2026-04-03 14:30 | Power-on + Splash | ✅ | Logo appears | N/A |
| 2026-04-03 14:32 | Bastian Home Menu | ❌ | Menu not rendering | Check GPU initialization |

---

## **🎯 Final Validation**

- All tests pass → Tag v1.0 in Git.
- Any failures → Document in HARDWARE_QUirks.md.
- Production Image: Rename codebook.img to CodebookOS_v1.0.img (64MB).