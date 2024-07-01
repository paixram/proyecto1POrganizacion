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
	ult_numero: .word -1  # Último número generado por el dado
	rep_count: .word 0    # Contador de repeticiones del último número
	
	separator: .asciiz " | "	# Separador entre elementos
	newline: .asciiz "\n"		# Nueva línea al final
	msg_intro:  .asciiz "Bienvenido al Juego de Chacales\n"
	msg_ganar:  .asciiz "Has ganado $"
	msg_perder: .asciiz "Has perdido. Encontraste todos los chacales\n"
	msg_perder_por_repeticion: .asciiz "Has perdido. Haz repetido el numero del dado 3 veces consecutivas\n"
	msg_continuar: .asciiz "¿Deseas continuar jugando? (s/n): "
	msg_turno:  .asciiz "Casillas descubiertas: "
	msg_dinero: .asciiz "Dinero acumulado: $"
	msg_chacales: .asciiz "Chacales encontrados: "
	msg_girar: .asciiz "Girar Dado (s/n): "
	msg_salida: .asciiz "Vuelva a jugar pronto..."
	msg_invalida: .asciiz "Entrada no válida, vuelva a intentarlo\n"
	msg_valor_dado: .asciiz "El dado ha sacado el valor: "

.text
main: 
	# Inicializar el juego
    	la $a0, msg_intro
    	li $v0, 4
    	syscall
    	jal init_board

juego:
	jal display_board	#mostrar tablero
	jal game_status

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
	bge $t0, 8, fin_ganar      # Si ya encontro los 8 tesoros entonces gana
	
    	
    	# Mostrar tablero actualizado
	jal display_board
	jal game_status
    	
    	# Si ha encontrado 4 tesoros, preguntar si quiere continuar
    	li $v0, 4
    	la $a0, msg_continuar
    	syscall
    	
    	la $a0, buffer
    	li $a1, 256
    	li $v0, 8
    	syscall
    
    	lb $t3, 0($a0)
    
    	beq $t3, 's', continuar
    	beq $t3, 'n', fin_ganar
	
		
continuar:
	j juego
		
fin_ganar:
	# Mostrar tablero actualizado
	jal display_board
	li $v0, 4
    	la $a0, msg_ganar
    	syscall
    	lw $a0, dinero
    	li $v0, 1
    	syscall
    	j fin

fin_perder:
	# Mostrar tablero actualizado
	jal display_board
	li $v0, 4
    	la $a0, msg_perder
    	syscall
    	j fin
    	
fin_perder_por_repeticion:
	# Mostrar tablero actualizado
	jal display_board
	li $v0, 4
    	la $a0, msg_perder_por_repeticion
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
    	move $s0, $a0
    	#li $s0, 1 for test
    	# Mostrar el mensaje del valor del dado
    	li $v0, 4
    	la $a0, msg_valor_dado
    	syscall
    
    	li $v0, 1
    	move $a0, $s0
    	syscall
    	
    	la $a0, newline      # Imprimir una nueva línea al final
    	li $v0, 4            # syscall para imprimir string
    	syscall
    	
    	# Verificar si el número generado se ha repetido tres veces consecutivas
    	lw $s1, ult_numero
    	lw $s2, rep_count
    
    	beq $s0, $s1, aumentar_contador
    	j reset_contador
    	
    	#move $v0, $a0
    	#jr $ra
    	
aumentar_contador:
    addi $s2, $s2, 1
    sw $s2, rep_count
    
    li $s3, 3
    beq $s2, $s3, fin_perder_por_repeticion
    j continuar_juego
    
reset_contador:
    li $s2, 1
    sw $s2, rep_count
    sw $s0, ult_numero
    
continuar_juego:
    
    
    move $v0, $s0
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
    	
    	bne $t5, $zero , salto
    	
    	sw $t4, 0($t2)
    	
    	lw $t7, num_descubiertas
	addi $t7, $t7, 1
	sw $t7, num_descubiertas
    	
    	
    	# Si la casilla contiene un tesoro (valor 100)
	li $t6, 100
	beq $t4, $t6, aumento_tesoro

	# Si la casilla contiene un chacal (valor -1)
	li $t6, -1
	beq $t4, $t6, aumento_chacal
	
	j salto
    	 
salto:	
	j juego
	
aumento_tesoro:
	lw $t7, tesoros_enc
	addi $t7, $t7, 1
	sw $t7, tesoros_enc
	
	# Actualizar el dinero ganado
	lw $t8, dinero
	addi $t8, $t8, 100  # Asume que cada tesoro vale 100
	sw $t8, dinero

	jr $ra
    	
aumento_chacal:
	lw $t7, chacales_enc
	addi $t7, $t7, 1
	sw $t7, chacales_enc
	
	jr $ra
	
game_status:
	 # Mostrar dinero acumulado y chacales encontrados
    	li $v0, 4
    	la $a0, msg_dinero
    	syscall

    	lw $a0, dinero
   	 li $v0, 1
    	syscall
    
    	la $a0, newline      # Imprimir una nueva línea al final
    	li $v0, 4            # syscall para imprimir string
    	syscall
    
    	li $v0, 4
    	la $a0, msg_chacales
    	syscall
    
    	lw $a0, chacales_enc
    	li $v0, 1
    	syscall
    	
    	la $a0, newline      # Imprimir una nueva línea al final
    	li $v0, 4            # syscall para imprimir string
    	syscall
    	
    	jr $ra
