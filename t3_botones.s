;Archvo: timer0.s
;Dispositivo: PIC16F887
;Autor: Kevin Hernández
;Compilador: Pic.as(v2.31) MPLAB v5.50
;Programa: contador en el puerto A activado por timer0
;Harware: LEDs en el puerta A y D, display en puerto C y botones en puerto B
;Creado: 09/08/2021
;Ultima modificación: 09/08/2021

PROCESSOR 16F887

    #include <xc.inc>
;--------------------------BITS DE CONFIGURACION-------------------------------;
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; oscilador interno 
  CONFIG  WDTE = OFF            ; Watchdog Timer- reinicio repetitivo PIC 
  CONFIG  PWRTE = ON            ; espera de 72 ms aprox al inciar el PIC 
  CONFIG  MCLRE = OFF           ; pin MCLR se usa como I/O 
  CONFIG  CP = OFF              ; proteccion de codigo
  CONFIG  CPD = OFF             ; proteccion de datos
  CONFIG  BOREN = OFF           ; reinicio cuando el V.alimentacion baje de 4V 
  CONFIG  IESO = OFF            ; reinicio sin cambio de reloj de int a ext
  CONFIG  FCMEN = OFF           ; en caso de algun fallo cambio de reloj ext-int 
  CONFIG  LVP = ON              ; programar en bajo votaje

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; reinicio PIC abajo de 4V
  CONFIG  WRT = OFF             ; proteccion de autoescritura
  

;------------------------------ | variables | ---------------------------------;
  PSECT udata_bank0	       ;PSECT, SECTOR DE PROGRAMA,INDICA LOS REGISTROS
			       ; DE PROPOSITO GENERAL QUE ESTARAN EN EL BANCO 0 
  ;cont: DS 2 ;separar 2 bytes
  contador: DS 1 
  contador2: DS 1
  cont_d: DS 2 ;separar 2 bytes
  cont: DS 2
;----------------------------- | vector reset | -------------------------------;
PSECT resVect, class=CODE, abs, delta=2    ;SECTOR DEL VECTOR RESET
ORG 00h          ;ESTA EN LA POSICION 0 PORQUE EL VECTOR RESET ESTA ESA POSICIÓN
    
resetVec:        ;etiqueta por si quiero regresar a la posicion 0 
  PAGESEL main	 ;selecciona la pagina principal main con la directiva pagesel  
  goto main      ;se llamara con la instruccion goto

;-----------------| 
;|CODIGO PRINCIPAL|-----------------------------------------------------------;
;-----------------|  
PSECT code, delta=2, abs 
ORG 100h	 ;POSICION PARA EL CODIGO EN 100 HEXADECIMAL
 
;-------------------------------- | TABLA | ----------------------------------;
tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0 ;PCLATH = 01
    andlw   00001111B ;va a poner en 0 todo lo superior a 16, el valor mas grande es f
    addwf   PCL	      ;PC = PCLATH + PCL + W = 103+1h+W = (se le suma lo del conta)
    retlw   00111111B	      ;return y devuelve una literal 0
    retlw   00000110B	      ;1
    retlw   01011011B	      ;2
    retlw   01001111B	      ;3
    retlw   01100110B	      ;4
    retlw   01101101B	      ;5
    retlw   01111101B	      ;6
    retlw   00000111B	      ;7
    retlw   01111111B	      ;8
    retlw   01101111B	      ;9
    retlw   01110111B	      ;A
    retlw   01111100B	      ;B
    retlw   00111001B	      ;C
    retlw   01011110B	      ;D
    retlw   01111001B	      ;E
    retlw   01110001B	      ;F
    
;--------------------------- | CONFIGURACIÓN | --------------------------------;
main:
    call config_io	    ;Configuración de entradas y salidas
    call config_reloj	    ;Configuración de ocsilador interno
    call config_timer0	    ;Configuracion del timer0
    banksel PORTA	    ;Si no se esta seguro en el banco en que estamos
 
;--------------------------- | LOOP PRINCIPAL | -------------------------------; 
loop:
    btfss   T0IF ;si la bandera se activa, ya pasaron los 100 ms, se salta
    goto    $-1
    incf    PORTA
    
    call    contador_seg    ;contador 3 de 1 segundo 
    call    reinicio_timer0 ;se reinicia la bandera

    
    btfsc   PORTB, 0	    ;se el pin 0 del PORTB es 1 hace la siguiente inst.
    call    inc_portc       ;llama a la subrutina incrementar PORTC
   
    btfsc   PORTB, 1	    ;se el pin 1 del PORTB es 1 hace la siguiente inst.
    call    dec_portc	    ;llama a la subrutina decrementar PORTC
    
    call    comparacion	    ;llama a la subrutina comparacion 
    goto    loop
 
;---------------------------- | SUB RUTINAS | ---------------------------------;
config_io:
    banksel ANSEL	;banco 3 (11)
    clrf    ANSEL	;se colocan los puertos A como digitales
    clrf    ANSELH	;se colocan los puertos B como digitales
			;con los registros ANSEL Y ANSELH
    
    banksel TRISA	;banco 1 (01)
    clrf    TRISA	;PORTA como salida para contador de 100 mseg
    clrf    TRISC	;PORTC como salida para displays de 7 seg
    clrf    TRISD	;PORTD como salida para contador de segundos
    
    bsf	    TRISB,0     ;PUERTO B como entrada
    bsf	    TRISB,1	;por medio de la instrucción bsf
    ;bcf	    TRISB,2	;
    
    banksel PORTA	;banco 0 (00)
    clrf    PORTA	;limpiar PORTA (valor inicial a 0)
    clrf    PORTB	;limpiar PORTA (valor inicial a 0)
    clrf    PORTC	;limpiar PORTC
    clrf    PORTD	;limpiar PORTD
    return
    
config_reloj:
    banksel OSCCON  ;se selecciona con la directiva BANKSEL el banco del 
		    ;registro OSCCON para poder configurar el oscilador
    
		    ;poniendo el nombre de los bits 4,5,6 		    
		    ;se confiura a 250 KHz (reloj lento, ahorro bateria)
    bcf IRCF2	    ;(0) 
    bsf IRCF1	    ; (1)
    bcf IRCF0	    ; (0)
    bsf SCS	    ; se pon en 1 el bit o para colocar el reloj interno
    return
    
config_timer0:
    ;banksel TRISA   ;banco 1 (01)
    bcf	    T0CS    ;colocar el reloj interno
    bcf	    PSA	    ;assigno un prescaler para el modulo timer0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS = 111 -> configurar la razon de escala a 1:256 
    banksel PORTA
    call reinicio_timer0
    ;se coloco aparte ya que cada vez que el timer termine de contar
    ;hay que volver a cargar los valores, entonces se reuitlizara la subrutina
    ;reinicio_timer0
    return
    
reinicio_timer0:
    BANKSEL TMR0
    movlw   231     ;100meg = 4*(1/250 KHz)*(256-N)*256 --> N=231 para obtener
		    ; un delay de 100ms cada vez que la bandera se active
    movwf   TMR0    ;mover w a f el timer0
    bcf	    T0IF    ;bit TOIF esta a 0 (bandera de interrupcion del timer0 OFF) 
    return
    
inc_portc:
    btfss   PORTB, 0 ;misma instruccion para realizar antirrebote
    goto    $-1		  
    btfsc   PORTB, 0
    goto    $-1
    
    incf    contador    ;incrementa la variable contador
    movf    contador, W ;mover contador  a W (acumulador)
    call    tabla    ;se llama a la etiqueta tabla, el cual convierte el valor W
    movwf   PORTC    ;se mueve en W  el valor convertido a puerto C
    return     
    
dec_portc:   
    btfss   PORTB, 1
    goto    $-1		  
    btfsc   PORTB, 1
    goto    $-1
    
    decf    contador    ;decrementar el contador
    movf    contador, W	;mover contador  a W (acumulador)
    call    tabla    ;se llama a la etiqueta tabla, el cual convierte el valor W
    movwf   PORTC    ;mover el valor convertido a puerto C
    return  
    
contador_seg:
    ;incf    PORTA
    movlw   10		;se mueve una literal 10 al acumulador W
    subwf   PORTA, 0    ;se hace la resta de W con el PUERTO A
    btfsc   STATUS,2	;si el resultado de la operacion es 0, se coloca el bit 2
                        ;del registro STATUS en 1
    call    conta_seg	;se llama a la sub rutina cnta_Seg
    return
    
conta_seg:
    clrf    PORTA	;limpia PORTA
    incf    PORTD	;incrementa el puerto D
    btfsc   PORTD,4	;contador 3 de 4 bits
    clrf    PORTD	;Limpia el puerto D
    return
 
comparacion:
    movf    PORTD, W	 ;se mueve lo del puerto D al acumulador
    subwf   contador, 0  ;se hace la resta de W con la variable contador del display
    btfsc   STATUS,2     ;si el resultado de la operacion es 0, se coloca el bit 2
                         ;del registro STATUS en 1
    
    call alarma		;alarma
    return   
    
alarma:			
    clrf    PORTD	;limpia el puerto D (REINICIA)
    bsf	    PORTC,7	;se pone en 1 pin 7 del PORTC
    call    delay	;se llama a un delay
    bcf	    PORTC,7	;se pone en 0 pin 7 del PORTC
    ;bsf	    PORTB,2
    return
    
delay: ;0.5ms
    movlw   165	    ;valor incial
    movwf   cont
    decfsz  cont, 1 ;decrementar cont y guardar en cont
    goto    $-1	    ;ejecutar a la linea anterior
    return
       
end


