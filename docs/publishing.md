# Publish to GitHub

This folder is a self-contained Git repository. Create an empty GitHub repository named `platform-engineering-home-lab` (do not initialize it with a README), then run:

```bash
git branch -M main
git add .
git commit -m "Initial platform engineering home lab"
git remote add origin https://github.com/YOUR-USERNAME/platform-engineering-home-lab.git
git push -u origin main
```

After the first push, update the image references in `charts/platform-home-lab/values.yaml` to the GitHub Container Registry names you publish. Enable the commented `publish` job in `.github/workflows/ci.yml` only after confirming the package names and repository package permission settings.

## Portfolio presentation

Pin the repository, add a short demo GIF or screenshots to `docs/evidence/`, and link to the sections on architecture, SLOs, alerting, and runbooks from the README. Keep an honest completed/next roadmap: strong portfolio projects explain both what is implemented and what remains.
