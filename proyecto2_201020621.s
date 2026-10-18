.data
.align 3
// Datos de identificación del estudiante (USAC)
encabezado1:  .ascii "MiniShell — Interprete de Comandos en ARM-64 Puro\n"
len_enc1 = . - encabezado1

encabezado2:  .ascii "Estudiante: Yesus Rudy Espinoza Pivaral 201020621\n"
len_enc2 = . - encabezado2

encabezado3:  .ascii "Auxiliar: Diego Josue Guevarra - Segundo Semestre 2026\n\n"
len_enc3 = . - encabezado3

// El prompt personalizado que se mostrará en cada ciclo
prompt:       .ascii "MiniShell_201020621> "
len_prompt = . - prompt
//ls0-a
//caracter nulo

e// Mensaje de ayuda para el comando 'help'
msg_help:     .ascii "\n--- comandar internos en minishell ---\n"
              .ascii "  help  : Muestra esta guia de usuario.\n"
              .ascii "  clear : Limpia el entorno de la terminal.\n"
              .ascii "  echo  : Repite el texto enviado como argumento.\n"
              .ascii "  exit  : Cierra el interprete de comandos.\n\n"
len_help = . - msg_help

// Mensaje de error para comandos desconocidos (Requisito de rúbrica)
msg_error:    .ascii "MiniShell Error: Comando o programa externo no encontrado.\n"
len_error = . - msg_error

// Secuencia de escape ANSI para limpiar pantalla y resetear cursor
clear_ansi:   .ascii "\033[H\033[J"
len_ansi = . - clear_ansi

msg_newline:  .ascii "\n"

// Cadenas de comparación constantes para los comandos Built-in
cmd_exit:     .asciz "exit"
cmd_clear:    .asciz "clear"
cmd_help:     .asciz "help"
cmd_echo:     .asciz "echo"

// Cadenas limpias para validar comandos externos
ext_ls:       .asciz "ls"
ext_pwd:      .asciz "pwd"
ext_date:     .asciz "date"

// Rutas absolutas binarias requeridas para la syscall execve
path_ls:      .asciz "/bin/ls"
path_pwd:     .asciz "/bin/pwd"
path_date:    .asciz "/bin/date"

.bss
.align 3
// Búfer seguro para la entrada de datos
buffer_entrada: .space 100

// Arreglos de punteros requeridos como argumentos para la syscall execve
.align 3
args_vector:    .space 16       // Tabla de argumentos (Puntero al comando, puntero a NULL)
env_vector:     .space 8        // Tabla de entorno vacía (Terminada en NULL)

.text
.global _start


//main para el minishell

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

// Bucle principal del intérprete de comandos (REPL)
shell_loop:
    // 2. Mostrar el prompt personalizado en la pantalla
    mov     x0, #1                  
    ldr     x1, =prompt             
    mov     x2, #len_prompt         
    mov     x8, #64                 // Syscall 64 = sys_write
    svc     #0                      

    // 3. Leer la entrada del usuario desde el teclado (Syscall 63)
    mov     x0, #0                  // Descriptor: Entrada estándar (teclado)
    ldr     x1, =buffer_entrada     // Búfer en RAM seguro
    mov     x2, #100                // Capacidad máxima de lectura (100 bytes)
    mov     x8, #63                 // Syscall 63 = sys_read
    svc     #0                      // El procesador se detiene aquí esperando "Enter"

    // Guardamos la cantidad de bytes leídos devueltos en X0
    mov     x19, x0                 

    // Validación de seguridad: si no escribió nada (solo dio Enter), vuelve al prompt
    cmp     x19, #1
    b.le    shell_loop

    // 4. FUNCIÓN MODULAR 1: Limpiar el carácter de nueva línea '\n'
    ldr     x0, =buffer_entrada     // Parámetro 1: Dirección base del búfer
    bl      quitar_nueva_linea      // Llama a tu función modular

    // 5. EVALUACIÓN DE COMANDO INTERNO: 'exit'
    ldr     x0, =buffer_entrada     
    ldr     x1, =cmd_exit           
    bl      comparar_cadenas        // FUNCIÓN MODULAR 2: strcmp puro
    cmp     x0, #0
    b.eq    ejecutar_salir          

    // 6. EVALUACIÓN DE COMANDO INTERNO: 'clear'
    ldr     x0, =buffer_entrada     
    ldr     x1, =cmd_clear          
    bl      comparar_cadenas        
    cmp     x0, #0
    b.eq    ejecutar_clear          

    // 7. EVALUACIÓN DE COMANDO INTERNO: 'help'
    ldr     x0, =buffer_entrada     
    ldr     x1, =cmd_help           
    bl      comparar_cadenas        
    cmp     x0, #0
    b.eq    ejecutar_help           

    // 8. EVALUACIÓN DE COMANDO INTERNO COMPUESTO: 'echo [argumento]'
    ldr     x0, =buffer_entrada     
    ldr     x1, =cmd_echo           
    bl      ejecutar_echo_built_in  
    cmp     x0, #0
    b.eq    shell_loop              // Si fue ejecutado de forma interna, reitera ciclo

    
    // GESTIÓN DE PROGRAMAS EXTERNOS CORREGIDA (ls, pwd, date)
   
    ldr     x0, =buffer_entrada
    ldr     x1, =ext_ls
    bl      comparar_cadenas
    cmp     x0, #0
    b.eq    .L_launch_ls

    ldr     x0, =buffer_entrada
    ldr     x1, =ext_pwd
    bl      comparar_cadenas
    cmp     x0, #0
    b.eq    .L_launch_pwd

    ldr     x0, =buffer_entrada
    ldr     x1, =ext_date
    bl      comparar_cadenas
    cmp     x0, #0
    b.eq    .L_launch_date

    // Si no fue ningún comando interno ni externo válido, muestra error
    mov     x0, #1
    ldr     x1, =msg_error
    mov     x2, #len_error
    mov     x8, #64
    svc     #0
    b       shell_loop

.L_launch_ls:
    ldr     x20, =path_ls
    b       .L_execute_fork

.L_launch_pwd:
    ldr     x20, =path_pwd
    b       .L_execute_fork

.L_launch_date:
    ldr     x20, =path_date

.L_execute_fork:
    // Invocamos sys_fork (Syscall 220) para bifurcar el sistema operativo
    mov     x8, #220                // Syscall 220 = fork
    svc     #0
    
    // El kernel devuelve el PID del hijo en X0
    cmp     x0, #0
    b.eq    .L_proceso_hijo         // Si X0 == 0, somos el proceso hijo; va a ejecutar
    
    // Si X0 > 0, somos el proceso padre. Debemos esperar a que el hijo termine (wait4)
    mov     x1, #0                  // Status NULL
    mov     x2, #0                  // Options 0
    mov     x3, #0                  // Rusage NULL
    mov     x8, #260                // Syscall 260 = wait4
    svc     #0
    b       shell_loop              // Cuando el hijo termina, el padre vuelve al bucle

.L_proceso_hijo:
    // Configuramos los vectores de argumentos requeridos por execve en la sección .bss
    ldr     x1, =args_vector
    str     x20, [x1]               // args_vector[0] = Dirección de la ruta absoluta (/bin/ls)
    mov     x2, #0
    str     x2, [x1, #8]            // args_vector[1] = NULL (Fin obligatorio del arreglo)

    ldr     x2, =env_vector
    str     x2, [x2]                // env_vector[0] = NULL (Entorno vacío sin variables)

    // Invocamos sys_execve (Syscall 221) para transformar al hijo en el programa externo
    mov     x0, x20                 // Parámetro 1: Dirección de la ruta binaria
    ldr     x1, =args_vector        // Parámetro 2: Arreglo de argumentos
    ldr     x2, =env_vector         // Parámetro 3: Arreglo de entorno
    mov     x8, #221                // Syscall 221 = execve
    svc     #0                      // Transforma el proceso
    
    // Si execve llegara a fallar por permisos, cierra el hijo de forma segura
    mov     x0, #1
    mov     x8, #93
    svc     #0

ejecutar_salir:
    mov     x0, #0                   
    mov     x8, #93                 
    svc     #0                      

ejecutar_clear:
    bl      cmd_internal_clear      
    b       shell_loop

ejecutar_help:
    bl      cmd_internal_help       
    b       shell_loop

// =============================================================================
// FUNCIÓN MODULAR 1: QUITAR NUEVA LÍNEA ('\n') EN LA RAM
// =============================================================================
quitar_nueva_linea:
    stp     x29, x30, [sp, #-16]!   
    mov     x29, sp

.L_find_nl_loop:
    ldrb    w2, [x0]                
    cmp     w2, #10                 
    b.eq    .L_replace_nl           
    cmp     w2, #0                  
    b.eq    .L_end_nl               
    add     x0, x0, #1              
    b       .L_find_nl_loop

.L_replace_nl:
    mov     w2, #0                  
    strb    w2, [x0]                

.L_end_nl:
    ldp     x29, x30, [sp], #16     
    ret

// =============================================================================
// FUNCIÓN MODULAR 2: STRCMP EN BAJO NIVEL PURO
// =============================================================================
comparar_cadenas:
    stp     x29, x30, [sp, #-16]!   
    mov     x29, sp

.L_strcmp_loop:
    ldrb    w2, [x0], #1            
    ldrb    w3, [x1], #1            
    
    cmp     w2, w3                  
    b.ne    .L_strcmp_diff          

    cmp     w2, #0                  
    b.eq    .L_strcmp_equal         

    b       .L_strcmp_loop          

.L_strcmp_diff:
    mov     x0, #1                  
    b       .L_strcmp_end

.L_strcmp_equal:
    mov     x0, #0                  

.L_strcmp_end:
    ldp     x29, x30, [sp], #16     
    ret

// =============================================================================
// FUNCIÓN MODULAR 3: COMANDO INTERNO CLEAR (ANSI DRIVER)
// =============================================================================
cmd_internal_clear:
    stp     x29, x30, [sp, #-16]!   

mov     x29, sp
mov     x0, #1                  // Destino: Pantalla
ldr     x1, =clear_ansi         // Cadena de escape para limpiar terminal
mov     x2, #len_ansi           // Cantidad de bytes
mov     x8, #64                 // Syscall 64 = sys_write
svc     #0                      // Ejecuta la limpieza por hardware
ldp     x29, x30, [sp], #16     // Restaura Stack Frame
ret

// =============================================================================
// FUNCIÓN MODULAR 4: COMANDO INTERNO HELP (MANUAL REQUERIDO)
// =============================================================================
cmd_internal_help:
stp     x29, x30, [sp, #-16]!   // Guarda FP y LR en el Stack
mov     x29, sp
mov     x0, #1                  // Destino: Pantalla
ldr     x1, =msg_help           // Carga la lista de comandos válidos
mov     x2, #len_help           // Longitud del mensaje
mov     x8, #64                 // Syscall 64 = sys_write
svc     #0                      // Imprime la ayuda por hardware
ldp     x29, x30, [sp], #16     // Restaura Stack Frame
ret

// =============================================================================
// FUNCIÓN MODULAR 5: COMANDO INTERNO ECHO CON PARSING DE ARGUMENTOS
// =============================================================================
ejecutar_echo_built_in:
stp     x29, x30, [sp, #-32]!   // Reserva espacio en la pila
mov     x29, sp
str     x19, [sp, #16]          // Resguarda registro de trabajo
mov     x19, x0                 // X19 = Dirección del búfer ingresado
// Comparamos los primeros 4 bytes para ver si inicia con la palabra "echo"
ldrb    w2, [x0], #1
cmp     w2, #'e'
b.ne    .L_echo_fail
ldrb    w2, [x0], #1
cmp     w2, #'c'
b.ne    .L_echo_fail
ldrb    w2, [x0], #1
cmp     w2, #'h'
b.ne    .L_echo_fail
ldrb    w2, [x0], #1
cmp     w2, #'o'
b.ne    .L_echo_fail
// Verificamos si lo que sigue es un espacio o el final de la cadena
ldrb    w2, [x0]
cmp     w2, #' '                // Si hay un espacio, saltamos a imprimir el argumento
b.eq    .L_echo_print_args
cmp     w2, #0                  // Si es el fin de cadena (escribió "echo" a secas)
b.eq    .L_echo_newline
b       .L_echo_fail            // Si decía otra cosa (ej: "echos"), aborta
.L_echo_print_args:
add     x0, x0, #1              // Se salta el espacio para apuntar directo al texto
mov     x1, x0                  // X1 = Puntero al texto a imprimir
// Calculamos la longitud del argumento recorriendo hasta encontrar el '\0'
mov     x2, #0                  // Inicializa contador de bytes en 0
.L_echo_len_loop:
ldrb    w3, [x0, x2]
cmp     w3, #0
b.eq    .L_echo_execute_write
add     x2, x2, #1
b       .L_echo_len_loop
.L_echo_execute_write:
mov     x0, #1                  // Destino: Pantalla
mov     x8, #64                 // Syscall 64 = sys_write
svc     #0                      // Imprime el texto del usuario
.L_echo_newline:
mov     x0, #1                  // Destino: Pantalla
ldr     x1, =msg_newline        // Imprime un salto de línea decorativo final
mov     x2, #1
mov     x8, #64
svc     #0
mov     x0, #0                  // Éxito
b       .L_echo_end
.L_echo_fail:
mov     x0, #1                  // No fue echo
.L_echo_end:
ldr     x1, [sp, #16]           // Restaura los registros callee-saved
ldp     x29, x30, [sp], #32
ret
