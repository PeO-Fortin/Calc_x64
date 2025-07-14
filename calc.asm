; Calculatrice
; Pierre-Olivier Fortin
;
; Ce programme effectue des opérations entières de base sur des nombres positifs.
; Les débordements ne sont pas gérés par le programme.
; Les priorités d'opérations ne sont pas gérés par le programme.

section .data
total   DQ 0                                ; conteneur du total de l'operation
chiflu  DQ 0                                ; conteneur du chiffre lu
operat  DB 0                                ; conteneur de l'operateur
bool    DB 0                                ; conteneur du verificateur de chiffre lu

newline: DB 0x0A                            ; \n
number_buffer: times 20 DB 0                ; conteneur pour affichage du total

; Messages d'erreur complets
err_msg0: DB 'E0'                           ; Erreur caractère invalide
err_msg1: DB 'E1'                           ; Erreur soustraction négative
err_msg2: DB 'E2'                           ; Erreur division par zéro

section .text
global _start

_start:

lire:   mov RAX, 0                          ; syscall: read
        mov RDI, 0                          ; syscall $1, entree standard
        push 0                              ; le byte lu sera sur le top du stack
        mov RSI, RSP                        ; syscall $2, addresse pour les bytes lus
        mov RDX, 1                          ; syscall $3, nombre de bytes a lire
        syscall
        pop RBX
        
	;Vérification des espaces blancs
        cmp BL, ' '
        je lire
        cmp BL, 0x09
        je lire
        cmp BL, 0x0A
        je lire
        cmp BL, 0x0D
        je lire
	
	;Vérification des chiffres
        cmp BL, '0'
        jl oper
        cmp BL, '9'
        jg oper
	
	;if (caractère = chiffre) {
        sub BL, 0x30                        ; Transformation du caractère en entiers
        mov byte[bool], 1 	           ; Boolean = chiffre trouvé
	
	;Gestion des dizaines
        mov RAX, qword[chiflu]
        mov RDX, 10
        imul RAX, RDX
        movzx RDX, BL
        add RAX, RDX
        mov qword[chiflu], RAX
	
        cmp byte[operat], 0
        jne lire 		          ; Si le nombre est le premier de l'opération {
        mov RAX, qword[chiflu]	          ; Chiffre lu = total
        mov qword[total], RAX               ; }
        jmp lire 			  ;      }
	
oper:	cmp byte[bool], 0
        je eChar 		          ;Erreur si aucun chiffre lu avant l'opérateur
	
	;Exécution de l'opération en mémoire
	cmp byte[operat], '+'
	je addit
	cmp byte[operat], '-'
	je sous
	cmp byte[operat], '*'
	je mult
	cmp byte[operat], '/'
	je divi
	cmp byte[operat], '%'
	je divi
	
	mov qword[chiflu], 0 		 ;Réinitialisation du conteneur de chiffre lu
	mov byte[bool], 0 		 ;Réinitialisation du boolean de chiffre lu
	
	;Vérification des opérateurs
	cmp BL, '='
	je egal
	cmp BL, 'q'
	je egal
	
	cmp BL, '+'
	jne valSub
	mov byte[operat], BL
	jmp lire

valSub:	cmp BL, '-'
	jne valMul
	mov byte[operat], BL
	jmp lire

valMul:	cmp BL, '*'
	jne valDiv
	mov byte[operat], BL
	jmp lire
	
valDiv:	cmp BL, '/'
	jne valMod
	mov byte[operat], BL
	jmp lire
	
valMod:	cmp BL, '%'
	jne eChar 	                  ;Erreur si caractère invalide
	mov byte[operat], BL
	jmp lire

;***Section de l'exécution des opérations***

addit:  mov RDX, qword[chiflu]
        add qword[total], RDX 	           ;Addition au total
        jmp finOpe

sous:   mov RDX, qword[chiflu]
        cmp RDX, qword[total]
        jg eSous            	            ;Erreur si le résultat sera négatif
        sub qword[total], RDX 	            ;Soustraction au total
        jmp finOpe

mult:	mov RDX, qword[chiflu]
        mov RAX, qword[total]
        imul RAX, RDX                        ; Multiplication au total
        mov qword[total], RAX        
        jmp finOpe

divi:   cmp qword[chiflu], 0
        je eDiv 		                    ;Erreur si divison par 0
        mov RAX, qword[total]
        mov RDX, 0
        idiv qword[chiflu]
        cmp byte[operat], '/'
        je findiv
        mov qword[total], RDX                ; if (operateur == "%") {total = restant}
        jmp finOpe
        
findiv: mov qword[total], RAX                ; if (operateur == "/") {total = quotient}
        jmp finOpe

finOpe:	mov byte[operat], 0		   ;Réinitialisation du conteneur d'opérateur
	jmp oper

egal:	mov byte[operat], BL 	            ;Sauvegarde l'opérateur '=' ou 'q'
	
        call print_int
        
        mov RAX, 1                          ; syscall: write
        mov RDI, 1                          ; syscall $1, sortie standard
        mov RSI, newline                    ; syscall $2, "\n"
        mov RDX, 1                          ; syscall $3, nombre de bytes a ecrire
        syscall
	
	cmp byte[operat], 'q'
	je fin      	                   ;if (opérateur != 'q') {

        ; Reinitialisation des conteneurs
        mov qword[total], 0
        mov qword[chiflu], 0
        mov byte[operat], 0
        mov byte[bool], 0
        
        jmp lire 		           ; }

;***Section des erreurs***

;Erreur caractère invalide
eChar:	mov RAX, 1                          ; syscall write
        mov RDI, 1                          ; sortie standard
        mov RSI, err_msg0                   ; message "E0"
        mov RDX, 2                          ; longueur du message
        syscall
        jmp fin                             ; Fin du programme si E0

;Erreur soustraction avec résultat < 0
eSous:	mov RAX, 1                          ; syscall write
        mov RDI, 1                          ; sortie standard
        mov RSI, err_msg1                   ; message "E1"
        mov RDX, 2                          ; longueur du message
        syscall
        jmp nxtOpe                          ; Ignorer le reste de l'opération

;Erreur division par 0
eDiv:	mov RAX, 1                          ; syscall write
        mov RDI, 1                          ; sortie standard
        mov RSI, err_msg2                   ; message "E2"
        mov RDX, 2                          ; longueur du message
        syscall
        jmp nxtOpe                          ; Ignorer le reste de l'opération
	
;Ignorer le reste de l'opération
nxtOpe:	cmp BL, '='
	je finNxtOpe 	                   ;if (caractère != '=') {
	cmp BL, 'q'
	je fin      	                   ; } else if (caractère != 'q') {
	cmp BL, -1
	je fin      	                   ; } else if (caractère != fin de l'input) {
        
        mov RAX, 0                          ; syscall: read
        mov RDI, 0                          ; syscall $1, entree standard
        push 0                              ; le byte lu sera sur le top du stack
        mov RSI, RSP                        ; syscall $2, addresse pour les bytes lus
        mov RDX, 1                          ; syscall $3, nombre de bytes a lire
        syscall
        pop RAX
        mov RBX, RAX
        
        jmp nxtOpe 		           ; }

;Reprendre le déroulement normal du programme
finNxtOpe:
        mov RAX, 1                          ; syscall: write
        mov RDI, 1                          ; syscall $1, sortie standard
        mov RSI, newline                    ; syscall $2, "\n"
        mov RDX, 1                          ; syscall $3, nombre de bytes a ecrire
        syscall
        
        mov qword[total], 0
        mov qword[chiflu], 0
        mov byte[operat], 0
        mov byte[bool], 0
        jmp lire

print_int:
    mov RAX, qword[total]
    mov RCX, 10
    mov RDI, number_buffer + 19             ; fin du buffer
    mov byte[RDI], 0                        ; fin de la chaine de caracteres
    
convert_loop:
    dec RDI
    mov RDX, 0
    div RCX                                 ; RAX = RAX / 10, RDX = RAX % 10
    add DL, '0'                             ; convertir en ASCII
    mov byte[RDI], DL
    test RAX, RAX
    jnz convert_loop
    
    ; Calculer la longueur
    mov RAX, number_buffer + 19
    sub RAX, RDI
    mov RDX, RAX                            ; syscall $3, longueur
    
    ; Afficher
    mov RAX, 1                              ; syscall: write
    mov RSI, RDI                            ; syscall $2, début de la chaîne
    mov RDI, 1                              ; syscall $1, sortie standard
    syscall
    ret

;Fin du programme
fin:    mov RAX, 60                         ; syscall: exit
        mov RDI, 0                          ; exit code
        syscall