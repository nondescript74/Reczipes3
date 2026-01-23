# ZIP Extraction Diagnostic Guide

## Overview
The enhanced ZIP extraction now provides detailed logging to help diagnose any import issues with `.recipebook` files.

## Log Categories
All ZIP-related logs use the `book-import` category. Enable this in your diagnostic logger to see detailed extraction information.

## Extraction Flow

### Phase 1: Native Extraction Attempt
```
Starting ZIP extraction from: MyBook.recipebook
```

If native extraction succeeds:
```
Successfully extracted using NSFileCoordinator
```

If native extraction fails, proceeds to Phase 2:
```
NSFileCoordinator extraction failed: [error details]
Attempting manual ZIP extraction
ZIP file size: [bytes] bytes
```

### Phase 2: Manual ZIP Parsing

ZIP parsing now uses a **Central Directory-first approach** for reliability:

```
Starting manual ZIP parsing, size: [bytes] bytes
Found EOCD at offset [bytes]
Central directory at offset [bytes], [N] entries
Found [N] entries in central directory
```

#### Success Path
```
Created directory: Images/
Extracted (uncompressed): book.json ([bytes] bytes)
Extracted (DEFLATE): Images/recipe_123.jpg ([compressed] -> [uncompressed] bytes)
ZIP extraction complete: [N] files, [M] directories
Successfully extracted using manual parser
```

#### Error Scenarios

**Not a ZIP file:**
```
Not a valid ZIP file: signature=0x[value]
Error: File is not a valid ZIP archive
```

**Missing Central Directory:**
```
End of Central Directory not found
Error: Invalid ZIP file: End of Central Directory not found
```

**Corrupted Central Directory:**
```
Invalid central directory entry signature at [offset]
Error: Corrupted ZIP central directory
```

**Truncated/Corrupted ZIP:**
```
ZIP file truncated
Error: ZIP file is corrupted or truncated
```

**Decompression failure:**
```
Decompression failed: result=0, compressed=[bytes] bytes, expected=[bytes] bytes
Error: Could not decompress the file...
```

**No files extracted:**
```
ZIP extraction complete: 0 files, 0 directories
Error: No files found in ZIP archive
```

## Decompression Details

When DEFLATE compression (method 8) is encountered:

**First attempt (standard zlib):**
```
[No specific log - tries standard decompression silently]
```

**Fallback (raw DEFLATE with wrapper):**
```
Attempting raw DEFLATE decompression with zlib wrapper
Successfully decompressed [compressed] -> [uncompressed] bytes
```

## Common Issues and Solutions

### Issue: "Decompression failed: result=0, compressed=0 bytes"
**Cause:** ZIP file uses data descriptors (flags bit 3 set), sizes in local header are 0
**Previous behavior:** Would fail immediately trying to decompress 0 bytes
**Current behavior:** Reads actual sizes from Central Directory - works correctly!
**Solution:** Update to the latest version with Central Directory parsing

### Issue: "End of Central Directory not found"
**Cause:** File is not a complete ZIP archive or is severely corrupted
**Check:** ZIP files must end with EOCD signature (0x06054b50)
**Solution:** Re-export or re-download the file

### Issue: "Not a valid ZIP file"
**Cause:** File is not actually a ZIP archive
**Cause:** File is not actually a ZIP archive
**Check:** First 4 bytes should be `50 4B 03 04` (PK signature)
**Solution:** Re-export the recipe book

### Issue: "ZIP file is corrupted or truncated"
**Cause:** Incomplete file transfer or storage corruption
**Check:** File size matches what was exported
**Solution:** Re-transfer the file

### Issue: "Could not decompress the file"
**Cause:** Unsupported compression method or corrupted compressed data
**Check:** Compression method should be 0 (stored) or 8 (DEFLATE)
**Solution:** Export with different compression settings or re-export

### Issue: "No files found in ZIP archive"
**Cause:** ZIP only contains central directory, no actual file entries
**Check:** ZIP structure integrity
**Solution:** Re-export the recipe book

## Testing Your Fix

1. **Export a book:**
   - Choose a recipe book with images
   - Export as `.recipebook`
   - Check export logs for success

2. **Import on same device:**
   - Should use manual extraction (already have the data)
   - Check logs show extraction progress
   - Verify all files extracted

3. **Import on different device:**
   - Transfer via AirDrop/Files/email
   - Import the file
   - Check logs for any errors
   - Verify recipes and images appear correctly

## Helpful Console Filter
```
category:book-import
```

This will show only ZIP-related logs for easier troubleshooting.

## Expected File Structure in ZIP
```
MyRecipeBook.recipebook/
├── book.json               (metadata, always uncompressed or DEFLATE)
├── Images/                 (directory)
│   ├── cover_123.jpg      (book cover, usually DEFLATE)
│   ├── recipe_456.jpg     (recipe images, usually DEFLATE)
│   └── recipe_789.jpg
```

## Compression Methods
- **Method 0 (Stored)**: No compression, direct copy
- **Method 8 (DEFLATE)**: Standard ZIP compression (what we support)
- **Other methods**: Would fail with "Unsupported compression method" error

## zlib Header Structure
When wrapping raw DEFLATE:
```
Byte 0: 0x78 (CMF - DEFLATE with 32K window)
Byte 1: Calculated FLG byte (ensures FCHECK validity)
Bytes 2-N: Compressed DEFLATE stream
Bytes N+1 to N+4: Adler-32 checksum (currently zeros)
```

The FCHECK calculation ensures `(CMF * 256 + FLG) % 31 == 0`, which is required by RFC 1950.
