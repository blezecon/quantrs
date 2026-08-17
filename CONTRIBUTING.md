# Contributing to quantrs

Thanks for checking out quantrs! Contributions are welcome — here's how to get started.

## 1. Fork & Star

- Star the repo if you find it useful — it helps others discover the project.
- Fork the repo to your own GitHub account using the **Fork** button.
- Clone your fork locally:

```bash
git clone https://github.com/<your-username>/quantrs.git
cd quantrs
```

## 2. Build with Docker

No need to install Rust locally — everything runs in Docker.

```bash
docker compose build
```

This builds the image using the multi-stage `Dockerfile` (compiles the Rust binary, then packages it into a slim runtime image).

## 3. Run with Docker

Since quantrs is a TUI app, run it interactively so it has a proper terminal:

```bash
docker compose run --rm app
```

- `--rm` automatically removes the container once you exit — no leftover stopped containers.
- If you're on Podman instead of Docker, swap `docker` for `podman` in the commands above; they work the same way.

## 4. Stop the App

Since we use `run --rm` (not `up`), quantrs isn't running in the background — just exit the TUI normally (e.g. `q` or `Ctrl+C`, depending on the app) and the container stops and removes itself automatically.

If you ever do leave a container running in the background, stop it with:

```bash
docker stop quantrs
```

## 5. Make Your Changes

- Create a new branch for your change:

```bash
git checkout -b my-feature
```

- Edit code, then rebuild to test your changes:

```bash
docker compose build
docker compose run --rm app
```

- Commit and push to your fork, then open a Pull Request against the main repo.

## 6. Clean Up When You're Done

Once you're finished contributing (or just want to free up disk space), remove the Docker resources this project created:

```bash
# Remove the quantrs image
docker rmi quantrs_app

# Or, if you want to clean up everything unused across all Docker projects
# (containers, images, build cache) — not just quantrs:
docker system prune -a
```

`docker system prune -a` is broad — it'll remove unused images/containers from *other* projects too, not just this one. Use it if you're okay with a clean slate; skip it if you've got other Docker projects you don't want touched.

---

That's it! If anything here is unclear or broken, feel free to open an issue.