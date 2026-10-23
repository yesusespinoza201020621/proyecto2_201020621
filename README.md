# Laboratorio ACYE1 - Proyecto No. 2: MiniShell en ARM-64 Puro

## 👥 Información General
* **Estudiante:** Yesus Rudy Espinoza Pivaral
* **Carnet:** 201020621
* **Universidad:** Universidad de San Carlos de Guatemala
* **Facultad:** Ingeniería
* **Escuela:** Ciencias y Sistemas
* **Curso:** Arquitectura de Computadores y Ensambladores 1
* **Auxiliar:** Diego Josue Guevarra
* **Semestre:** Segundo Semestre 2026

---

## 🎯 1. Marco Formativo y Competencias Desarrolladas

### 🤝 Excelencia Académica Aplicada
En cumplimiento con el marco formativo del laboratorio, este proyecto se diseñó de forma autónoma y con un control estricto de los recursos de hardware. Se logró dominar el funcionamiento interno del sistema operativo interactuando directamente con el Kernel de Linux a través de llamadas al sistema (syscalls) nativas de 64 bits, escribiendo código ensamblador modular, limpio y altamente documentado.

### 🧠 Conceptos de los Capítulos 1 al 5 Aplicados
1. **Manejo de Datos de 1 Byte (Capítulo 2):** El análisis de texto se procesa carácter por carácter utilizando instrucciones de carga de bytes (`ldrb`) sobre registros `W` de 32 bits, respetando la estructura de la tabla ASCII.
2. **Direccionamiento Escalado por Registro (Capítulo 3):** Para almacenar las direcciones de los argumentos dentro de la tabla `argv`, se aplica direccionamiento indexado con desplazamiento lógico a la izquierda de 3 bits (`LSL #3`), multiplicando el índice de forma inmediata por 8 debido al tamaño de los punteros de 64 bits.
3. **Estructuras de Decisión (Capítulo 4):** Las bifurcaciones condicionales y comparaciones de cadenas simulan estructuras de alto nivel evaluando directamente el estado de las banderas de condición (`N`, `Z`, `C`, `V`) en el estado del procesador (`PSTATE`).
4. **Preservación del Stack Frame (Capítulo 5):** Cada una de las subrutinas modularizadas salvaguarda el contexto de ejecución respetando la convención formal de llamadas de ARM64 (AAPCS), utilizando emparejamientos pre-indexados y post-indexados (`stp` / `ldp`) para proteger el Link Register (`X30`).

---

## 🧭 2. Justificación Técnica de las Syscalls Empleadas

El núcleo del MiniShell interactúa de forma directa con los servicios del sistema operativo mediante interrupciones de software (`svc #0`), eliminando cualquier dependencia de bibliotecas estándar de C:

* **`sys_read` (Syscall 63):** Captura los bytes provenientes de la entrada estándar (`stdin`) depositándolos de forma segura en un búfer estático de la sección `.bss`.
* **`sys_write` (Syscall 64):** Envía flujos de caracteres a la salida estándar (`stdout`) para renderizar el prompt interactivo y las secuencias de escape ANSI por hardware.
* **`sys_exit` (Syscall 93):** Devuelve el control del hilo de ejecución de forma segura al kernel de Linux al invocar el comando interno `exit`.
* **`sys_clone` (Syscall 220):** Bifurca el proceso actual pasando el flag `#17` (`SIGCHLD`) para generar un proceso hijo controlado.
* **`sys_execve` (Syscall 221):** Muta la imagen de memoria del proceso hijo para cargar y ejecutar comandos del sistema (como `/bin/ls`) utilizando el vector `argv` generado por el tokenizador.
* **`sys_wait4` (Syscall 260):** Sincroniza los hilos pausando al proceso padre hasta que el hijo termine de ejecutarse, evitando la corrupción visual del prompt.

---

## 🛠️ 3. Guía de Compilación y Ejecución

Para levantar el intérprete de comandos de forma limpia en cualquier entorno emulado o nativo Linux ARM64, ejecute los siguientes comandos en su terminal:

```bash
# Limpiar binarios previos
make clean

# Compilar el proyecto completo
make

# Ejecutar el MiniShell interactivo
./proyecto2_201020621
```
