---
name: file-introspection
version: "1"
description: Identify and analyse files of unknown, obscure, or untrusted type using exiftool, magick identify, file, magika, strings, and hexyl. Load before processing any file whose format is unclear, when extensions are missing or untrustworthy, or when metadata and binary structure must be understood before acting on a file.
---

# File Introspection

Probe files systematically before processing them. The goal is confident knowledge of format, structure, embedded metadata, and integrity — especially when file extensions are absent, wrong, or untrusted.

## Tool Overview

| Tool | Best for |
|---|---|
| `file` | Magic-byte identification, all types — fast and universal |
| `magika` | ML-based type detection — more reliable on ambiguous or adversarial inputs |
| `exiftool` | Rich metadata from images, PDFs, audio, video, Office docs |
| `magick identify` | Image format, dimensions, colour space, corruption status |
| `strings` | Extracting printable text clues from binary blobs |
| `hexyl` | Visualising raw byte structure, magic signatures, file headers |

## Workflow

Always identify first, then select the appropriate deep-dive tool(s).

### Step 1 — Identify

Run both tools; cross-check results.

```bash
file <path>
magika <path>
```

- **Both agree** → proceed to Step 2 with confidence.
- **They disagree**, or either returns `data` / `application/octet-stream` / `unknown` → go to Step 3 (binary inspection) before Step 2.
- Prefer `magika` for untrusted or adversarial inputs — ML-based and harder to fool with spoofed magic bytes.

### Step 2 — Deep-dive by type

**Images** (JPEG, PNG, TIFF, WebP, HEIC, RAW, PSD, SVG, …)
```bash
magick identify -verbose <path>
exiftool -a -u -G <path>
```
`magick identify` reports colour space, bit depth, ICC profiles, dimensions, and corruption status. `exiftool` adds EXIF/IPTC/XMP, GPS, camera model, and embedded thumbnails. Always run both — they surface different information.

**Documents and PDFs** (PDF, DOCX, XLSX, ODT, EPUB, …)
```bash
exiftool -a -u -G <path>
```
Reports author, creation/modification timestamps, software, page count, embedded fonts, encryption status, and macro indicators.

**Audio / video** (MP3, FLAC, MP4, MKV, MOV, …)
```bash
exiftool -a -u -G <path>
```
Reports codec, duration, bitrate, sample rate, embedded artwork, and ID3/Vorbis/XMP tags.

**Unknown or binary blobs** → go to Step 3.

### Step 3 — Binary inspection

Use this whenever type is uncertain, or to supplement Step 2 for any file.

```bash
hexyl <path> | head -n 32           # First ~256 bytes — magic bytes and header structure
strings -n 8 <path> | head -n 60    # Printable strings (min length 8 reduces noise)
```

**What to look for in `hexyl` output:**

Magic signatures in the first 4–16 bytes identify most formats:

| Bytes (hex) | Format |
|---|---|
| `50 4B 03 04` (`PK\x03\x04`) | ZIP — and by extension DOCX, XLSX, PPTX, JAR, APK |
| `25 50 44 46` (`%PDF`) | PDF |
| `89 50 4E 47` | PNG |
| `FF D8 FF` | JPEG |
| `47 49 46 38` (`GIF8`) | GIF |
| `52 49 46 46` (`RIFF`) | WAV or AVI (check bytes 8–11 for `WAVE`/`AVI `) |
| `1F 8B` | gzip |
| `42 5A 68` (`BZh`) | bzip2 |
| `D0 CF 11 E0` | Legacy OLE2 (XLS, DOC, PPT pre-2007) |
| `7F 45 4C 46` | ELF binary |
| `4D 5A` (`MZ`) | Windows PE/EXE |

After the magic: look for version fields, chunk markers, endianness indicators (little-endian `FF FE` or `FF FF FE 00` = UTF-16/32 BOM).

**What to look for in `strings` output:**
- Embedded filenames, paths, URLs → reveal origin or intended format
- XML declarations, JSON fragments, `<!DOCTYPE` → nested or wrapped formats
- Version strings, tool names, copyright notices → authoring software
- Format markers like `JFIF`, `Exif`, `ICC_PROFILE` → confirm or extend type identification

### Step 4 — Comprehensive sweep (when thorough analysis is needed)

```bash
file <path> && magika <path> && exiftool -a -u -G <path>
```

For images, always add `magick identify -verbose <path>` to the above.

## Key Rules

- **Never trust the extension.** Verify with `file` and/or `magika` against actual bytes before acting.
- **Always use `-a -u -G` with exiftool.** `-a` surfaces duplicate tags, `-u` unknown tags, `-G` tag group names — together they expose the maximum available metadata.
- **Default `strings` min length is 4 — too noisy.** Use `-n 8` for binary blobs; `-n 6` is acceptable for very sparse files.
- **Pipe `hexyl` through `head`.** The first 32 lines (~256 bytes) almost always suffices to identify structure; full output of large files is overwhelming.
- **High entropy = compressed or encrypted.** If `hexyl` shows a near-uniform byte distribution with few repeated patterns, standard introspection will not recover structure — flag this and do not attempt text extraction.

## Gotchas

- **`magick identify` can hang on maliciously crafted images.** Wrap with a timeout: `timeout 10 magick identify -verbose <path>`.
- **Modern Office files are ZIP archives.** `file` reports them as `Zip archive data`; `exiftool` correctly identifies the Office subtype. If `file` says ZIP but the extension or context suggests Office, try `exiftool` before manually unzipping.
- **`exiftool` validates metadata, not file integrity.** A file can have complete, valid metadata and still be truncated or corrupt. Use `magick identify` to check image integrity; for other formats, attempt parsing in a sandboxed context.
- **`file` can be fooled by polyglot files** (valid as two formats simultaneously). `magika` handles these better — use it as the authoritative result when they disagree.
- **`hexyl` outputs ANSI colour codes.** If piping to a log or file: `hexyl <path> | cat` strips colour, or use `--no-squeezing` for cleaner plain output.
- **`exiftool` on a PDF reporting `Linearized: Yes`** means the PDF is optimised for web streaming — not that it is valid or complete.
- **`strings` on encrypted content returns garbage.** High-entropy files (confirmed by `hexyl`) should be flagged as encrypted/compressed rather than processed further with string extraction.

## Examples

**File with no extension, possibly an image**
```bash
file mystery_blob                     # → JPEG image data
magika mystery_blob                   # → image/jpeg
magick identify -verbose mystery_blob # → dimensions, colour space, profiles
exiftool -a -u -G mystery_blob        # → EXIF metadata, GPS, camera
```

**Completely unknown binary**
```bash
file unknown.bin    # → data
magika unknown.bin  # → application/octet-stream
hexyl unknown.bin | head -n 32      # → magic bytes show 50 4B 03 04 (PK)
strings -n 8 unknown.bin | head -n 60  # → "[Content_Types].xml" — it's an Office file
exiftool -a -u -G unknown.bin       # → identifies as XLSX, reveals author and dates
```

**Suspicious document before opening**
```bash
file report.docx    # → Zip archive data
magika report.docx  # → application/vnd.openxmlformats-officedocument.wordprocessingml.document
exiftool -a -u -G report.docx  # → check Creator, Software, revision count, macro indicators
strings -n 8 report.docx | grep -i "macro\|vba\|autoopen"  # → scan for macro strings
```
