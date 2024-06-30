.data
	buffer: .space 256
	board:      .word 0:12	# arreglo de 12 casillas
	status:     .word 0:12      # Estado de las casillas (0 = oculta, 1 = descubierta)
	tesoros:   .word 8	# número de tesoros
	chacales:   .word 4	# número de chacales
	dinero:     .word 0        # Dinero ganado
	chacales_enc: .word 0      # Chacales encontrados
	tesoros_enc: .word 0	   # Tesoros encontrado
	num_descubiertas: .word 0  # Número de casillas descubiertas
	num_dados_rep: .word 0
	
	separator: .asciiz " | "	# Separador entre elementos
	newline: .asciiz "\n"		# Nueva línea al final
	msg_intro:  .asciiz "Bienvenido al Juego de Chacales\n"
	msg_ganar:  .asciiz "Has ganado $"
	msg_perder: .asciiz "Has perdido. Encontraste todos los chacales\n"
	msg_continuar: .asciiz "¿Deseas continuar jugando? (s/n): "
	msg_turno:  .asciiz "Casillas descubiertas: "
	msg_dinero: .asciiz "Dinero acumulado: $"
	msg_chacales: .asciiz "Chacales encontrados: "
	msg_girar: .asciiz "Girar Dado (s/n): "
	msg_salida: .asciiz "Vuelva a jugar pronto..."
	msg_invalida: .asciiz "Entrada no válida, vuelva a intentarlo\n"

.text
main: 
	# Inicializar el juego
    	la $a0, msg_intro
    	li $v0, 4
    	syscall
    	jal init_board

juego:
	jal display_board	#mostrar tablero
	jal get_input		#obtener entrada
	
	# Procesar el movimiento
	jal check_move
	
	# Verificar si el jugador ha ganado o perdido
	lw $t0, tesoros_enc
    	lw $t1, chacales_enc
    	lw $t2, num_descubiertas
    	bge $t2, 12, fin_perder    # Si todas las casillas están descubiertas y no ha ganado, pierde
    	bge $t1, 4, fin_perder     # Si encontró todos los chacales, pierde
    	blt $t0, 4, juego          # Si aún no ha encontrado 4 tesoros, continúa jugando
    	
    	# Si ha encontrado 4 tesoros, preguntar si quiere continuar
    	li $v0, 4
    	la $a0, msg_continuar
    	syscall
    	
    	la $a0, buffer
    	li $a1, 256
    	li $v0, 8
    	syscall
    
    	lb $t3, 0($a0)
    
    	beq $t3, 's', juego
    	beq $t3, 'n', fin_ganar
		
fin_ganar:
	li $v0, 4
    	la $a0, msg_ganar
    	syscall
    	lw $a0, dinero
    	li $v0, 1
    	syscall
    	j fin

fin_perder:
	li $v0, 4
    	la $a0, msg_perder
    	syscall
    	j fin

fin_salir:
	li $v0, 4
	la $a0, msg_salida 
	syscall
fin:
	# Finalizar el programa
    	li $v0, 10
    	syscall
				
# Inicializar el tablero con chacales y tesoros
init_board:
	lw $t0, tesoros	
	lw $t1, chacales  
    	li $t2, 2
    	la $t3, board
    	li $t4, 12
    
init_loop:
	li $v0, 42           # Llamar al generador de números aleatorios
    	move $a1, $t2        # Argumento para el número aleatorio (total de elementos)
    	syscall              # Generar número aleatorio
    	move $t5, $a0        # $t5 = número aleatorio
    
    	# Determinar si colocar premio (dinero) o chacal (trampa)
    	beq $t5,$zero,place_chacal
    	beq $t0, $zero, place_chacal  # Si $t0 (tesoros restantes) es <= 0, colocar una chacal
    	li $t5,100
    	sw $t5, 0($t3)       # Guardar un chacal en el arreglo en la posición 
    	addi $t0, $t0, -1    # Decrementar contador de tesoros restantes
    	b end_fill           # Saltar al final del bucle
    
place_chacal:
	beq $t1, $zero, init_loop
    	li $t5, -1
    	sw $t5, 0($t3)       # Guardar un chacal en el arreglo
	addi $t1, $t1, -1    # Decrementar contador de chacales restantes

end_fill:
	addi $t3, $t3, 4     # Mover al siguiente elemento del arreglo
    	addi $t4, $t4, -1    # Decrementar contador de iteraciones del bucle
    	bnez $t4, init_loop # Si no se ha llenado todo el arreglo, repetir el bucle
    	jr $ra

# Mostrar el tablero
display_board:
	la $t0, board
	la $t1, status
	
	li $t2, 0
display_loop:
    	bge $t2, 12, display_end
    	
    	lw $a0, 0($t1)       # Cargar el elemento actual del arreglo en $a0
    	li $v0, 1            # syscall para imprimir entero
    	syscall
    	
    	addi $t2, $t2, 1     # Incrementar el índice del arreglo
    
    	bge $t2, $t0, skip_separator   # Si es el último elemento, saltar la impresión del separador
    
    	la $a0, separator    # Cargar el separador entre elementos
    	li $v0, 4            # syscall para imprimir string
    	syscall
    	
skip_separator:
    	addi $t1, $t1, 4     # Mover el puntero al siguiente elemento del arreglo
    	j display_loop         # Repetir el bucle
    	
display_end:
	la $a0, newline      # Imprimir una nueva línea al final
    	li $v0, 4            # syscall para imprimir string
    	syscall
    	jr $ra
    	

# Obtener la entrada del usuario y girar dado
get_input:
    li $v0, 4
    la $a0, msg_girar
    syscall
    
    la $a0, buffer
    li $a1, 256
    li $v0, 8
    syscall
    
    lb $t3, 0($a0)
    
    beq $t3, 's', generar_numero
    beq $t3, 'n', fin_salir
    
    # Si la entrada no es ni 's' ni 'n', imprimir mensaje de error y finalizar
    li $v0, 4
    la $a0, msg_invalida
    syscall
    j get_input

generar_numero:
	li $v0, 42           # Llamar al generador de números aleatorios
    	li $a1, 12        # Argumento para el número aleatorio (total de elementos)
    	syscall              # Generar número aleatorio
    	move $v0, $a0
    	jr $ra

# Verificar el movimiento del usuario (COMPLETAR)
check_move:
	li $t0, 0
    	add $t0,$t0, $v0
    	#addi $t0,$t0,-1
    	sll $t3, $t0, 2
    	la $t1, board
    	la $t2, status
    	
    	# tomar en cuenta offset
    	add $t1,$t1,$t3
    	add $t2,$t2,$t3
    	lw $t4, 0($t1)
    	lw $t5, 0($t2)
    	
    	li $t6, 100
    	
    	beq $t4,$t6, aumento_tesoro
	
	lw $t7, chacales_enc
	la $t8, chacales_enc
	addi $t7,$t7,1
	sw $t7, 0($t8)  
salto:	
	bne $t5,$zero,juego
    	sw $t4, 0($t2)
    	j juego
aumento_tesoro:
	lw $t7, tesoros_enc
	la $t8, tesoros_enc
	addi $t7,$t7,1
	sw $t7, 0($t8)    	
    	j salto	
    	
    	
    	
    	
    	
    	
    	
    	
