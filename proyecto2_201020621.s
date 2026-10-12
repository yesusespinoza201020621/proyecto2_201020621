.section .data
.align 3
// son mis datos
encabezado1:  .ascii "MiniShell — Interprete de Comandos en ARM-64 \n"
len_enc1 = . - encabezado1

encabezado2:  .ascii "Estudiante: Yesus Rudy Espinoza Pivaral 201020621\n"
len_enc2 = . - encabezado2

encabezado3:  .ascii "Auxiliar: Diego Josue Guevarra - Segundo Semestre 2026\n"
len_enc3 = . - encabezado3

// El prompt personalizado que se mostrará en cada ciclo
prompt:       .ascii "MiniShell_201020621> "
len_prompt = . - prompt

.section .bss
.align 3
// Búfer en la sección .bss para almacenar la entrada del teclado (máximo 100 caracteres)
buffer_entrada: .space 100

.section .text
.global _start

// Main del minishell
_start:
    // 1. Imprimir encabezados de presentación al arrancar
    mov     x0, #1                  // Descriptor: Salida estándar (pantalla)
    ldr     x1, =encabezado1        // Dirección del texto
    mov     x2, #len_enc1           // Longitud del texto
    mov     x8, #64                 // Syscall 64 = sys_write
    svc     #0                      // Invoca al kernel de Linux

    mov     x0, #1
    ldr     x1, =encabezado2
    mov     x2, #len_enc2
    mov     x8, #64
    svc     #0

    mov     x0, #1
    ldr     x1, =encabezado3
    mov     x2, #len_enc3
    mov     x8, #64
    svc     #0

// Bucle principal del intérprete de comandos (REPL: Read-Eval-Print Loop)
shell_loop:
    // 2. Mostrar los mensajes en la pantalla
    mov     x0, #1                  // Destino: Pantalla
    ldr     x1, =prompt             // Dirección de "MiniShell_201020621> "
    mov     x2, #len_prompt         // Cantidad de bytes a escribir
    mov     x8, #64                 // Syscall 64 = sys_write
    svc     #0                      // Imprime por hardware el prompt

    // 3. Leer la entrada del usuario desde el teclado
    mov     x0, #0                  // Descriptor: Entrada estándar (teclado)
    ldr     x1, =buffer_entrada     // Búfer en RAM donde se guardará lo que escribas
    mov     x2, #100                // Capacidad máxima de lectura (100 bytes)
    mov     x8, #63                 // Syscall 63 = sy0s_read en ARM64 Linux
    svc     #0                      // Pausa el programa esperando el "Enter"

    // Nota: El registro X0 ahora contiene la cantidad real de bytes leídos (incluyendo el \n)

    // Aquí irá el llamado a la función modular de Parsing y validación de comandos...

    b       shell_loop              // Ciclo infinito: vuelve a mostrar el prompt

// Aquí se programarán las 5 funciones modulares con su STP/LDP bueno esta en proceso

//para salir reciclando
 mov     x0, #0                   // Código de retorno exitoso
    mov     x8, #93                 // Syscall 93 = sys_exit
    svc     #0                      
