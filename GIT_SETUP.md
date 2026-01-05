# Git Setup Guide - Fixing Permission Issues

## Problem
You're trying to push to `Mighty123456/Bubble-Chat-Backend.git` but authenticated as `stargym0205-ux` which doesn't have permission.

## Solutions

### Option 1: Change Remote to Your Own Repository (Recommended)

1. **Remove current remote:**
   ```powershell
   git remote remove origin
   ```

2. **Add your own repository:**
   ```powershell
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   ```
   Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub username and desired repository name.

3. **Or if you want to create a new repository:**
   - Go to GitHub and create a new repository
   - Then use the commands above with your new repository URL

### Option 2: Use SSH Instead of HTTPS

1. **Remove current remote:**
   ```powershell
   git remote remove origin
   ```

2. **Add SSH remote:**
   ```powershell
   git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git
   ```

3. **Make sure you have SSH keys set up:**
   - Check: `ssh -T git@github.com`
   - If not set up, follow: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### Option 3: Update HTTPS Credentials

1. **Update remote URL with your username:**
   ```powershell
   git remote set-url origin https://YOUR_USERNAME@github.com/Mighty123456/Bubble-Chat-Backend.git
   ```

2. **Or use GitHub Personal Access Token:**
   - Create token: https://github.com/settings/tokens
   - Use: `https://YOUR_TOKEN@github.com/Mighty123456/Bubble-Chat-Backend.git`

### Option 4: Get Access to the Repository

If you need access to `Mighty123456/Bubble-Chat-Backend`:
- Ask the repository owner (`Mighty123456`) to add you as a collaborator
- Or fork the repository to your account

## Complete Setup Steps (Recommended)

```powershell
# 1. Remove current remote
git remote remove origin

# 2. Add all files
git add .

# 3. Commit
git commit -m "Initial commit: WhatsApp-like chat application"

# 4. Create a new repository on GitHub first, then:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 5. Push
git push -u origin main
```

## Current Git Configuration
- Username: Ansh13032005
- Email: anshparikh.1305@gmail.com

You can use a repository under this account or create a new one.

