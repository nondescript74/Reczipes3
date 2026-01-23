# Recipe Book Import Decompression Fix

## Problem
Recipe Book imports were failing with "could not decompress" errors when trying to import `.recipebook` files.

## Root Causes

### Issue 1: Raw DEFLATE vs zlib-wrapped DEFLATE
ZIP files use **raw DEFLATE compression** (RFC 1951), while Apple's Compression framework expects **zlib-wrapped DEFLATE** (RFC 1950).

The difference:
- **Raw DEFLATE**: Just the compressed data stream (used by ZIP format)
- **zlib format**: Adds a 2-byte header + compressed data + 4-byte Adler-32 checksum

The original code attempted to wrap raw DEFLATE with a zlib header but used incorrect header bytes without proper FCHECK validation.

### Issue 2: Data Descriptor Flag (Bit 3)
When the ZIP general purpose bit flag has **bit 3 set** (value 8), the compressed and uncompressed sizes are stored in a **data descriptor** after the compressed data, not in the local file header. The local header contains zeros for these fields.

This is common when:
- ZIP files are created by streaming compressors
- The final size isn't known when compression starts
- macOS/iOS native ZIP creation with `NSFileCoordinator`

The original parser read sizes from the local header (getting 0 bytes), causing decompression to fail immediately.

## Solution
The fix implements a robust ZIP extraction strategy:

### 1. Central Directory Parsing (New!)
Instead of reading sizes from local file headers (which can be 0 when data descriptors are used), the parser now:

1. **Locates the End of Central Directory (EOCD)** record at the end of the ZIP file
2. **Reads the Central Directory** which contains the authoritative file information
3. **Extracts files using Central Directory metadata** (always has correct sizes)

This handles ZIP files with data descriptors correctly, regardless of how they were created.

### 2. Proper zlib Header Wrapping

#### CMF Byte (Compression Method and Flags)
- Value: `0x78`
- Bits 0-3: Compression method (8 = DEFLATE)
- Bits 4-7: Window size (7 = 32K window)

#### FLG Byte (Flags)
- Calculated dynamically to ensure `(CMF * 256 + FLG) % 31 == 0`
- This is the FCHECK requirement from RFC 1950
- Starts with base value `0x9C` (default compression level)
- Adjusts if needed to satisfy the modulo 31 check

#### Adler-32 Checksum
- Added 4 zero bytes at the end
- While not a valid checksum, decompression works without validation
- Could be enhanced to compute actual Adler-32 if needed

### 3. Two-Phase Extraction
1. **Phase 1**: Try native `NSFileCoordinator` extraction (fast path)
2. **Phase 2**: Fall back to manual parsing with central directory support

## Code Changes

### Before (Broken with Data Descriptors)
```swift
// Read sizes from local file header (can be 0!)
let compressedSize = Int(data.withUnsafeBytes { ... })
let uncompressedSize = Int(data.withUnsafeBytes { ... })

// Try to decompress 0 bytes -> FAIL
let compressedData = data.subdata(in: offset..<(offset + compressedSize))
fileData = try decompressDeflate(compressedData, uncompressedSize: uncompressedSize)
```

### After (Robust Central Directory Approach)
```swift
// 1. Find and parse the central directory
let centralDir = try parseCentralDirectory(data)

// 2. Extract files using authoritative sizes from central directory
for entry in centralDir {
    let compressedData = try readFileData(
        from: data,
        at: entry.localHeaderOffset,
        compressedSize: entry.compressedSize  // ✅ Always correct!
    )
    
    // 3. Decompress with proper sizes
    fileData = try decompressDeflate(
        compressedData,
        uncompressedSize: entry.uncompressedSize  // ✅ Always correct!
    )
}
```

### zlib Header Fix
```swift
// Proper zlib header with FCHECK validation
var zlibData = Data()

let cmf: UInt8 = 0x78  // DEFLATE with 32K window

// Calculate FLG to satisfy (CMF*256 + FLG) % 31 == 0
var flg: UInt8 = 0x9C
let fcheck = (UInt16(cmf) * 256 + UInt16(flg)) % 31
if fcheck != 0 {
    flg = flg + UInt8(31 - fcheck)
}

zlibData.append(cmf)
zlibData.append(flg)
zlibData.append(data)

// Add Adler-32 placeholder
zlibData.append(contentsOf: [0, 0, 0, 0])
```

## Testing
To test the fix:
1. Export a recipe book from the app
2. Share the `.recipebook` file to another device
3. Import it - should now work without decompression errors

## References
- RFC 1950: ZLIB Compressed Data Format Specification
- RFC 1951: DEFLATE Compressed Data Format Specification  
- ZIP File Format Specification (PKWARE)
- **APPNOTE.TXT** - ZIP specification section 4.4.4 (general purpose bit flag)
- **APPNOTE.TXT** - ZIP specification section 4.3.9 (data descriptor)

## Key Technical Details

### ZIP General Purpose Bit Flag
```
Bit 0: Encrypted file
Bit 1: Compression option  
Bit 2: Compression option
Bit 3: Data descriptor used  ← THIS WAS THE PROBLEM!
Bit 4: Enhanced deflating
Bit 5: Compressed patched data
...
```

When **bit 3 = 1** (flags & 0x08):
- Local header has compressed size = 0
- Local header has uncompressed size = 0
- Actual sizes follow the compressed data in a data descriptor
- **Must use Central Directory for correct sizes**

### ZIP File Structure
```
┌─────────────────────────────┐
│ Local File Header 1         │ ← May have size = 0
│ File Data 1                 │
│ [Data Descriptor 1]         │ ← Only if bit 3 set
├─────────────────────────────┤
│ Local File Header 2         │
│ File Data 2                 │
│ [Data Descriptor 2]         │
├─────────────────────────────┤
│ ...                         │
├─────────────────────────────┤
│ Central Directory           │ ← ALWAYS has correct sizes ✅
├─────────────────────────────┤
│ End of Central Directory    │ ← Start here, work backwards
└─────────────────────────────┘
```

## Future Enhancements
If needed, could implement:
1. Actual Adler-32 checksum calculation for validation
2. Support for other ZIP compression methods (BZIP2, LZMA, etc.)
3. ZIP64 support for very large archives

## Version History Entry
Added in version **15.3.103**:
- 🐛 **CRITICAL FIX**: Recipe Book import now handles ZIP files with data descriptors (flags bit 3)
- 🔧 Enhanced: ZIP extraction now parses Central Directory for authoritative file sizes
- ✅ Fixed: .recipebook files created by macOS/iOS native compression now import successfully  
- 📊 Added: Comprehensive diagnostic logging for ZIP extraction troubleshooting
- 🔍 Added: Better error messages identifying specific ZIP format issues
- ⚡️ Improved: Proper zlib header wrapping with FCHECK validation for raw DEFLATE data
