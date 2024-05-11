;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Autor:        Sergiy Khudoley
; Fecha:        2024/05/11
; Version:      0.3
; Descripcion:  Programa en ensamblador preparado para el simulador de 8085 (U. Granada).
;               El programa habilita las interrupciones y entra en un bucle infinito a 
;               la espera de la interrupción RST 5.5. Como no existe en el simulador,
;               existe una subrutina abajo del todo que indica que hay que hacer en ese caso.
;               Llama a una subrutina que guarda los resultados de la tabla de multiplicar de 
;               forma descendente/ascendente para 'X' numeros del boton pulsado.
;               Además si pulsamos la tecla 'Y' se sale del bucle y devuelve para el simulador
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; VARIABLES USADAS                   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3051H	-> tabla_multiplicando                                  ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3052H	-> tabla_contador_mul                                   ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3053H	-> tabla_mem_inicio_baja                                ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3054H	-> tabla_mem_inicio_alta                                ;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                   ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 1200H 	-> tabla_inicio                                         ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3000H	-> pila_inicio                                          ;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3100H 	-> origen_programa                                      ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA 3050H
	dB 69H, 2H, 1H, 00H, 12H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;     RUTINA PRINCIPAL       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.ORG 3100H
	LXI SP, 3000H 	; Inicializacion de la pila
	
	MVI A, 08H	; Bits para las mascaras
	SIM		; Setear las mascaras

BUCLE:
	EI		; Habilitar interrupciones
	JMP BUCLE	; Bucle infinito

FIN:
	HLT
	
	;RST 1 ; En caso de ser para el uP2000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; SUBRUTINAS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Algoritmo de multiplicacion por suma desplazamiento                           ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Multiplica dos numeros positivos de 4 bits                                           ;;;;
;;;; Necesita que se le pasen los numeros por los                                         ;;;;
;;;; registros D y E, y devuelve el resultado en A                                        ;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


MULT:
	; Setear las variables iniciales
	MVI B, 0H	; Suma
	MVI C, 0H	; Contador bits

MULTS:
	; Rotar el multiplicador
	MOV A, E
	RAR
	MOV E, A
	
	; Comprobar si el bit menos significativo era 0 o 1
	JNC MULTC	 ; si no era 1 saltarse la suma

	; sumar suma anterior mas multiplicando rotado
	MOV A, B
	ADD D
	MOV B, A

	; Incrementar contador de bits
MULTC:
	INR C

	; Comprobar si el contador de bits es 4
	MOV A, C
	CPI 4H
	JZ MULTF	; En caso de que sea 4 terminar la multiplicacion y retornar
	
	; Una forma de resetear el CY a 0. Si no hago esto me puede dar problemas
	STC
	CMC

	; Rotar y guardar nuevo Multiplicando rotado
	MOV A, D
	RAL
	MOV D, A
	
	; En caso de que no se hayan completado la multiplicacion para los 4 bits
	; volver a realizar el algoritmo
	JMP MULTS	

	; Retornar la subrutina
MULTF:
	MOV A, B 	; Dejar en el acumulador el resultado
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Generar tabla de multiplicar                                                         ;;;;
;;;; Se guardan X resultados de multiplicar el                                            ;;;;
;;;; a partir de la memoria "tabla_mem_inicio"                                            ;;;;
;;;; Necesita que los datos a trabajar se guarden en memoria:                             ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; 3051H	-> tabla_multiplicando                                         ;;;;;;;;;;;;;;;
;;;;; 3052H	-> tabla_contador_mul (multiplicador)                          ;;;;;;;;;;;;;;;
;;;;; 3053H	-> tabla_mem_inicio                                            ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TABL:
	;;;;; Aqui seteo todo a valores iniciales por defecto
	; Cargar el E con el multiplicando
	LXI H, 3051H
	MOV D, M
	LXI H, 3052H
	MVI M, 1H 	; Por defecto empieza en 1
	; Cada vezq se ejecuta reseteo el valor de inicio de la memoria
	LXI H, 1209H  ; <-------- QUIERO DEJARLO A PARTIR DE LA MEMORIA
	SHLD 3053H 
	

TABLS:

	; Cargar el E con el multiplicando
	LXI H, 3051H
	MOV D, M
	; Cargar el D con el contador (multiplicador)
	LXI H, 3052H
	MOV E, M

	; Comprobar si el contador es igual a Ah
	MOV A, E
	CPI AH
	JZ TABLF ; En caso de que sea el Ah (10d) terminar

	; Multiplicar
	CALL MULT

	; Carga la posicion de memoria donde tiene que dejar el resultado
	LHLD 3053H
	; Guardando el resultado
	MOV M, A	; Guardar el resultado

	; Incrementar la posicion de memoria
	;INX H		; Incrementar la posicion de memoria donde se guardara el siguiente dato
	DCX H		; <--------------- Quiero guardarlo en orden inverso
	SHLD 3053H	; Volver a guardar la posicion de memoria
	
	; Incrementar el contador (es a la vez el multiplicador)
	LXI H, 3052H	; Aqui esta el multiplicador
	MOV A, M	;
	ADI 1H	
	MOV M, A	; Guardar el nuevo multiplicador

	JMP TABLS
	

	; Retornar la subrutina
TABLF:
	RET


	;END ; Para el uP2000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; RST 5.5 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; En el simulador cuando recibe la interrupcion 5.5 salta a                          ;;;;;;;
;;; la posicion 002CH. Como no existe ROM, entonces                                    ;;;;;;;
;;; tengo que crear yo la lógica que se va a ejecutar cuando                           ;;;;;;;
;;; llegue a estsa posición                                                            ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.ORG 002CH
	IN 00H		; Deposito lo que se atrape en A
	
	; Comprobar si el valor pulsado es '0' (30H)
	CPI 30H	; < ------- SALIR CON LA TECLA
	JZ FIN 		; En caso de que sea, terminar bucle infinito

	; Guardar en memoria el valor atrapado por la interrupcion
	LXI H, 3051H	; Posicion donde se deja el multiplicando

	; El valor recibido esta en ASCII
	; Primero lo modifico a un numero. En este caso 0=30 y 39=9
	; asi que le puedo restar 30
	SBI 30H ; El valor resultante se deja en el acumulador (0 al 9)
	; !Cuidado las letras no funcionan igual!	

	MOV M, A	; Escribir nuevo multiplicando

	; Ejecutar creacion de la tabla
	CALL TABL
	RET
	


