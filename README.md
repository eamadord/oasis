# OASIS · Buscador de Trabajos Fin de Grado de la UPM

OASIS recopila los TFG del Archivo Digital UPM, los guarda en una base de datos y una base vectorial, y permite consultarlos en lenguaje natural desde una página web. Todo el sistema se despliega con Docker Compose.

| Servicio | Función |
| --- | --- |
| `web` | Página de OASIS (Nginx), en `http://localhost:8080` |
| `n8n` | Orquesta la carga de TFGs y el chat; editor en `http://localhost:5678` |
| `pg` | PostgreSQL: registro de TFGs y búsqueda por personas |
| `qdrant` | Base vectorial para la búsqueda por temas |
| `ollama` | Modelo de embeddings `embeddinggemma`, en local (CPU) |
| `qdrant-init`, `ollama-init`, `n8n-init` | Preparan todo la primera vez y terminan |

El modelo de chat (`gpt-oss:120b`) se usa a través de Ollama Cloud.

## Requisitos

- Docker Desktop (Windows o macOS) o Docker Engine con Compose (Linux).
- 8 GB de RAM.
- Una clave de API de Ollama Cloud: [ollama.com/settings/keys](https://ollama.com/settings/keys).

## Instalación

Los comandos son para PowerShell; en Linux o macOS, usa `cp` y tu editor habitual.

1. Abre una terminal en esta carpeta.
2. Crea el archivo de configuración y rellénalo. Usa solo letras y números en contraseñas y claves:
   ```powershell
   Copy-Item .env.example .env
   notepad .env
   ```
3. Si tienes en marcha los contenedores de una instalación manual anterior, páralos para liberar los puertos:
   ```powershell
   docker stop n8n pg qdrant ollama
   ```
4. Arranca OASIS. La primera vez tarda varios minutos, porque descarga las imágenes y el modelo de embeddings:
   ```powershell
   docker compose up -d
   ```
5. Comprueba el estado con `docker compose ps -a`. Los servicios `qdrant-init`, `ollama-init` y `n8n-init` deben aparecer como `Exited (0)`, y el resto como `Up`.

## Primera puesta en marcha

1. Abre `http://localhost:5678` y crea la cuenta de administrador de n8n.
2. Abre el workflow **OASIS · Buscador de TFG UPM**. Las credenciales ya están creadas y asignadas.
3. En el nodo `Config carga`:
   - `escuela`: vacío para toda la UPM, o el código de una escuela.
   - `max_paginas`: páginas de 25 TFGs que se cargan. Con `4` se cargan unos 100 TFGs, en unos 10 minutos.
   - `pagina_inicio`: desde qué página empezar. Sirve para cargar por bloques.
4. Pulsa *Execute* sobre el nodo `Carga inicial (manual)` y espera a que termine.
5. Pulsa **Publish**. Esto activa el chat y la actualización semanal (lunes a las 03:00).
6. Abre `http://localhost:8080`: es OASIS.

Para ampliar la base de datos, sube `max_paginas` y vuelve a ejecutar la carga. Los TFGs que ya están se omiten.

**Logotipo de la UPM:** descarga el oficial de la [página de identidad gráfica de la UPM](https://www.upm.es/UPM/SalaPrensa/IdentidadGrafica) y guárdalo como `web/logo-upm.png`. Mientras no esté, la página muestra el nombre de la universidad en texto.

## Comandos útiles

| Para… | Comando |
| --- | --- |
| Ver el estado | `docker compose ps -a` |
| Ver los mensajes de un servicio | `docker compose logs n8n` (o `n8n-init`, `ollama-init`…) |
| Parar OASIS (conserva los datos) | `docker compose down` |
| Volver a arrancarlo | `docker compose up -d` |
| Contar TFGs en Postgres | `docker compose exec pg psql -U tfg -d tfgs -c "SELECT count(*) FROM tfg;"` |
| Contar vectores en Qdrant | `(Invoke-RestMethod http://localhost:6333/collections/tfgs_gemma_atribustosESP).result.points_count` |
| **Borrarlo todo**, incluidos los datos | `docker compose down -v` |

## Cosas que conviene saber

- **La configuración se aplica solo la primera vez.** La contraseña de Postgres y la clave de Ollama Cloud del `.env` se usan al crear la base de datos y al importar las credenciales. Si después cambias la clave de Ollama, cámbiala también en n8n (*Overview → Credentials → Ollama Cloud*).
- **No pierdas `N8N_ENCRYPTION_KEY`.** Con ella se cifran las credenciales; si cambia, n8n no podrá leerlas.
- **El editor de n8n solo es accesible desde el propio equipo** (`127.0.0.1:5678`). En un servidor, entra con un túnel: `ssh -L 5678:localhost:5678 usuario@servidor`.
- **Después de cambiar algo en el workflow, vuelve a publicarlo.** La página usa siempre la última versión publicada.

## Despliegue en un dominio de la UPM

1. En `.env`, pon `PUBLIC_URL=https://tu-subdominio.upm.es/`.
2. Pide a los Servicios Informáticos que publiquen con HTTPS el puerto `WEB_PORT` del servidor en ese subdominio. El proxy debe reenviar las cabeceras `X-Forwarded-For` y `X-Forwarded-Proto`.
3. Aplica el cambio con `docker compose up -d`.

## Si algo falla

- **`n8n-init` termina con error:** revisa `docker compose logs n8n-init`. Si la importación de credenciales falla, créalas a mano en n8n con estos nombres exactos y asígnalas a los nodos:

  | Nombre | Tipo | Configuración |
  | --- | --- | --- |
  | Postgres TFG | Postgres | Host `pg`, puerto `5432`, base, usuario y contraseña del `.env`, SSL `disable` |
  | Qdrant TFG | Qdrant API | URL `http://qdrant:6333` |
  | Ollama Cloud | Ollama | Base URL `https://ollama.com`, API Key del `.env` |
  | Ollama Embeddings (local) | Ollama | Base URL `http://ollama:11434` |

- **El chat responde que no encuentra nada:** comprueba que Postgres y Qdrant tienen datos (ver *Comandos útiles*). Qdrant debe tener igual o más vectores que TFGs en Postgres.
- **Para cualquier otro error,** consulta la tabla de problemas frecuentes de la guía de despliegue.

## Agradecimientos
El trabajo realizado ha sido posible gracias a la I Convocatoria de ayudas para el desarrollo y despliegue de pilotos de IA para el apoyo docente de la Universidad Politécnica de Madrid. Además, este sistema no hubiera sido posible sin el magnífico trabajo previo realizado por los estudiantes Sergio Delgado González y Hugo Blanco Iraola en sus respectivos Trabajos de Fin de Grado. Gracias, chicos, por el trabajo tan increíble que habéis hecho.