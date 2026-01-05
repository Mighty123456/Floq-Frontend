# How to Fix Git Authentication Issues (403 Permission Denied)

## Problem
When you see: `Permission denied to USERNAME/REPO.git denied to DIFFERENT_USERNAME`
This means you're logged in as a different GitHub account than the repository owner.

## Solution: Change Remote URL and Authenticate

### Method 1: Change Remote to Your Own Repository

If you want to push to YOUR repository instead:

```powershell
# 1. Remove current remote
git remote remove origin

# 2. Add your repository
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 3. Push
git push -u origin main
```

### Method 2: Use Personal Access Token (For Mighty123456 repo)

If you own the `Mighty123456` account:

**Step 1: Create Personal Access Token**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "Git Push"
4. Select scope: `repo`
5. Generate and **copy the token**

**Step 2: Update Remote with Token**

```powershell
# Option A: Embed token in URL (most secure)
git remote set-url origin https://YOUR_TOKEN@github.com/Mighty123456/Bubble-Chat-Backend.git
git push -u origin main
```

```powershell
# Option B: Use username, enter token when prompted
git remote set-url origin https://Mighty123456@github.com/Mighty123456/Bubble-Chat-Backend.git
git push -u origin main
# When prompted for password, paste your token
```

### Method 3: Clear Credentials and Re-authenticate

**Step 1: Clear Windows Credentials**

```powershell
# Open Credential Manager
control /name Microsoft.CredentialManager
```

Then:
- Go to "Windows Credentials"
- Find `git:https://github.com`
- Click "Remove" on all GitHub entries

**Or use command line:**
```powershell
git credential-manager-core erase
# Type: https://github.com
# Press Enter twice
```

**Step 2: Push Again (will prompt for login)**
```powershell
git push -u origin main
# Enter: Mighty123456 username
# Enter: Your Personal Access Token as password
```

### Method 4: Use SSH Instead of HTTPS

**Step 1: Check if you have SSH keys**
```powershell
ssh -T git@github.com
```

**Step 2: If connected, change remote to SSH**
```powershell
git remote set-url origin git@github.com:Mighty123456/Bubble-Chat-Backend.git
git push -u origin main
```

## Quick Reference Commands

### Change Remote URL
```powershell
# Remove current remote
git remote remove origin

# Add new remote (HTTPS)
git remote add origin https://github.com/USERNAME/REPO.git

# Add new remote (SSH)
git remote add origin git@github.com:USERNAME/REPO.git

# Update existing remote
git remote set-url origin https://github.com/USERNAME/REPO.git
```

### View Current Remote
```powershell
git remote -v
```

### Clear Credentials
```powershell
# Method 1: Credential Manager GUI
control /name Microsoft.CredentialManager

# Method 2: Command line
git credential-manager-core erase
```

## Common Scenarios

### Scenario 1: Wrong Account Logged In
**Problem:** Authenticated as `stargym0205-ux` but need `Mighty123456`

**Solution:**
```powershell
# Clear credentials
git credential-manager-core erase
# Type: https://github.com, press Enter twice

# Update remote with username
git remote set-url origin https://Mighty123456@github.com/Mighty123456/Bubble-Chat-Backend.git

# Push (will prompt for Mighty123456 credentials)
git push -u origin main
```

### Scenario 2: Want to Use Different Repository
**Problem:** Want to push to your own repo instead

**Solution:**
```powershell
# Change remote
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Scenario 3: Using Personal Access Token
**Problem:** Password authentication disabled, need token

**Solution:**
```powershell
# Get token from: https://github.com/settings/tokens
# Then:
git remote set-url origin https://YOUR_TOKEN@github.com/Mighty123456/Bubble-Chat-Backend.git
git push -u origin main
```

## Prevention Tips

1. **Always use Personal Access Tokens** instead of passwords
2. **Use SSH keys** for better security
3. **Check your remote** before pushing: `git remote -v`
4. **Verify authentication**: `ssh -T git@github.com` (for SSH)

## Your Current Situation

- **Repository:** https://github.com/Mighty123456/Bubble-Chat-Backend.git
- **Authenticated as:** stargym0205-ux (wrong account)
- **Need:** Authenticate as Mighty123456

**Quick Fix:**
1. Create Personal Access Token for Mighty123456 account
2. Run: `git remote set-url origin https://Mighty123456@github.com/Mighty123456/Bubble-Chat-Backend.git`
3. Run: `git push -u origin main`
4. Enter token as password when prompted

