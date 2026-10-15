# Laboratorio ACYE1 - Proyecto #2: MiniShell en ARM-64 Puro

## 👥 Datos del Estudiante
* **Nombre:** Yesus Rudy Espinoza Pivaral
* **Carnet:** 201020621
* **Universidad:** Universidad de San Carlos de Guatemala
* **Sección de Laboratorio:** A
* **Auxiliar:** Diego Josue Guevarra

---

## 🎯 1. Decisiones de Diseño de Arquitectura

El proyecto está estructurado como un entorno **REPL (Read-Eval-Print Loop)** implementado en bajo nivel puro. No depende de ninguna biblioteca dinámica de C (`libc`) ni de funciones del sistema estándar. Toda la lógica de interacción con la terminal y la pantalla se procesa mediante interrupciones de software directas al hardware.

### 🏢 Gestión y Preservación del Stack Frame
Cada una de las funciones modulares del sistema cuenta con un preámbulo y epílogo estricto para balancear la pila:
* Se reclaman los bytes necesarios en múltiplos de 16 mediante indexación pre-indexada (`stp x29, x30, [sp, #-16]!`) para resguardar el **Frame Pointer** y el **Link Register (X30)**.
* Al finalizar la subrutina, se devuelven los recursos de forma post-indexada (`ldp x29, x30, [sp], #16`) antes de la ejecución de la instrucción `ret`, evitando desalineaciones del bus.

---

## 🧭 2. Desglose de las Syscalls Empleadas (Linux ARM64)

| No. Syscall | Nombre Técnico | Registro `X8` | Propósito en el MiniShell |
| :---: | :--- | :---: | :--- |
| **63** | `sys_read` | `#63` | Captura los bytes ingresados por el usuario desde el teclado. |
| **64** | `sys_write` | `#64` | Imprime el prompt personalizado y los mensajes ANSI por pantalla. |
| **93** | `sys_exit` | `#93` | Cierra los subprocesos y finaliza el intérprete de comandos de forma limpia. |
| **220** | `sys_fork` | `#220` | Bifurca el proceso del shell para generar un entorno hijo aislado. |
| **221** | `sys_execve` | `#221` | Transforma el proceso hijo reemplazando su imagen por el comando externo. |
| **260** | `sys_wait4` | `#260` | Pausa el proceso padre hasta que el comando externo finalice su ejecución. |

---

## 🛠️ 3. Guía de Compilación y Automatización

Para levantar e interactuar con el entorno del MiniShell en el emulador o sistema nativo, se integra un `Makefile` que automatiza el proceso con las herramientas de GNU Assembler (`as`) y el enlazador estático puro (`ld`):

```bash
# Limpiar el área de trabajo
make clean

# Compilar e incluir los símbolos de depuración (-g)
make

# Ejecutar el MiniShell autónomo
./minishell
```
# proyecto2_201020621
