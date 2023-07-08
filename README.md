# Smart Community

A **Smart Community** application built with [Flutter](https://flutter.dev) and [PocketBase](https://pocketbase.io).

# How To Build

## Prerequisites

- Flutter 3.10.5
- PocketBase 0.16.5

## Command

```sh
flutter build web --web-renderer canvaskit --no-web-resources-cdn
```

# How To Run

## Prerequisites

- Open PocketBase admin UI and import `scheme.json`

## Command

You can use any framework run the web build, here is a `python` example.

```sh
cd path/to/build
python -m http.server
```

Then open another terminal and run:

```sh
cd path/to/database
pocketbase serve
```
