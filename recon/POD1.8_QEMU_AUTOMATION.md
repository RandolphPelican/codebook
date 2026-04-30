# QEMU Bare-Metal Test Automation — Named Pipe + Sendkey + Screendump

**Captured:** Pod 1.8 (April 29, 2026)
**Reconstructed from:** Pod 1.7 chat history + build/*.png artifacts
**Status:** Standing reference for all future pod QEMU tests

---

## Prerequisites

- WSL2 Ubuntu with QEMU and OVMF installed
- Python3 with PIL/Pillow (`pip3 install Pillow`)
- Built `codebook.img` in `build/`

## Method

### 1. Create named pipes for QEMU monitor

```bash
rm -f /tmp/qemu_mon.in /tmp/qemu_mon.out
mkfifo /tmp/qemu_mon.in /tmp/qemu_mon.out
```

QEMU uses the `.in` / `.out` suffix convention for pipe monitor.

### 2. Launch QEMU daemonized with pipe monitor

```bash
qemu-system-x86_64 \
    -drive file=build/codebook.img,format=raw \
    -bios /usr/share/ovmf/OVMF.fd \
    -display none \
    -monitor pipe:/tmp/qemu_mon \
    -daemonize
```

`-display none` = headless. `-daemonize` = background process.

### 3. Send keystrokes via monitor pipe

```bash
echo 'sendkey 2' > /tmp/qemu_mon.in       # select Gmork Terminal
sleep 1
echo 'sendkey ret' > /tmp/qemu_mon.in     # confirm
```

Key names follow QEMU monitor convention:
- Letters: `a`, `b`, `c`, etc. (lowercase)
- Numbers: `0`, `1`, `2`, etc.
- Special: `ret` (Enter), `spc` (Space), `dot` (.), `shift-minus` (_)
- Modifiers: `shift-a` (A), etc.

**Important:** Use `spc` for space, NOT `space`. `space` is silently ignored.

### 4. Type a command character by character

```bash
for key in l o a d spc t e s t shift-minus e n e r g y dot c b c; do
    echo "sendkey $key" > /tmp/qemu_mon.in
    sleep 0.15
done
echo 'sendkey ret' > /tmp/qemu_mon.in
```

Sleep between keys prevents dropped keystrokes.

### 5. Capture screen via screendump

```bash
echo 'screendump /tmp/qemu_result.ppm' > /tmp/qemu_mon.in
sleep 1
python3 -c "
from PIL import Image
img = Image.open('/tmp/qemu_result.ppm')
img.save('build/test_result.png')
"
```

PPM is QEMU's native screendump format. PIL converts to PNG for review.

### 6. Quit QEMU

```bash
echo 'quit' > /tmp/qemu_mon.in
```

## Timing

- Allow 5s after QEMU launch for UEFI boot + Bastian menu
- Allow 2s after menu selection for surface to load
- Allow 3–4s after program load command for VM execution
- Allow 1s after screendump for file write to complete

## Artifacts

Pod 1.7 screenshots: `build/sign_test_*.png`, `build/gmork_prompt.png`
Pod 1.8 screenshots: `build/energy_test_result*.png`, `build/energy_boot.png`
