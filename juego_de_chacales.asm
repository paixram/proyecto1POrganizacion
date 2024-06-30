.data
	#.align 2
	board:      .word 0:12      # Tablero de 12 casillas
	premios:   .word 8
	chacales:   .word 4
	
	msg_intro:  .asciiz "Bienvenido al Juego de Chacales\n"
	msg_ganar:  .asciiz "Has ganado $"
	msg_perder: .asciiz "Has perdido. Encontraste todos los chacales\n"
	msg_continuar: .asciiz "¿Deseas continuar jugando? (s/n): "
	msg_turno:  .asciiz "Casillas descubiertas: "
	msg_dinero: .asciiz "Dinero acumulado: $"
	msg_chacales: .asciiz "Chacales encontrados: "
	msg_girar: .asciiz "Girar Dado (s/n): "

.text
main: 
	# Inicializar el juego
    	la $a0, msg_intro
    	li $v0, 4
    	syscall
    	jal init_board
    	j print #cambiarse por jal para seguir implementando
juego:
	#jal display_board	#mostrar tablero
	#jal get_input		#obtener entrada
	
	#jal check_move
	
		
# Inicializar el tablero con chacales y tesoros
init_board:
    lw $t0, premios	# $t0 = 8 (premios)
    lw $t1, chacales
    li $t2, 2
    #add $t2, $t0, $t1    # $t2 = total de elementos a distribuir (12)
    la $t3, board
    # Llenar el arreglo con premios y chacales en posiciones aleatorias
    li $t4, 12
    
init_loop:
    li $v0, 42              # Llamar al generador de números aleatorios
    move $a1, $t2        # Argumento para el número aleatorio (total de elementos)
    syscall              # Generar número aleatorio
    move $t5, $a0        # $t5 = número aleatorio
    
    # Determinar si colocar premio (dinero) o chacal (trampa)
    beq $t5,$zero,place_chacal
    beq $t0, $zero, place_chacal  # Si $t0 (premios restantes) es >= 0, colocar una mina
    li $v0, 42              # Llamar al generador de números aleatorios
    li $a1, 10        # Argumento para el número aleatorio (total de elementos)
    syscall              # Generar número aleatorio
    move $t5, $a0
    addi $t5,$t5,1
    mul $t5,$t5,10
    sw $t5, 0($t3)       # Guardar una mina en el arreglo en la posición aleatoria
    addi $t0, $t0, -1    # Decrementar contador de minas restantes
    b end_fill           # Saltar al final del bucle
    
place_chacal:
    beq $t1, $zero, init_loop
    li $t5, -1
    sw $t5, 0($t3)       # Guardar un premio en el arreglo en la posición aleatoria
    addi $t1, $t1, -1    # Decrementar contador de premios restantes

end_fill:
    addi $t3, $t3, 4     # Mover al siguiente elemento del arreglo
    addi $t4, $t4, -1    # Decrementar contador de iteraciones del bucle
    bnez $t4, init_loop # Si no se ha llenado todo el arreglo, repetir el bucle
    
    jr $ra

print: #Imprimir el contenido del arreglo
    la $t0, board       # Cargar la dirección base del arreglo en $t0
    li $t1, 12          # Contador para el bucle (número de elementos del arreglo)

print_loop:
    lw $a0, 0($t0)      # Cargar el valor del arreglo en $a0
    li $v0, 1           # syscall 1: imprimir entero
    syscall             # Llamar a la syscall para imprimir el valor en $a0

    # Imprimir un espacio después de cada número (opcional para claridad)
    li $v0, 11          # syscall 11: imprimir carácter
    li $a0, ' '         # Cargar el carácter espacio en $a0
    syscall             # Llamar a la syscall para imprimir un espacio

    addi $t0, $t0, 4    # Avanzar al siguiente elemento del arreglo (4 bytes = tamaño de una palabra)
    addi $t1, $t1, -1   # Decrementar contador de iteraciones del bucle
    bnez $t1, print_loop    # Si no se ha imprimido todo el arreglo, repetir el bucle

    # Imprimir un salto de línea al final (opcional para claridad)
    li $v0, 11          # syscall 11: imprimir carácter
    li $a0, '\n'        # Cargar el carácter de nueva línea en $a0
    syscall
    
    
    li $v0, 10
    syscall
     #jr $ra quitar este comentario por el jal print del main