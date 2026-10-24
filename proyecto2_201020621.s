.data
.align 3
// practicamente son mis datos 
encabezado1:  .ascii "MiniShell — Interprete de Comandos en ARM-64 Puro\n"
len_enc1 = . - encabezado1

encabezado2:  .ascii "Estudiante: Yesus Rudy Espinoza Pivaral 201020621\n"
len_enc2 = . - encabezado2

encabezado3:  .ascii "Auxiliar: Diego Josue Guevarra - Segundo Semestre 2026\n\n"
len_enc3 = . - encabezado3

prompt:       .ascii "MiniShell_201020621> "
len_prompt = . - prompt

// Cadenas propias del sistema toma en cuenta la primer lectura de la palabra puedo poner echo echo sin problemas
name_help:    .asciz "help"
name_clear:   .asciz "clear"
name_echo:    .asciz "echo"
name_exit:    .asciz "exit"

help_text:    .asciz "funciones Internas disponibles la quinta es la de los errores:\n help\n echo\n clear\n exit\n"
clear_text:   .asciz "\033[2J\033[H"
unknown_text: .asciz "Comando desconocido: "
space:        .asciz " "
newline:      .asciz "\n"
limite_de_mi_error:  .asciz "Error: maximo 16 argumentos\n"
path_bin:     .asciz "/bin/"

.section .bss
.balign 8
// Variables y estructuras estáticas de las plantillas del auxiliar
buffer_entrada:   .skip 100
path_ejecutable:  .skip 120
argv:             .skip 136         // 16 punteros de argumentos + NULL final
digits:           .skip 2           // Para impresión de números de 0 a 16
child_status:     .skip 4           // Para capturar estado del hijo en wait4

.section .text
.global _start

// el main del sistema

_start:
    // 1. Mostrar encabezados institucionales de la USAC al iniciar
    ldr     x1, =encabezado1
    mov     x2, len_enc1
    bl      print_fixed_len

    ldr     x1, =encabezado2
    mov     x2, len_enc2
    bl      print_fixed_len

    ldr     x1, =encabezado3
    mov     x2, len_enc3
    bl      print_fixed_len

// Bucle interactivo REPL (Read-Eval-Print Loop)
shell_loop:
    // 2. Pintar el prompt interactivo por hardware
    ldr     x1, =prompt
    mov     x2, len_prompt
    bl      print_fixed_len

    // 3. Capturar la entrada del teclado con la syscall read (Syscall 63)
    mov     x0, #0                  // stdin
    ldr     x1, =buffer_entrada     // Destino
    mov     x2, #100                // Límite de bytes
    mov     x8, #63                 // sys_read
    svc     #0                      

    // Validación de buffer vacío o entrada nula
    cmp     x0, #1
    b.le    shell_loop

    // 4. FUNCIÓN MODULAR 1: Quitar el salto de línea '\n' antes del parsing
    ldr     x0, =buffer_entrada
    bl      quitar_nueva_linea

    // 5. FUNCIÓN MODULAR 2 (PLANTILLA AUXILIAR): Tokenizador parse_line
    ldr     x0, =buffer_entrada
    ldr     x1, =argv
    mov     x2, #16                 // Máximo 16 argumentos permitidos
    bl      parse_line              // X0 retorna el conteo de argumentos (argc)
    
    cmp     x0, #0
    b.lt    .L_too_many_args        // Si retorna -1, excedió el límite

    // 6. FUNCIÓN MODULAR 3 (PLANTILLA AUXILIAR): Despachador centralizado
    ldr     x0, =argv
    bl      dispatch                // Evalúa si es comando interno o externo
    b       shell_loop

.L_too_many_args:
    ldr     x1, =limite_de_mi_error
    bl      print_z
    b       shell_loop

// implementación de las funciones auxiliares que vamos a usar


// SUBRUTINA: PARSE_LINE (MÓDULO DE PARSING EXIGIDO - SOURCE 8)
parse_line:
    mov     x3, x0                  // Posición actual del buffer
    mov     x4, #0                  // Cantidad de argumentos (argc)
    mov     x5, x1                  // Siguiente posición de la tabla argv

skip_separators:
    ldrb    w6, [x3]
    cbz     w6, parse_done
    cmp     w6, #' '
    b.eq    erase_separator
    cmp     w6, #9                  // Tabulación \t
    b.eq    erase_separator

    cmp     x4, x2                  // Valida límite de desbordamiento
    b.ge    parse_overflow          
    str     x3, [x5]                // Almacena dirección del token actual en argv
    add     x5, x5, #8
    add     x4, x4, #1

scan_word:
    ldrb    w6, [x3]
    cbz     w6, parse_done
    cmp     w6, #' '
    b.eq    erase_separator
    cmp     w6, #9
    b.eq    erase_separator
    add     x3, x3, #1
    b       scan_word

erase_separator:
    strb    wzr, [x3]               // Reemplaza separador por NUL por hardware
    add     x3, x3, #1
    b       skip_separators

parse_done:
    str     xzr, [x5]               // Cierra el arreglo argv con NULL
    mov     x0, x4                  // Retorna argc
    ret

parse_overflow:
    str     xzr, [x5]               // Cierra seguro en NULL
    mov     x0, #-1                 // Código de error por exceso de argumentos
    ret

// SUBRUTINA: DISPATCH (DESPACHADOR MODULAR - SOURCE 9)
dispatch:
    stp     x19, x30, [sp, #-16]!   // Resguarda el marco de la pila
    mov     x19, x0
    ldr     x0, [x19]               // Carga el nombre del comando (argv[0])
    cbz     x0, dispatch_done       // Si es nulo, aborta

    // Comparación secuencial contra los 4 Built-ins requeridos
    ldr     x1, =name_help
    bl      string_equal
    cbnz    x0, do_help

    ldr     x0, [x19]
    ldr     x1, =name_echo
    bl      string_equal
    cbnz    x0, do_echo

    ldr     x0, [x19]
    ldr     x1, =name_clear
    bl      string_equal
    cbnz    x0, do_clear

    ldr     x0, [x19]
    ldr     x1, =name_exit
    bl      string_equal
    cbnz    x0, do_exit

    // Si no fue comando interno, se procesa dinámicamente como externo (SOURCE 10)
    b       ejecutar_comando_externo

do_help:
    bl      builtin_help
    b       dispatch_success
do_echo:
    mov     x0, x19                 // Pasa la tabla completa de argv a echo
    bl      builtin_echo
    b       dispatch_success
do_clear:
    bl      builtin_clear
    b       dispatch_success
do_exit:
    bl      builtin_exit

dispatch_success:
    mov     x0, #1
dispatch_done:
    ldp     x19, x30, [sp], #16
    ret

// subturina para comparar los texto
string_equal:
compare_byte:
    ldrb    w2, [x0]
    ldrb    w3, [x1]
    cmp     w2, w3
    b.ne    unequal
    cbz     w2, equal               // Ambas cadenas finalizaron simultáneamente en NUL
    add     x0, x0, #1
    add     x1, x1, #1
    b       compare_byte
equal:
    mov     x0, #1                  // Retorna 1 (Verdadero)
    ret
unequal:
    mov     x0, #0                  // Retorna 0 (Falso)
    ret


// sección de los comandos internos (BUILT-INS OFICIALES)

builtin_help:
    ldr     x1, =help_text
    b       print_z

builtin_clear:
    ldr     x1, =clear_text
    b       print_z

builtin_echo:
    stp     x19, x30, [sp, #-16]!
    add     x19, x0, #8             // Desplaza el puntero para iniciar en argv[1]
echo_word:
    ldr     x1, [x19]
    cbz     x1, echo_newline        // Fin de la tabla detectado por puntero NULL
    bl      print_z
    add     x19, x19, #8            // Siguiente casilla del vector de punteros
    ldr     x0, [x19]
    cbz     x0, echo_newline
    ldr     x1, =space
    bl      print_z
    b       echo_word
echo_newline:
    ldr     x1, =newline
    bl      print_z
    ldp     x19, x30, [sp], #16
    ret

builtin_exit:
    mov     x0, #0
    mov     x8, #93                 // Syscall 93 = sys_exit
    svc     #0

// gestion dinamica para la parte de los procesos externos (COMBINACIÓN CLONE + EXECVE - SOURCE 10)

ejecutar_comando_externo:
    stp     x19, x30, [sp, #-16]!
    
    // Construimos dinámicamente la ruta absoluta concatenando "/bin/" + argv[0]
    ldr     x0, =path_bin
    ldr     x1, [x19]               // Nombre del comando (ej: "ls")
    ldr     x2, =path_ejecutable
    bl      concatenar_ruta

    // Invocación formal de sys_clone con la firma exacta del auxiliar (Syscall 220)
    mov     x0, #17                 // SIGCHLD mandatorio para notificar al padre
    mov     x1, #0                  // Utiliza el segmento de pila actual en el hijo
    mov     x2, #0                  
    mov     x3, #0                  
    mov     x4, #0                  
    mov     x8, #220                // sys_clone
    svc     #0
    
    cmp     x0, #0
    b.lt    .L_error_externo        // Error si el retorno es negativo
    cbz     x0, .L_entorno_hijo     // Si es cero, la CPU está procesando en el hijo

// Proceso Padre: Espera obligatoria estructurada wait4 (Source 10)
    mov     x19, x0                 // Almacena el PID del proceso hijo generado
.L_wait_child_loop:
    mov     x0, x19
    ldr     x1, =child_status       // Dirección del estado de retorno en .bss
    mov     x2, #0                  
    mov     x3, #0                  
    mov     x8, #260                // Syscall 260 = wait4
    svc     #0
    cmp     x0, #-4                 // Comprobación EINTR: repetir la espera si fue interrumpido
    b.eq    .L_wait_child_loop
    b       .L_externo_exito

.L_entorno_hijo:
    // Ajustamos la primera celda de la tabla de argumentos con la ruta absoluta generada
    ldr     x1, =argv
    ldr     x0, =path_ejecutable
    str     x0, [x1]                // argv[0] = "/bin/ls" o la ruta calculada

    // Invocación de la syscall execve (Syscall 221)
    ldr     x0, =path_ejecutable    // Parámetro 1: Dirección del binario

ldr     x1, =argv               // Parámetro 2: Tabla de argumentos completa con flags
mov     x2, #0                  // Parámetro 3: Entorno vacío terminado en NULL
mov     x8, #221                // sys_execve
svc     #0
.L_error_externo:
// Si la resolución del binario falla, imprime la excepción controlada de la rúbrica
ldr     x1, =unknown_text
bl      print_z
ldr     x1, [x19]
bl      print_z
ldr     x1, =newline
bl      print_z
.L_externo_exito:
ldp     x19, x30, [sp], #16
ret
// subrutinas de impresión y utilería para el proyecto

quitar_nueva_linea:
mov     x1, x0
.L_nl_loop:
ldrb    w2, [x1]
cbz     w2, .L_nl_end
cmp     w2, #10                 // Busca carácter \n
b.eq    .L_nl_replace
add     x1, x1, #1
b       .L_nl_loop
.L_nl_replace:
strb    wzr, [x1]               // Reemplaza por fin de cadena
.L_nl_end:
ret
concatenar_ruta:
.L_copy_p1:
ldrb    w3, [x0], #1
cbz     w3, .L_copy_p2
strb    w3, [x2], #1
b       .L_copy_p1
.L_copy_p2:
ldrb    w3, [x1], #1
strb    w3, [x2], #1
cbnz    w3, .L_copy_p2
ret
print_fixed_len:
mov     x0, #1                  // stdout
mov     x8, #64                 // sys_write
svc     #0
ret
print_z:
mov     x2, #0
mov     x3, x1
count_bytes:
ldrb    w4, [x3]
cbz     w4, write_text
add     x3, x3, #1
add     x2, x2, #1
b       count_bytes
write_text:
mov     x0, #1
mov     x8, #64                 // sys_write
svc     #0
ret
