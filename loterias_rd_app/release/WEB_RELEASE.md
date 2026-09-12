# Build Web Release - Sorteos Dominicanos

## Comando recomendado

```bash
./scripts/build_web_release.sh
```

O manualmente:

```bash
flutter clean
flutter pub get
flutter build web --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results
```

## Resultado

La version final queda en:

```bash
build/web
```

Sube el contenido completo de `build/web` a tu hosting.

## Cloudflare Pages

- Build command:

```bash
flutter build web --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results
```

- Output directory:

```bash
build/web
```

## Validacion rapida

Despues del build, abre el sitio y revisa:

- Inicio carga resultados.
- Favoritas funciona.
- Historial filtra por fecha.
- Estadisticas abre desde la barra inferior.
- Calientes, Frios y Veces respetan el periodo seleccionado.
- Ayuda y Acerca de abren sin error.
