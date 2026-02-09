# Git Large File Push Fix

## Problem

Git push was failing with HTTP 408 timeout error when trying to push 358.72 MiB of data. The error occurred because large backup files were accidentally committed to the repository.

## Root Cause

Two large backup files were committed in commit `19e39ac`:
- `Backups/RecipeXBackup_2026-02-08_144527_339.reczipes` (511 MB)
- `Backups/BookBackup_2026-02-08_144545_227.bookbackup` (11 MB)

Even though these files were later removed in commit `8354538`, they remained in git history, causing the push to attempt transferring all that data.

The repository had no `.gitignore` file, which allowed these files to be accidentally committed.

## Solution

### 1. Created .gitignore File

Added a comprehensive `.gitignore` to prevent this from happening again:

```gitignore
# Xcode
*.xcuserstate
*.xcworkspace/xcuserdata/
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.swiftpm/
.build/

# Backup files - NEVER commit these!
Backups/
*.reczipes
*.bookbackup

# macOS
.DS_Store
```

### 2. Removed Backup Files from Git History

Used `git filter-branch` to rewrite history and remove the backup files from all commits:

```bash
# Remove Backups directory from history
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force \
  --index-filter 'git rm -r --cached --ignore-unmatch Backups/' \
  --prune-empty --tag-name-filter cat -- 4f0fff5..HEAD

# Clean up backup refs
git for-each-ref --format='%(refname)' refs/original/ | \
  xargs -n 1 git update-ref -d

# Garbage collect to free space
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### 3. Force Pushed Clean History

Since history was rewritten, used force-with-lease to safely push:

```bash
git push origin main --force-with-lease
```

## Results

- ✅ Successfully pushed to remote
- ✅ Repository size reduced significantly
- ✅ Future backup files will be ignored
- ✅ No more timeout errors

## Prevention

The `.gitignore` file now prevents:
1. Backup files (`*.reczipes`, `*.bookbackup`)
2. Backups directory
3. Xcode build artifacts
4. Swift Package Manager build files
5. macOS system files

## Important Notes

1. **Never commit backup files** - They can be hundreds of megabytes and will bloat your repository
2. **Always use .gitignore** - Define what should never be committed before starting work
3. **Check file sizes before committing** - Use `git status` and review what's being added
4. **History rewrites require force push** - Use `--force-with-lease` for safety

## Related Files

- `.gitignore` - Git ignore configuration
- `Backups/` directory - Now ignored by git

## Verification Commands

Check repository size:
```bash
git count-objects -vH
```

Find large files in history:
```bash
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '/^blob/ {print substr($0,6)}' | \
  sort -n -k2 | \
  tail -20
```

Check what will be pushed:
```bash
git log --oneline origin/main..HEAD
```
