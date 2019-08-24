;===============================================================================
; Programa gorilas.as
;
; Descricao: Jogo gorilas
;
; Autores: David Baptista - 92446 | Jose Rodrigues 92503
;===============================================================================

;===============================================================================
; ZONA I: Definicao de constantes
;===============================================================================

; Enderecos de I/O
IO_READ         EQU FFFFh
IO_WRITE        EQU FFFEh
IO_STATUS       EQU FFFDh
IO_CONTROL      EQU FFFCh

TIMER_COUNT_ADDR    EQU FFF6h   ; Endereco do valor do contador usado para o timer
TIMER_CTRL_ADDR     EQU FFF7h   ; Endereco para parar ou ligar o timer

TIMER_STATE         EQU 1b      ; Estado do timer 0 - inativo 1 - ativo
TICKS_SEC           EQU 1       ; Ticks por segundo (1 * 100ms) = 100ms = 0,1s

MASK_ADDR           EQU	0000000000000000b

INT_MASK	    EQU	83ffh

;--------------------------------------
; Constantes da trajetoria
;--------------------------------------

SP_INIC EQU FDFFh                       ; Stack Pointer

GRAVITY EQU 09CDh                       ; Gravidade em 8/8 (9.8 * 16^2 = 2509d = 09CDh)

RAD     EQU 4774h                       ; PI/180 radianos em 0/16 (((3.14 / 180) * 16^2) * 16^3 = 4774h)

MASCARA         EQU 1000000000010110b   ; Mascara random

; Constantes da janela de txt
IGUAL           EQU 003Dh
BARRA_DIREITA   EQU 002Fh
BARRA_ESQUERDA  EQU 005Ch
PARENTESES_E    EQU 0028h
PARENTESES_D    EQU 0029h
PONTO           EQU 002Eh
ASTERISCO       EQU 002Ah
ESPACO          EQU 0020h
LETRA_O         EQU 004Fh
LETRA_Z         EQU 005Ah

;===============================================================================
; ZONA II: Definicao de interrupcoes
;=============================================================================

                ORIG    FE00h
INT0            WORD    BTN_0
INT1            WORD    BTN_1
INT2            WORD    BTN_2
INT3            WORD    BTN_3
INT4            WORD    BTN_4
INT5            WORD    BTN_5
INT6            WORD    BTN_6
INT7            WORD    BTN_7
INT8            WORD    BTN_8
INT9            WORD    BTN_9
INT10           WORD    BTN_10
INT11           WORD    BTN_11
INT12           WORD    BTN_BACKSPACE
INT13           WORD    BTN_13
INT14           WORD    BTN_RETURN
INT15           WORD    SECS

;===============================================================================
; ZONA III: Definicao de variaveis
;=============================================================================
                ORIG 8000h

; Valores da trajetoria
ANGLE           WORD 0000h
VELOCITY        WORD 0000h

POS_HORIZONTAL  WORD 0000h
POS_VERTICAL    WORD 0000h

; Placeholders para os valores do seno, cosseno (em rads) e tempo final
ANGLE_SIN       WORD 0000h 
ANGLE_COS       WORD 0000h

; Valores true/false
IS_RETURN       WORD 0000h
IS_DELETE       WORD 0000h
RESTART         WORD 0000h

; Valores para a janela de texto
CURSOR          WORD FFFFh
USED_POSITIONS  TAB 30

; Valores do timer
COUNTER         WORD 0000h
PREV_COUNTER    WORD FFFFh

; Valor do ultimo botao
BTN_NUM         WORD FFFFh

; Gorilas
GORILLA1_POS    WORD 1505h
GORILLA1_Y      WORD 0000h
GORILLA2_POS    WORD 1540h
GORILLA2_Y      WORD 0000h
GORILLA1_HITBOX  TAB 10
GORILLA2_HITBOX  TAB 10

; Posicoes da banana
POS_BANANA1     WORD 0000h
POS_BANANA2     WORD 0000h
LAST_POS        WORD EEEEh

; Variaveis do score
SCORE1          WORD 0000h
SCORE2          WORD 0000h

; Variaveis de jogadores
FIRST_PLAYER    WORD 0001h
CURRENT_PLAYER  WORD 0001h
HIT_PLAYER      WORD 0000h

; Bools para o jogo
IS_HIT          WORD 0000h
APAGA_TUDO      WORD 0000h

; Variaveis Random
ITERADOR        WORD 0001h
RAND_SEED1      WORD 0000h
RAND_SEED2      WORD 0000h
RANDOM_SEQUENCE TAB 1000

; Mensagens
MENSAGEM_START     STR 'Clique numa tecla para iniciarZ'
MENSAGEM_RESTART   STR 'Clique numa tecla para reiniciarZ'
MENSAGEM_ANGLE     STR 'ANGLE:Z'
MENSAGEM_SPEED     STR 'SPEED:Z'
MENSAGEM_SCORE     STR 'SCORE:Z'
MENSAGEM_PLAYER    STR 'PLAYERZ'
MENSAGEM_VENCEDOR1 STR 'GANHOU O PLAYER1!Z'
MENSAGEM_VENCEDOR2 STR 'GANHOU O PLAYER2!Z'

LINHA_BRANCA    STR '                                                                                Z'


;===============================================================================
; ZONA IV: Definicao das Interrupções
;===============================================================================
BTN_0:  MOV R1, 30h
        MOV M[BTN_NUM], R1      ; (igual em todas) passa para a variavel em memoria o codigo ascii do caracter a escrever apos carregar no botao
        RTI

BTN_1:  MOV R1, 31h
        MOV M[BTN_NUM], R1
        RTI

BTN_2:  MOV R1, 32h
        MOV M[BTN_NUM], R1
        RTI

BTN_3:  MOV R1, 33h
        MOV M[BTN_NUM], R1
        RTI

BTN_4:  MOV R1, 34h
        MOV M[BTN_NUM], R1
        RTI

BTN_5:  MOV R1, 35h
        MOV M[BTN_NUM], R1
        RTI

BTN_6:  MOV R1, 36h
        MOV M[BTN_NUM], R1
        RTI

BTN_7:  MOV R1, 37h
        MOV M[BTN_NUM], R1
        RTI

BTN_8:  MOV R1, 38h
        MOV M[BTN_NUM], R1
        RTI

BTN_9:  MOV R1, 39h
        MOV M[BTN_NUM], R1
        RTI

BTN_10: RTI

BTN_11: RTI

BTN_13: RTI


BTN_BACKSPACE:  MOV R1, 0008h
                MOV M[BTN_NUM], R1
                RTI

BTN_RETURN:     MOV R1, 000Ah
                MOV M[BTN_NUM], R1
                RTI

SECS:   INC M[COUNTER]                  ; Incrementa o contador sempre que passam TICKS_SEC/10 segundos

        MOV R7, TICKS_SEC
        MOV M[TIMER_COUNT_ADDR], R7
        MOV R7, TIMER_STATE
        MOV M[TIMER_CTRL_ADDR], R7

        RTI

;===============================================================================
; ZONA IV: Inicio do programa 
;===============================================================================
        ORIG 0000h
        JMP START

;===============================================================================
; SUBZONA I: SUBROTINAS DE ESCRITA 
;===============================================================================

;===============================================================================
;PREPARE_CONTROL: Rotina que inicializa a variavel de controlo da janela
;       Entradas: ---
;       Saidas: ---
;       Efeitos: Inicializa o valor M[IO_CONTROL]
;===============================================================================
PREPARE_CONTROL:PUSH R1

                MOV R1, FFFFh
                MOV M[IO_CONTROL], R1           

                POP R1
                
                RET

;===============================================================================
;UPDATE_CURSOR: Rotina que atualiza o valor do cursor na janela
;       Entradas: M[SP+3]: endereco do cursor
;       Saidas: ---
;       Efeitos: Altera o valor de M[IO_CONTROL]
;===============================================================================
UPDATE_CURSOR:  PUSH R1

                MOV R1, M[SP+3]         ; Atualizacao da posicao do cursor
                MOV M[IO_CONTROL], R1   

                POP R1

                RETN 1

;===============================================================================
;READCHAR: Subrotina que le um caracter
;       Entradas: ----
;       Saidas: M[SP+3] O Char escrito
;       Efeitos: Recebe um caracter do teclado numerico do P3 ou QWERTY
;===============================================================================
READCHAR:       PUSH R1
                MOV R1, M[BTN_NUM]
                CMP R1, FFFFh           ; Verificar se algum botao foi premido
                BR.Z READCHAR_AUX
                MOV M[SP+3], R1
                MOV R1, FFFFh
                MOV M[BTN_NUM], R1      ; Reset ao numero do botao
                POP R1
                RET

        ; Rotina que verifica se uma tecla foi premida no caso de nao ter sido premido nenhum botao
        READCHAR_AUX:   POP R1
                        CMP R0, M[IO_STATUS]
                        BR.Z READCHAR
                        PUSH R1
                        MOV R1, M[IO_READ]
                        MOV M[SP+3], R1
                        POP R1
                        RET

;===============================================================================
;WRITE_CHAR: Rotina que escreve um caracter na consola
;       Entradas: M[SP+3] - Caracter
;       Saidas: ---
;       Efeitos: Escreve em M[IO_WRITE]
;===============================================================================
WRITE_CHAR:     PUSH R1

                MOV R1, M[SP+3]         ; Escreve o caracter recebido na janela de texto
                MOV M[IO_WRITE], R1

                POP R1

                RETN 1

;===============================================================================
; SUBZONA II: Subrotinas de geracao pseudo aleatoria 
;===============================================================================

;===============================================================================
;RANDOM: Rotina que gera um valor pseudo aleatorio recorrendo a uma tabela e a uma seed
;       Entradas: Seed, tabela de valores
;       Saidas: Valor aleatorio
;       Efeitos: Gera um valor pseudo aleatorio
;===============================================================================
RANDOM:         MOV R3, RANDOM_SEQUENCE
                ADD R3, M[ITERADOR]
                MOV R4, M[R3]
                TEST R4, 0001h
                BR.Z RANDOM_SKIP
                XOR R4, MASCARA
RANDOM_SKIP:    ROR R4, 1
                INC M[ITERADOR]
                INC R3
                MOV M[R3], R4
                MOV R1, M[ITERADOR]
                MOV R7, RANDOM_SEQUENCE
                ADD R1, R7
                MOV R1, M[R7]
                XOR R2, R2
                XOR R3, R3
                MVBL R2, R1
                MVBH R3, R1
                SHR R3, 8
                MOV R4, 10
                DIV R2, R4
                MOV M[SP+2], R4         ; Da output do valor aleatorio ao mover para o stack

                RET

;===============================================================================
;FILL_TABLE: Rotina que preenche uma tabela com valolres para gerar um valor aleatorio
;       Entradas: --
;       Saidas: Tabela de valores
;       Efeitos: Gera uma tabela em memoria
;===============================================================================
FILL_TABLE:     MOV R3, M[ITERADOR]
                ADD R3, RANDOM_SEQUENCE         
                MOV M[R3], R7
                INC R7
                INC M[ITERADOR]

                MOV R6, 1000
                CMP M[ITERADOR], R6

                BR.NZ FILL_TABLE

                RET

;===============================================================================
; SUBZONA III: Subrotinas de preparacao da trajetoria (Fase 1 do projeto)
;===============================================================================

;===============================================================================
;PREPARE_BANANA: Rotina que prepara todos os valores para a trajetoria da banana, isto e
; chama as respetivas funcoes de conversao graus > radianos, seno, cosseno e calculo do t final
;       Entradas: Angulo em graus
;       Saidas: Angulo em radianos
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
PREPARE_BANANA: PUSH R0
                PUSH M[ANGLE]
                CALL DEG2RAD            ; Calculo do angulo em radianos
                POP M[ANGLE]            ; M[ANGLE] convertido em radianos na representacao 8/8bits
                                       
                PUSH R0
                PUSH M[ANGLE]           
                CALL SIN                ; Calculo do sin do angulo
                POP M[ANGLE_SIN]        ; Guardar o valor na memoria
        
                PUSH R0
                PUSH M[ANGLE]
                CALL COS                ; Calculo do cos do angulo
                POP M[ANGLE_COS]        ; Guardar o valor na memoria

                                        ; Calculo do tempo final da trajetoria
                MOV R1, M[VELOCITY]     ; R1 = v (16/0bits)
                ADD R1, R1              ; R1 = 2v (16/0bits)
                MOV R2, M[ANGLE_SIN]    ; R2 = sin x (8/8bits)
                MUL R2, R1              ; R1 = 2v * sin x (8/8bits)
        
                MOV R2, GRAVITY         ; R2 = g (8/8bits)
                SHR R2, 4               ; R2 = g (12/4bits)
                DIV R1, R2              ; R1 = (2v * sin x)/g (12/4bits)
                MOV M[RAND_SEED1], R1
                MOV M[RAND_SEED2], R2
                DEC M[RAND_SEED2]
        
                MOV R7, 0               ; R7 = t = 0 (tempo inicial)

                RET


;===============================================================================
;DEG2RAD: Rotina que converte um valor em graus para radianos
;       Entradas: Angulo em graus
;       Saidas: Angulo em radianos
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
DEG2RAD:MOV R1, M[SP+2]        
        MOV R2, RAD             ; Guardar uma copia dos 4 digitos menos significativos
        MUL R1, R2              ; Apos a multiplicacao dividir o resultado por 16^3, ou seja deslocar 
        MOV R3, R2              ; R1 4 bits para a esquerda e R2 12 bits para a direita e depois soma-los, 
        SHL R1, 4               ; Para obter o angulo em radianos na representacao em virgula fixa escolhida (8/8bits)
                                                    
        SHR R2, 12              ; Pegar nos três ultimos digitos hexadecimais que vao ser cortados 
        ADD R1, R2              ; Seguidos por um 0h, e no caso de ser maior ou igual a 8000h, fazer um
        SHL R3, 4               ; "Arredondamento", ou seja, adicionar 1h ao resultado final 
                                
        CMP R3, 8000h
        BR.NN ROUNDUP           ;Se o primeiro digito de R3 for maior ou igual a 8, somar 1 ao valor de R1

        MOV M[SP+3], R1
        RETN 1

;===============================================================================
;QUADRADO: Rotina auxiliar que calcula o valor do numero ao quadrado
;       Entradas: Numero
;       Saidas: Numero^2
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
QUADRADO:MOV R1, M[SP+2]
        MOV R2, R1
        MUL R1, R2
        MOV R3, R2             ; Guardar uma copia dos 4 digitos menos significativos
        SHL R1, 8              ; Apos a multiplicacao dividir o resultado por 16^2, ou seja deslocar 
                               ; R1 8 bits para a esquerda e R2 8 bits para a direita e depois soma-los, 
                               ; Para obter o angulo em radianos na representacao em virgula fixa escolhida
        SHR R2, 8              ; Pegar nos dois ultimos digitos hexadecimais que vao ser cortados 
        ADD R1, R2             ; Seguidos por 00h, e no caso de o numero ser maior ou igual a 8000h, fazer 
        SHL R3, 8              ; Um "arredondamento", ou seja, adicionar 1h ao resultado final 
        CMP R3, 8000h          ; Se o primeiro digito de R3 for maior ou igual a 8, 
        BR.NN ROUNDUP          ; Somar 1 ao valor de R1
             
        MOV M[SP+3], R1
        RETN 1

        ; Subrotina auxiliar de arredondamento
        ROUNDUP:INC R1
                MOV M[SP+3], R1
                RETN 1

;===============================================================================
;SIN: Rotina que calcula o valor do seno em radianos. Usa a funcao cos para calcular o valor do seno (4º comentario)
;       Entradas: angulo (rads)
;       Saidas: seno
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
SIN:    MOV R1, M[SP+2]         ; R1 = x
        MOV R2, 0192h           ; R2 = 90° em radianos
        SUB R2, R1              ; R2 =  90° - x
 
        PUSH R0 
        PUSH R2 
        CALL COS 
        POP R1                  ; cos(90° - x) = sin(x)

        MOV M[SP+3], R1
        RETN 1

;===============================================================================
;COS: Rotina que calcula o valor do cos em radianos. Usa as series de Taylor
;       Entradas: angulo (rads)
;       Saidas: cosseno
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
COS:    MOV R1, 0100h           ; 1 na representacao escolhida
        ADD M[SP+3], R1         ; RES = 1
        MOV R1, M[SP+2]         ; R1 = x
 
        PUSH R0 
        PUSH R1 
        CALL QUADRADO 
        POP R1                  ; R1 = x^2
 
        MOV R2, 2               ; 2! = 2
        DIV R1, R2              ; R1 = x^2/2
        SUB M[SP+3], R1         ; RES = 1 - x^2/2
        MOV R1, M[SP+2]         ; R1 = x
 
        PUSH R0 
        PUSH R1 
        CALL QUADRADO 
        POP R1                  ; R1 = x^2
        PUSH R0 
        PUSH R1 
        CALL QUADRADO 
        POP R1                  ; R1 = x^4
         
        MOV R2, 24              ; 4! = 24
        DIV R1, R2              ; R1 = x^4/24
        ADD M[SP+3], R1         ; RES = 1 - x^2/2 + x^4/24    

        RETN 1

;===============================================================================
;POS_X: Rotina que calcula o valor da posicao horizontal do projetil.
;       Entradas: tempo, velocidade, cosseno(angle)
;       Saidas: posicao horizontal
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
POS_X:  MOV R1, M[SP+2]         ; R1 = t (12/4)
        MOV R2, M[VELOCITY]     ; R2 = v (16/0)
        MUL R2, R1              ; R1 = v * t (12/4)
        MOV R2, M[ANGLE_COS]    ; R2 = cos(x) (8/8)
        MUL R2, R1 
        SHR R1, 12 
        SHL R2, 4               ; Apos deslocar R1 e R2 e soma-los, obtemos
        ADD R1, R2              ; R1 = v * t * cos(x) na representacao em virgula fixa 16/0bits
        MOV M[SP+3], R1
        RETN 1

;===============================================================================
;POS_Y: Rotina que calcula o valor da posicao vertical do projetil.
;       Entradas: tempo, velocidade, seno(angle), gravidade
;       Saidas: posicao vertical
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
POS_Y:  MOV R1, M[SP+2]         ; R1 = t (12/4)
        MOV R2, M[VELOCITY]     ; R2 = v (16/0)
        MUL R2, R1              ; R1 = v * t (12/4)
        MOV R2, M[ANGLE_SIN]    ; R2 = sin(x) (8/8)
        MUL R2, R1              ; R1 = v * t * sin(x) na representacao em virgula fixa 12/4bits
        SHR R1, 8
        SHL R2, 8
        ADD R1, R2              ; Apos deslocar R1 e R2 e soma-los, obtemos
                                ; R1 = v * t * sin(x) na representacao em virgula fixa 12/4bits
 
        MOV R2, M[SP+2]         ; R2 = t (12/4)
        MOV R3, R2              ; R3 = t (12/4)
        MUL R3, R2             
        SHL R3, 12
        SHR R2, 4
        ADD R2, R3              ; Apos deslocar R2 e R3 e soma-los, obtemos
                                ; R2 = t^2 na representacao em virgula fixa 12/4bits

        MOV R3, GRAVITY         ; R3 = G (8/8)
        MOV R4, 2        
        DIV R3, R4              ; R3 = G/2 (8/8)
 
        MUL R3, R2              
        SHR R2, 8       
        SHL R3, 8               ; Apos deslocar R2 e R3 e soma-los, obtemos
        ADD R2, R3              ; R2 = G/2 * T^2 na representacao em virgula fixa 12/4bits   

        SUB R1, R2              ; R1 = v * t * sin(x) - G/2 * T^2 (12/4)
        SHR R1, 4               ; R1 = v * t * sin(x) - G/2 * T^2 (16/0)

        MOV M[SP+3], R1
        RETN 1

;===============================================================================
;GET_POS: Rotina que chama as funcoes de calculo das posicoes x e y e atualiza na memoria os respetivos valores
;       Entradas: tempo (r7)
;       Saidas: posicao horizontal e vertical
;       Efeitos: Altera os respetivos valores no stack
;===============================================================================
GET_POS:PUSH R0
        PUSH M[SP+3]
        CALL POS_X
        POP M[POS_HORIZONTAL]   ; Armazena a posicao horizontal no dado t em memoria

        PUSH R0
        PUSH M[SP+3]
        CALL POS_Y
        POP M[POS_VERTICAL]     ; Armazena a posicao vertical no dado t em memoria

        RETN 1

;===============================================================================
; SUBZONA IV: Subrotinas de escrita na janela de texto
;===============================================================================

;===============================================================================
;DRAW_FLOOR: Rotina que escreve na janela de texto o "chao" onde vao ser colocados os gorilas
;       Entradas: ---
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
DRAW_FLOOR:     PUSH IGUAL              ; O caracter igual e passado como parametro de escrita
                CALL DRAW_CHAR

                INC M[CURSOR]                

                MOV R2, M[SP+2]         ; o valor da posicao final
                CMP M[CURSOR], R2
                BR.NZ DRAW_FLOOR        ; Escreve enquanto nao chegar ao caracter final

                RET

;===============================================================================
;DRAW_CHAR: Rotina que escreve na janela de texto um dado caracter no stack
;       Entradas: CARACTER M[SP+2], POSICAO M[CURSOR]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
DRAW_CHAR:      PUSH M[CURSOR]
                CALL UPDATE_CURSOR
                PUSH M[SP+2]
                CALL WRITE_CHAR

                RETN 1

;===============================================================================
;DRAW_STRING: Rotina que escreve na janela de texto uma cadeia de caracteres
;       Entradas: Primeiro caracter M[SP+3], POSICAO M[CURSOR]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
DRAW_STRING:    PUSH R1
                MOV R1, M[SP+3]                         ; Usa o R1 para percorrer todos os caracteres da cadeia

        ; Ciclo que percorre todos os caracteres a escrever
        DRAW_STRING_CICLO:      PUSH R2
                                MOV R2, LETRA_Z         ; Verifica se chegou ao caracter terminal - 'Z'

                                CMP M[R1], R2
                                POP R2

                                BR.Z DRAW_STRING_SKIP

                                PUSH M[R1]
                                CALL DRAW_CHAR

                                INC M[CURSOR]           ; Incrementa a posicao do caracter a escrever
                                INC R1                                               

                                BR DRAW_STRING_CICLO
                ; Sai da subrotina quando chegar ao ultimo
                DRAW_STRING_SKIP:       POP R1
                                        RETN 1

;===============================================================================
;CHECK_HIT_USED_POS: Verifica se a banana atingiu uma posicao ocupada por texto para evitar apagar caracteres
;       Entradas: Posicao da banana M[SP+5]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
CHECK_HIT_USED_POS:     PUSH R1
                        PUSH R2
                        PUSH R3

                        MOV R1, M[SP+5]
                        MOV R3, R0

        ; Percorre todos os caracteres ocupados e verifica se a banana atingiu algum deles
        CHECK_HIT_USED_POS_AUX: MOV R2, USED_POSITIONS
                                ADD R2, R3
                                CMP R1, M[R2]
                                JMP.Z BANANA_HIT_USED_POS       ; Caso seja um caracter que esteja ocupado, nao desenha a banana
                                INC R3
                                CMP R3, 30                      ; Percorrer os 30 caracteres usados para as caixas de texto
                                BR.NP CHECK_HIT_USED_POS_AUX

                                POP R3
                                POP R2
                                POP R1

                                RETN 1
        ; Nao desenhar banana quando a sua posicao coincide com posicao usada para texto
        BANANA_HIT_USED_POS:    POP R3          
                                POP R2
                                POP R1
                                POP R0
                                JMP BANANA_CYCLE

;===============================================================================
;DRAW_BANANA: Escreve a proxima posicao da banana
;       Entradas: Proxima posicao da banana M[SP+3]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
DRAW_BANANA:    PUSH R1
                MOV R1, M[SP+3]

                MOV M[LAST_POS], R1     ; Adiciona a variavel a memoria para depois permitir apagar
                MOV M[CURSOR], R1       ; Ajusta o cursor
                MOV M[IO_CONTROL], R1

                PUSH LETRA_O            ; Escreve a banana na posicao certa
                CALL DRAW_CHAR

                POP R1
                RETN 1

;===============================================================================
;ERASE_BANANA: Apaga a ultima posicao da banana
;       Entradas: Ultima posicao da banana M[LAST_POS]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
ERASE_BANANA:   PUSH R1
                MOV R1, M[LAST_POS]     ; Acede a ultima posicao da banana

                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH ESPACO             ; Escreve um valor em branco/espaco
                CALL DRAW_CHAR

                POP R1
                RET

;===============================================================================
;GET_HITPOINT: Rotina que adiciona a tabela as posicoes das partes do corpo do gorila
;       Entradas: Posicao da parte do corpo do gorila [R1]
;       Saidas: ---
;       Efeitos: Escreve na memoria
;===============================================================================
GET_HITPOINT:   MOV R2, M[CURSOR]
                MOV M[R1], R2
                INC R1
                RET

;===============================================================================
;DRAW_GORILLA: Rotina que escreve na janela de texto um gorila numa dada posicao
;       Entradas: Posicao da perna esquerda [SP+4]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
DRAW_GORILLA:   PUSH R1
                PUSH R2
                MOV R1, M[SP+4]

                CALL GET_HITPOINT       ; Escreve a perna esquerda
                PUSH BARRA_DIREITA
                CALL DRAW_CHAR

                MOV R7, M[CURSOR]       ; Posiciona o cursor
                MOV R6, 5
                ADD M[CURSOR], R6
                
                CALL GET_HITPOINT
                PUSH BARRA_ESQUERDA     ; Escreve a perna direita
                CALL DRAW_CHAR

                MOV M[CURSOR], R7       ; Posiciona o cursor
                MOV R6, 100h
                SUB M[CURSOR], R6

                CALL GET_HITPOINT
                PUSH BARRA_ESQUERDA     ; Escreve o braco esquerdo
                CALL DRAW_CHAR

                INC M[CURSOR]           ; Posiciona o cursor
                CALL GET_HITPOINT
                PUSH PARENTESES_E       ; Escreve o tronco do gorila
                CALL DRAW_CHAR

                INC M[CURSOR]           ; Posiciona o cursor
                CALL GET_HITPOINT
                PUSH PONTO              ; Escreve o peito do gorila
                CALL DRAW_CHAR

                INC M[CURSOR]           ; Posiciona o cursor
                CALL GET_HITPOINT
                PUSH PONTO              ; Escreve o peito do gorila
                CALL DRAW_CHAR

                INC M[CURSOR]           ; Posiciona o cursor
                CALL GET_HITPOINT
                PUSH PARENTESES_D       ; Escreve o tronco do gorila
                CALL DRAW_CHAR

                INC M[CURSOR]           ; Posiciona o cursor
                CALL GET_HITPOINT
                PUSH BARRA_DIREITA      ; Escreve o braco do direito
                CALL DRAW_CHAR

                MOV M[CURSOR], R7       ; Posiciona o cursor
                MOV R6, 0200h
                SUB M[CURSOR], R6
                MOV R6, 0002h
                ADD M[CURSOR], R6

                CALL GET_HITPOINT
                PUSH ASTERISCO          ; Escreve a cabeca/olhos
                CALL DRAW_CHAR

                INC M[CURSOR]
                CALL GET_HITPOINT       ; Escreve a cabeca/olhos
                PUSH ASTERISCO
                CALL DRAW_CHAR

                MOV M[CURSOR], R7

                POP R2
                POP R1
                RETN 1

;===============================================================================
;AWAIT_NUMBER: Rotina que corre sempre ate ser inserido um numero, backspace ou enter
;       Entradas: Posicao do caracter a ler/escrever [SP+2]
;       Saidas: ---
;       Efeitos: Recebe um numero e escreve na janela de texto
;===============================================================================
AWAIT_NUMBER:   PUSH R0
                CALL READCHAR           ; le o caracter
                POP R1
                CMP R1, 0008h           ; verifica se e backspace
                JMP.Z BACKSPACE

                CMP R1, 000Ah
                JMP.Z AN_RETURN         ; verifica se e enter

                MOV R6, M[SP+2]
                AND R6, 000Fh
                CMP R6, 0009h
                BR.Z CONTINUE           ; verifica se esta a escrever o 3 caracter. Se sim da return

                CMP R1, 0030h
                BR.N AWAIT_NUMBER

                CMP R1, 0039h
                BR.P AWAIT_NUMBER       ; verifica se e numero

                MOV R7, M[SP+2]
                MOV M[CURSOR], R7
                MOV M[IO_CONTROL], R7

                PUSH R1
                CALL DRAW_CHAR          ; escreve o caracter

        CONTINUE:      RETN 1

        ;Apaga o caracter na posicao anterior
        BACKSPACE:      INC M[IS_DELETE]        ; Passa para true a var que indica se se deu uma operacao delete
                        MOV R7, 0007h
                        MOV R6, M[SP+2]
                        AND R6, 000Fh
                        CMP R7, R6
                        BR.NN CONTINUE          ; Verifica se esta na posicao 1 (do primeiro digito). Se estiver nao faz nada (nao pode apagar os 2 pontos)

                        DEC M[SP+2]

                        MOV R7, M[SP+2]
                        MOV M[CURSOR], R7
                        MOV M[IO_CONTROL], R7

                        PUSH 007Fh
                        CALL DRAW_CHAR          ; Escreve o DEL/espaco branco

                        BR CONTINUE
                        
        AN_RETURN:      INC M[IS_RETURN]        ; Passa para true a var que indica se se deu uma operacao delete
                        JMP CONTINUE                        

;===============================================================================
;AWAIT_INPUT: Espera pelo input do dado valor escolhido previamente ao chamar a subrotina. 
;Recebe o input do utilizador e escreve em memoria.
;       Entradas: [SP+2] (angle ou velocity)
;       Saidas: Angulo ou velocidade
;       Efeitos: Escreve em memoria, espera input das teclas numericas ou botoes da placa
;===============================================================================
AWAIT_INPUT:    MOV R7, M[SP+2]
                SUB R7, 8000h                   ; Verifica se esta a receber o angulo ou velocidade
                INC R7
                MOV R6, 0100h
                MUL R6, R7
                ADD R7, 7
                PUSH R7
                CALL AWAIT_NUMBER               ; Fim da fase para receber o primeiro numero

                CMP M[IS_DELETE], R0            ; Delete sem numeros e ignorado
                BR.NP AWAIT_INPUT_AUX
                        
                DEC M[IS_DELETE]                ; Caso tenha sido a tecla backspace, decrementa a variavel "bool" e volta a esperar por input
                BR AWAIT_INPUT

; Auxiliar para receber os digitos seguintes
AWAIT_INPUT_AUX:        CMP M[IS_RETURN], R0            ; Enter sem numeros e ignorado
                        BR.NP AWAIT_INPUT_STAGE11

                        DEC M[IS_RETURN]                ; Caso tenha sido um entar decrementa a variavel "bool"
                        BR AWAIT_INPUT
                
        AWAIT_INPUT_STAGE11:    SUB R1, 0030h
                                MOV R7, M[SP+2]         ; Converte de codigo ascii para numero e escreve em memoria o primeiro digito
                                MOV M[R7], R1

        AWAIT_INPUT_STAGE12:    MOV R7, M[SP+2]         ; Verificacao se esta a receber o angulo ou a velocidade
                                SUB R7, 8000h
                                INC R7
                                MOV R6, 0100h          
                                MUL R6, R7
                                ADD R7, 8

                                PUSH R7
                                CALL AWAIT_NUMBER

                                CMP M[IS_RETURN], R0            ; Caso tenha sido enter acaba a subrotina
                                JMP.P AWAIT_INPUT_RETURN

                                CMP M[IS_DELETE], R0            ; Caso nao seja delete segue em frente na subrotina
                                BR.NP AWAIT_INPUT_STAGE21

                                DEC M[IS_DELETE]
                                
                                PUSH R2
                                MOV R2, 10
                                MOV R7, M[SP+3]                 ; Apaga o ultimo caracter
                                DIV M[R7], R2
                                POP R2

                                JMP AWAIT_INPUT
                                                                ; Fim da fase para o segundo caracter
        AWAIT_INPUT_STAGE21:    SUB R1, 0030h
                                PUSH R2
                                MOV R2, 10
                                MOV R7, M[SP+3]
                                MUL R2, M[R7]
                                ADD M[R7], R1
                                POP R2

        AWAIT_INPUT_STAGE22:    MOV R7, M[SP+2]                 ; Verificacao se esta a receber o angulo ou a velocidade
                                SUB R7, 8000h
                                INC R7
                                MOV R6, 0100h
                                MUL R6, R7
                                ADD R7, 9

                                PUSH R7
                                CALL AWAIT_NUMBER               ; Espera pelo 3o caracter que so podera ser enter ou backspace

                                CMP M[IS_RETURN], R0
                                BR.P AWAIT_INPUT_RETURN

                                CMP M[IS_DELETE], R0            ; Verifica o valor da variavel. Se for 1 volta atras, se for 0 continua
                                BR.NP AWAIT_INPUT_STAGE22

                                DEC M[IS_DELETE]

                                PUSH R2                         ; Apaga o ultimo caracter
                                MOV R2, 10
                                MOV R7, M[SP+3]
                                DIV M[R7], R2
                                POP R2

                                JMP AWAIT_INPUT_STAGE12         ; Fim da stage para o terceiro digito (ENTER ou DEL)

                AWAIT_INPUT_RETURN:     DEC M[IS_RETURN]        
                                        RETN 1 

;===============================================================================
;START_MENU: Desenha a mensagem de inicio de jogo e as barras superiores e inferior no ecra
;       Entradas: ---
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
START_MENU:     MOV R1, 1600h           ; Posicao para a penultima linha
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1                   
                PUSH 1651h              ; Passar o valor da ultima posicao

                CALL DRAW_FLOOR

                MOV R1, 0100h           ; Posicao para a penultima linha
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1                   
                PUSH 0151h              ; Passar o valor da ultima posicao

                CALL DRAW_FLOOR

                MOV R1, 0B19h           ; Posicao inicial
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                MOV R1, M[RESTART]
                CMP R1, R0
                BR.P START_MENU_1
                PUSH MENSAGEM_START
                BR START_MENU_2

START_MENU_1:   PUSH MENSAGEM_RESTART

START_MENU_2:   CALL DRAW_STRING

                POP R0
                POP R0
                MOV R7, R0

        START_CYCLE:    PUSH R0

                        ENI             ; Interrupcoes ativadas para receber os botoes

                        CALL READCHAR
                        POP R1

                        DSI             ; Desativadas pois nao e necessario usar botoes ou temporizador na proxima secao

                        CALL FILL_TABLE
                        
                        CMP R1, R0
                        BR.NP START_CYCLE

                        MOV R6, R1

                        MOV R1, M[COUNTER]
                        
                        MOV M[RANDOM_SEQUENCE], R1

                        PUSH R0
                        CALL RANDOM
                        POP M[GORILLA1_Y]

                        MOV M[RANDOM_SEQUENCE], R6

                        PUSH R0
                        CALL RANDOM

                        POP M[GORILLA2_Y]

                        RET
;===============================================================================
;CHECK_HIT: Verifica se a banana acertou num gorila
;       Entradas: Posicao da banana[SP+5], gorila a verificar [SP+6]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
CHECK_HIT:      PUSH R1
                PUSH R2
                PUSH R3
                MOV R1, M[SP+5]
                MOV R2, R0
                MOV R3, M[SP+6]
CHECK_HIT_AUX:  CMP R2, 10
                BR.NN CHECK_HIT_END
                CMP R1, M[R3]
                BR.Z HIT
                INC R2
                INC R3
                BR CHECK_HIT_AUX

CHECK_HIT_END:  POP R3
                POP R2
                POP R1
                RETN 2

; Caso tenha acertado aumenta o score consoante o gorila atingido
HIT:            INC M[IS_HIT]
                DEC M[HIT_PLAYER]
                CMP M[HIT_PLAYER], R0
                BR.Z HIT_SKIP                 ; Caso o jogador atingido seja o player2, passa a frente
                INC M[SCORE1]
                MOV R1, EEEEh
                MOV M[LAST_POS], R1        ; Reset a ultima posicao da banana
                BR HIT_CONTINUE

HIT_SKIP:       INC M[SCORE2]

HIT_CONTINUE:   POP R3
                POP R2
                POP R1
                POP R0

                CALL APAGA_ECRA
                CALL REDRAW_GORILLAS

                JMP END_TURN

;===============================================================================
;REFRESH_VALUE: Atualiza o valor numerico correspondente ao jogador ou a pontuacao (selecionado previamente)
; Mostra o score relativo ao jogador atual
;       Entradas: Localizacao na janela de texto [SP+2], valor a inserir [SP+3]
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
REFRESH_VALUE:  MOV R1, M[SP+2]
                MOV M[CURSOR], R1
                
                MOV R1, M[SP+3]
                MOV R1, M[R1]
                ADD R1, 30h

                PUSH R1
                CALL DRAW_CHAR

                RET
;===============================================================================
;APAGA_ECRA: Apaga todos os caracteres da zona de jogo ou todo o ecra
;       Entradas: Variavel true/false que verifica quanto do ecra apaga
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
APAGA_ECRA:     PUSH R1

                CMP M[APAGA_TUDO], R0
                BR.Z AE_SKIP1
                MOV R1, 0000h                ; Caso apaga_tudo seja true comeca na linha 0000
                SUB R1, 100h
                BR A_E_CICLO
AE_SKIP1:       MOV R1, 0200h

A_E_CICLO:      ADD R1, 100h
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH LINHA_BRANCA

                CALL DRAW_STRING

                CMP M[APAGA_TUDO], R0
                BR.NZ AE_SKIP2

                CMP R1, 1500h
                BR.NZ A_E_CICLO

                BR AE_ACABA

AE_SKIP2:       CMP R1, 2300h
                BR.NZ A_E_CICLO

AE_ACABA:       POP R1
                RET    

;===============================================================================
;REDRAW_GORILLAS: Volta a posicionar aleatoriamente os gorilas depois de ser pontuado
;       Entradas: RAND_SEED1, RAND_SEED2
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
REDRAW_GORILLAS:        MOV R1, 1505h                   ; Posiciona os gorilas nas suas posicoes inciiais
                        MOV M[GORILLA1_POS], R1         
                        MOV R1, 1540h
                        MOV M[GORILLA2_POS], R1

                        MOV R1, M[RAND_SEED1]           ; Gera os valores aleatorios
                        MOV M[RANDOM_SEQUENCE], R1

                        PUSH R0
                        CALL RANDOM
                        POP M[GORILLA1_Y]               ; Guarda a posicao aleatoria do gorila 1 

                        MOV R1, M[RAND_SEED2]           ; Gera os valores aleatorios
                        MOV M[RANDOM_SEQUENCE], R1

                        PUSH R0
                        CALL RANDOM
                        POP M[GORILLA2_Y]               ; Guarda a posicao aleatoria do gorila 2

                        MOV R1, M[GORILLA1_POS]         ; Posiciona os gorilas aleatoriamente
                        MOV R2, 100h
                        MUL R2, M[GORILLA1_Y]
                        SUB R1, M[GORILLA1_Y]
                        MOV M[GORILLA1_POS], R1
                        MOV M[CURSOR], R1
                        MOV M[IO_CONTROL], R1

                        PUSH GORILLA1_HITBOX            
                        CALL DRAW_GORILLA

                        MOV R1, M[GORILLA2_POS]
                        MOV R2, 100h
                        MUL R2, M[GORILLA2_Y]
                        SUB R1, M[GORILLA2_Y]
                        MOV M[GORILLA2_POS], R1
                        MOV M[CURSOR], R1
                        MOV M[IO_CONTROL], R1

                        PUSH GORILLA2_HITBOX
                        CALL DRAW_GORILLA

                        RET
;===============================================================================
;START_GAME: Posiciona os jogadores e desenha o chao
;       Entradas: ---
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
START_GAME:     CALL PREPARE_CONTROL

RESTART_GAME:   CALL START_MENU

                MOV R1, 0B19h           ; Posicao inicial
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH LINHA_BRANCA

                CALL DRAW_STRING

                MOV R1, 0919h           ; Posicao inicial
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH LINHA_BRANCA

                CALL DRAW_STRING

                MOV R1, 0100h           ; Posicao inicial
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH LINHA_BRANCA

                CALL DRAW_STRING
                
                MOV R1, M[GORILLA1_POS] ; Posiciona o gorila 1
                MOV R2, 100h
                MUL R2, M[GORILLA1_Y]
                SUB R1, M[GORILLA1_Y]
                MOV M[GORILLA1_POS], R1
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH GORILLA1_HITBOX
                CALL DRAW_GORILLA
                
                MOV R1, M[GORILLA2_POS] ; Posiciona o gorila 2
                MOV R2, 100h
                MUL R2, M[GORILLA2_Y]
                SUB R1, M[GORILLA2_Y]
                MOV M[GORILLA2_POS], R1
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH GORILLA2_HITBOX 
                CALL DRAW_GORILLA

                MOV R1, 0101h          
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_ANGLE     ; Posiciona o texto relativo ao angulo

                CALL DRAW_STRING
                
                MOV R1, 0201h          
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_SPEED      ; Posiciona o texto relativo a velocidade

                CALL DRAW_STRING

                MOV R1, 0023h          
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_SCORE     ; Posiciona o texto relativo ao score

                CALL DRAW_STRING

                MOV R1, 0001h          
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_PLAYER    ; Posiciona o texto relativo ao jogador

                CALL DRAW_STRING

                RET

;===============================================================================
;CLEAR_INPUT: Troca os valores inseridos previamente pelo utilizador por valores em branco
;       Entradas: ---
;       Saidas: ---
;       Efeitos: Desenha na janela de texto
;===============================================================================
CLEAR_INPUT:    MOV R1, 0107h           ;apagar angle
                MOV M[CURSOR], R1
                PUSH ESPACO
                CALL DRAW_CHAR

                INC M[CURSOR]
                PUSH ESPACO
                CALL DRAW_CHAR

                MOV R1, 0207h           ;apagar speed
                MOV M[CURSOR], R1
                PUSH ESPACO
                CALL DRAW_CHAR

                INC M[CURSOR]
                PUSH ESPACO
                CALL DRAW_CHAR

                RET

;===============================================================================
;GET_USED_POS: Preenche uma tabela com as posicoes ocupadas
;       Entradas: ---
;       Saidas: USED_POSITIONS
;       Efeitos: Preenche uma tabela em memoria
;===============================================================================
GET_USED_POS:   PUSH R1
                PUSH R2
                PUSH R3

                MOV R1, USED_POSITIONS

                PUSH 0001h              ; Posicoes relativas ao player
                PUSH R1
                PUSH 7
                CALL GET_USED_POS_AUX  

                MOV R1, USED_POSITIONS
                ADD R1, 7               ; 7 posicoes ja estao ocupadas

                PUSH 0023h              ; Posicoes relativas ao score
                PUSH R1
                PUSH 7
                CALL GET_USED_POS_AUX

                MOV R1, USED_POSITIONS
                ADD R1, 14              ; 7 + 7 = 14 posicoes ja estao ocupadas

                PUSH 0101h              ; Posicoes relativas ao angulo
                PUSH R1
                PUSH 8
                CALL GET_USED_POS_AUX

                MOV R1, USED_POSITIONS
                ADD R1, 22              ; 7 + 7 + 8 = 22 posicoes ja estao ocupadas

                PUSH 0201h              ; Posicoes relativas a speed
                PUSH R1
                PUSH 8
                CALL GET_USED_POS_AUX

                POP R3
                POP R2
                POP R1
                RET
        
        GET_USED_POS_AUX:  MOV R3, R0           ; Preenche M[SP+2] valores da tabela USED_POSITIONS seguidos
        GET_USED_POS_AUX_1:MOV R1, M[SP+3]      ; Posicao da tabela USED_POSITIONS a partir da qual os valores sao preenchidos
                           MOV R2, M[SP+4]      ; Primeira posicao a copiar
                           ADD R1, R3
                           ADD R2, R3
                           MOV M[R1], R2
                           INC R3
                           CMP R3, M[SP+2]      ; R3 e o iterador e M[SP+2] e o numero de vezes que o ciclo vai correr
                           BR.N GET_USED_POS_AUX_1
                           RETN 3 

;===============================================================================
; SUBZONA V: SUBROTINAS PRINCIPAL 
;===============================================================================
START:          MOV R7, SP_INIC
                MOV SP, R7

                MOV R7, INT_MASK                ; Inicializacao das interrupcoes
                MOV M[MASK_ADDR], R7          

                CALL START_GAME
                MOV M[COUNTER], R0

                CALL GET_USED_POS

CONTINUA:       CALL CLEAR_INPUT
                
                MOV R1, 1
                CMP R1, M[CURRENT_PLAYER]       ; Verifica qual o jogador
                BR.Z UPDATE_SCORE1
                PUSH SCORE2
                BR UPDATE_SCORE2
UPDATE_SCORE1:  PUSH SCORE1
UPDATE_SCORE2:  PUSH 0029h  
                CALL REFRESH_VALUE
                PUSH CURRENT_PLAYER
                PUSH 0007h
                CALL REFRESH_VALUE

                ENI

                PUSH ANGLE                      ; Esperar pelo input do utilizador - velocidade
                CALL AWAIT_INPUT
                
                MOV R1, M[ANGLE]
                CMP R1, 90                      ; Garantir que o angulo e menor ou igual a 90 graus
                JMP.P CONTINUA      

                PUSH VELOCITY                   ; Esperar pelo input do utilizador - velocidade
                CALL AWAIT_INPUT        

                CALL PREPARE_BANANA
                MOV R1, M[GORILLA1_POS]         ; Calculo das posicoes iniciais das bananas
                SUB R1, 0200h
                ADD R1, 0004h
                MOV M[POS_BANANA1], R1

                MOV R1, M[GORILLA2_POS]
                SUB R1, 0200h
                MOV M[POS_BANANA2], R1

                DSI

                MOV R7, TICKS_SEC               ; Inicializacao de contador associado ao timer
                MOV M[TIMER_COUNT_ADDR],  R7
               
                MOV R7, TIMER_STATE             ; Inicializacao o timer
                MOV M[TIMER_CTRL_ADDR], R7  

                ENI

                MOV M[COUNTER], R0

BANANA_CYCLE:   MOV R1, M[COUNTER]
                MOV R2, M[PREV_COUNTER]
                CMP R1, R2
                BR.Z BANANA_CYCLE
                
                MOV M[PREV_COUNTER], R1

                PUSH R1                        
                CALL GET_POS

                MOV R2, M[CURRENT_PLAYER]
                DEC R2
                ADD R2, POS_BANANA1
                MOV R1, M[R2]
                MOV R2, M[POS_HORIZONTAL]

                CMP R2, R0
                JMP.N END_TURN

                MOV R7, M[CURRENT_PLAYER]
                DEC R7
                CMP R7, R0
                BR.NZ BANANA_CYCLE_SKIP1
                ADD R1, R2
                BR BANANA_CYCLE_CONTINUE
BANANA_CYCLE_SKIP1:     SUB R1, R2              ; Verifica qual o jogador de modo a efetuar a trajetoria da forma correta (somar ou subtrair aos valores das colunas)
BANANA_CYCLE_CONTINUE:  MOV R2, M[POS_VERTICAL]
                        MOV R3, 100h
                        MUL R3, R2
                        SUB R1, R2

                CALL ERASE_BANANA

                MOV R2, R1
                AND R2, FF00h
                CMP R2, 1500h                   ; 16 e o nivel do chao
                JMP.P END_TURN                  ; bateu no chao, volta ao inicio
                MOV R2, R1
                AND R2, 00FFh
                CMP R2, 004Fh
                JMP.P END_TURN                  ; saiu pelo lado direito volta ao inicio

                INC M[HIT_PLAYER]
                PUSH GORILLA1_HITBOX
                PUSH R1                         ; Posicao
                CALL CHECK_HIT                  ; com gorila

                INC M[HIT_PLAYER]
                PUSH GORILLA2_HITBOX
                PUSH R1                         ; Posicao
                CALL CHECK_HIT                  ; com gorila

                MOV M[HIT_PLAYER], R0

                PUSH R1
                CALL CHECK_HIT_USED_POS         ; com texto
                
                PUSH R1
                CALL DRAW_BANANA
                
                JMP BANANA_CYCLE             

END_TURN:       DSI

                MOV R7, R0                      ; Faz reset ao temporizador para a interrupcao nao coincidir com o carregar nos botoes
                MOV M[TIMER_CTRL_ADDR], R7  

                MOV R7, R0              
                MOV M[TIMER_COUNT_ADDR],  R7   

                MOV R7, M[SCORE1]
                MOV R1, 0003h
                CMP R7, R1

                BR.Z CHECK_WINNER1
                BR CHECK_WINNER2
CHECK_WINNER1:  INC M[APAGA_TUDO]
                CALL APAGA_ECRA

                MOV R1, 091Fh           
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_VENCEDOR1
                CALL DRAW_STRING

                CALL END_GAME

CHECK_WINNER2:  MOV R7, M[SCORE2]
                MOV R1, 0003h
                CMP R7, R1
                BR.NZ SKIP_CHECK                
                
                INC M[APAGA_TUDO]
                CALL APAGA_ECRA

                MOV R1, 091Fh           
                MOV M[CURSOR], R1
                MOV M[IO_CONTROL], R1

                PUSH MENSAGEM_VENCEDOR2
                CALL DRAW_STRING

                CALL END_GAME

SKIP_CHECK:     MOV R7, 1
                CMP M[CURRENT_PLAYER], R7                
                BR.NZ END_TURN_SKIP             ; Se for o jogador 2 da skip
                INC M[CURRENT_PLAYER]
                BR END_TURN_CONTINUE

END_TURN_SKIP:  DEC M[CURRENT_PLAYER]

END_TURN_CONTINUE:      MOV M[COUNTER], R0
                        MOV R7, SP_INIC
                        MOV SP, R7
                        JMP CONTINUA

END_GAME:       MOV R7, SP_INIC
                MOV SP, R7
                MOV R7, 0001h
                MOV M[RESTART], R7
                MOV R6, M[FIRST_PLAYER]         ; Alternar qual dos gorilas e o primeiro a jogar
                CMP R6, R7                      ; R7 = 1
                BR.Z END_GAME_AUX               
                MOV M[FIRST_PLAYER], R7         ; Se o segundo a jogar foi o primeiro
                MOV R7, M[FIRST_PLAYER]
                MOV M[CURRENT_PLAYER], R7
                BR END_GAME_FIM
END_GAME_AUX:   INC M[FIRST_PLAYER]             ; Se o primeiro a jogar foi o primeiro
                MOV R7, M[FIRST_PLAYER]
                MOV M[CURRENT_PLAYER], R7

END_GAME_FIM:   MOV M[COUNTER], R0
                MOV M[SCORE1], R0
                MOV M[SCORE2], R0
                MOV M[ITERADOR], R0
                MOV M[APAGA_TUDO], R0
                CALL RESTART_GAME
                JMP CONTINUA