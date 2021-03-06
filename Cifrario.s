#
# Titolo:       Cifrario.s
# Autore:       Leonardo Buoncompagni (leonardo.buoncompagni@stud.unifi.it)
# Data:         03/09/2019
#

.data
  error_io_msg: .asciiz "Si e' verificato un errore durante un'operazione di I/O. \n"
  error_key_msg: .asciiz "La chiave di cifratura puo' contenere solamente i caratteri 'A', 'B', 'C', 'D', 'E'. \n"

  key_path: .asciiz "chiave.txt"
  key_buffer: .space 5

  plaintext_path: .asciiz "messaggio.txt"
  encrypted_path: .asciiz "messaggioCifrato.txt"
  decrypted_path: .asciiz "messaggioDecifrato.txt"

  input_buffer: .space 4096
  output_buffer: .space 4096
  temp_buffer: .space 4096
  enum_chars: .space 256

.text
.globl main
main:
  la $a0, plaintext_path
  li $a2, 128
  jal read_file
  jal read_key

  move $a0, $s0
  move $a1, $s2
  jal cipher_loop

  la $a0, encrypted_path
  jal write_file

decipher:
  la $a0, encrypted_path
  li $a2, 4096
  jal read_file
  jal read_key

  move $a0, $s0
  move $a1, $s2
  jal decipher_loop

  la $a0, decrypted_path
  jal write_file

exit:
  li $v0, 10
  syscall


###############################################################################################################################
## 1) Lettura dei primi $a2 caratteri di un file contenuto in $a0;
##    Indirizzo del buffer salvato in $s0, lunghezza del messaggio in $s1.
###############################################################################################################################
read_file:
    # Apro il file.
  li $v0, 13
  li $a1, 0                                     # flags (0 = read-only)
  syscall
  blt $v0, $zero, error_io

    # Leggo il file.
  move $a0, $v0                                 # descrittore del file
  li $v0, 14
  la $a1, input_buffer                          # buffer
  syscall
  bltz $v0, error_io

  la $s0, input_buffer                          # $s0 = indirizzo del messaggio letto
  move $s1, $v0                                 # $s1 = lunghezza del messaggio letto

    # Chiudo il file.
  li $v0, 16
  syscall

  jr $ra

###############################################################################################################################
## 2) Lettura della chiave di cifratura, o inversione di quest'ultima se gia' letta;
##    Indirizzo del buffer salvato in $s2, lunghezza della chiave in $s3.
###############################################################################################################################
read_key:
  bne $s2, $zero, reverse_key                   # se la chiave e' gia' stata caricata, allora siamo in fase di decifratura
    # Apro il file.
  li $v0, 13
  la $a0, key_path                              # percorso del file
  li $a1, 0                                     # flags (0 = read-only)
  syscall
  blt $v0, $zero, error_io

    # Leggo il file.
  move $a0, $v0                                 # descrittore del file
  li $v0, 14
  la $a1, key_buffer                            # buffer
  li $a2, 4                                     # numero di caratteri da leggere
  syscall
  bltz $v0, error_io

  la $s2, key_buffer                            # $s2 = indirizzo della chiave letta
  move $s3, $v0                                 # $s3 = lunghezza della chiave letta

    # Chiudo il file.
  li $v0, 16
  syscall

  jr $ra

reverse_key:
  li $t0, 0
  addi $t1, $s3, -1

  reverse_key_loop:
    add $t2, $s2, $t0
    add $t3, $s2, $t1

    lb $t4, 0($t2)
    lb $t5, 0($t3)

    add $t6, $s2, $t0
    add $t7, $s2, $t1

    sb $t4, 0($t7)
    sb $t5, 0($t6)

    addi $t0, $t0, 1
    addi $t1, $t1, -1
    ble $t0, $t1, reverse_key_loop

  jr $ra

###############################################################################################################################
##  3) Lettura iterativa dei caratteri della chiave con conseguente
##     applicazione dei corrispondenti algoritmi di cifratura.
###############################################################################################################################
cipher_loop:
  lb $t0, 0($a1)                                # $t0 = prossimo carattere della chiave
  beq $t0, 0x00, cipher_exit                    # termina il ciclo una volta raggiunto il carattere nullo
  blt $t0, 0x41, error_key                      # la chiave deve essere composta soltanto dai caratteri 'A', 'B', 'C', 'D', 'E'
  bgt $t0, 0x45, error_key

  la $s7, output_buffer
  beq $t0, 0x41, cipher_a
  beq $t0, 0x42, cipher_b
  beq $t0, 0x43, cipher_c
  beq $t0, 0x44, cipher_d
  beq $t0, 0x45, cipher_e
cipher_next:
  move $a0, $v0
  addi $a1, $a1, 1                              # incremento l'indirizzo della chiave
  j cipher_loop
cipher_exit:
  jr $ra

###############################################################################################################################
##  4) Salvataggio dei contenuti di output_buffer in un file $a0.
###############################################################################################################################
write_file:
    # Apro il file.
  li $v0, 13
  li $a1, 1
  syscall

    # Scrivo sul file.
  move $a0, $v0
  li $v0, 15
  la $a1, output_buffer
  move $a2, $s1
  syscall

    # Chiudo il file.
  li $v0, 16
  syscall

  jr $ra

###############################################################################################################################
##  5) Applicazione degli algoritmi di decifratura in ordine inverso per risalire al messaggio originale.
###############################################################################################################################
decipher_loop:
  lb $t0, 0($a1)
  beq $t0, 0x00, decipher_exit                  # e' assunto che la chiave sia semanticamente valida poiche'
                                                # il controllo e' eseguito durante la fase di cifratura
  la $s7, output_buffer
  beq $t0, 0x41, decipher_a
  beq $t0, 0x42, decipher_b
  beq $t0, 0x43, decipher_c
  beq $t0, 0x44, decipher_d
  beq $t0, 0x45, decipher_e
decipher_next:
  move $a0, $v0
  addi $a1, $a1, 1                              # incremento l'indirizzo della chiave
  j decipher_loop
decipher_exit:
  jr $ra


###############################################################################################################################


cipher_a:
  li $a2, 0                                     # $a2 = numero di caratteri iniziali da ignorare
  li $a3, 0                                     # $a3 = numero di caratteri da ignorare dopo ogni iterazione
  li $s6, 4                                     # $s6 = spostamento del singolo carattere (positivo = cifratura)
_cipher_a:
  beq $a2, $zero, cipher_a_loop
  addi $a2, $a2, -1
  addi $a0, $a0, 1
  lb $t0, 0($a0)
  sb $t0, 0($s7)
  addi $s7, $s7, 1                              # ignora $a3 caratteri

  cipher_a_loop:
    lb $t0, 0($a0)                              # $t0 = prossimo carattere del messaggio
    bge $t0, $s1, cipher_a_exit                 # termina il ciclo

    add $t0, $t0, $s6
    div $t0, $t0, 256
    mfhi $t0                                    # $t0 = ($t0 +- 4) % 256
    sb $t0, 0($s7)                              # salvo il carattere su output_buffer

    addi $a0, $a0, 1                            # passo al prossimo carattere
    addi $s7, $s7, 1                            # incremento l'indirizzo del buffer

    beq $a3, $zero, cipher_a_next
    lb $t0, 0($a0)
    sb $t0, 0($s7)
    add $a0, $a0, $a3
    add $s7, $s7, $a3
  cipher_a_next:
    j cipher_a_loop
  cipher_a_exit:
    la $v0, output_buffer                       # $v0 = indirizzo del messaggio cifrato
    bgt $s6, $zero, cipher_next                 # $s6 positivo indica che sto cifrando
  j decipher_next

cipher_b:
  li $a2, 0
  li $a3, 1
  li $s6, 4
  j _cipher_a

cipher_c:
  li $a2, 1
  li $a3, 1
  li $s6, 4
  j _cipher_a

cipher_d:
  li $a2, 0
_cipher_d:
  li $t0, 0                                     # i
  addi $t1, $s1, -1                             # j = str_len - 1

  cipher_d_loop:
    add $t2, $a0, $t0
    add $t3, $a0, $t1

    lb $t4, 0($t2)                              # $t4 = msg[i]
    lb $t5, 0($t3)                              # $t5 = msg[j]

    add $t6, $s7, $t0
    add $t7, $s7, $t1

    sb $t4, 0($t7)                              # msg[j] = msg[i]
    sb $t5, 0($t6)                              # msg[i] = msg[j]

    addi $t0, $t0, 1                            # i++
    addi $t1, $t1, -1                           # j--

    ble $t0, $t1, cipher_d_loop
    la $v0, output_buffer
    beq $a2, $zero, cipher_next
  j decipher_next

cipher_e:
  li $t0, 0       # i
  li $t1, 0       # j
  li $t2, 0       # k
  la $t3, enum_chars
  la $s7, temp_buffer

  cipher_e_loop:
    bge $t0, $s1, cipher_e_exit                 # if i >= str_len exit loop
    move $t1, $t0                               # j = i
    add $t2, $a0, $t0                           # $t2 = &str[i]
    lb $a2, 0($t2)                              # $a2 = str[i]

    add $t4, $t3, $a2                           # $t4 = &enum_chars + &str[i]
    lb $s4, 0($t4)
    beq $a2, $s4, cipher_e_next                 # se il carattere e' gia' stato visitato, salta al prossimo
    sb $a2, 0($t4)                              # altrimenti inseriscilo in enum_chars
    li $t4, 0
    li $s4, 0                                   # ripristino i registri
    sb $a2, 0($s7)
    addi $s7, $s7, 1
    li $t2, 0

    find_char:
      bge $t1, $s1, find_char_exit              # if j >= str_len exit loop
      add $t4, $a0, $t1                         # $t4 = &str[j]
      lb $a3, 0($t4)                            # $a3 = str[j]
      bne $a2, $a3, find_char_next              # if str[i] != str[j] salta al prossimo

      move $s6, $t1                             # j viene copiato
      li $t4, 45
      sb $t4, 0($s7)
      addi $s7, $s7, 1                          # aggiungo il carattere "-"

      ce_push_index:
        addi $sp, $sp, -1
        div $t4, $s6, 10
        mfhi $t4                                # j % 10
        addi $t4, $t4, 48
        sb $t4, 0($sp)
        div $s6, $s6, 10                        # j / 10
        addi $t2, $t2, 1                        # k++
        beq $s6, $zero, ce_pop_index
        j ce_push_index

      ce_pop_index:
        lb $t4, 0($sp)
        sb $t4, 0($s7)
        addi $s7, $s7, 1
        addi $t2, $t2, -1                       # k--
        addi $sp, $sp, 1
        beq $t2, $zero, find_char_next
        j ce_pop_index

    find_char_next:
      addi $t1, $t1, 1                          # j++
      j find_char
    find_char_exit:
      li $t4, 32
      sb $t4, 0($s7)
      addi $s7, $s7, 1                          # aggiungo il carattere " "
  cipher_e_next:
    addi $t0, $t0, 1                            # i++
    j cipher_e_loop
  cipher_e_exit:
    li $t0, 0
    la $t1, temp_buffer
    la $t4, output_buffer

    copy_loop:
      add $t2, $t1, $t0
      lb $t3, 0($t2)
      sb $zero, 0($t2)                          #
      beq $t3, $zero, copy_loop_exit
      add $t5, $t4, $t0
      sb $t3, 0($t5)
      addi $t0, $t0, 1
      j copy_loop
    copy_loop_exit:

    la $v0, output_buffer
    move $s1, $t0                               # l'algoritmo non preserva la lunghezza della stringa, percio' e' da aggiornare
    j cipher_next


###############################################################################################################################


decipher_a:
  li $a2, 0
  li $a3, 0
_decipher_a:
  li $s6, -4
  j _cipher_a

decipher_b:
  li $a2, 0
  li $a3, 1
  j _decipher_a

decipher_c:
  li $a2, 1
  li $a3, 1
  j _decipher_a

decipher_d:
  li $a2, 1
  j _cipher_d

decipher_e:
  move $t0, $a0
  li $t6, 0                                     # $t6 = indice massimo
  li $t7, 0                                     # $t7 = totale
  li $t8, 0                                     # $t8 = contatore esponente
  li $t9, 0                                     # $t9 = contatore operazioni stack

  decipher_e_loop:
    lb $t1, 0($t0)                              # $t1 = carattere da inserire nella stringa finale
    beq $t1, 0x00, decipher_e_exit              # termina il ciclo una volta raggiunto il carattere nullo
    addi $t0, $t0, 1

    de_push_loop:
      addi $t0, $t0, 1
      lb $t2, 0($t0)                            # $t2 = cifra indice

      addi $sp, $sp, -1
      sb $t2, 0($sp)                            # $t2 viene salvato nello stack
      addi $t9, $t9, 1

      addi $t0, $t0, 1
      lb $t2, 0($t0)
      beq $t2, 0x20, de_pop_loop                # termina il ciclo di inserzione delle cifre nello stack per passare
      beq $t2, 0x2D, de_pop_loop                # all'estrazione una volta incontrato uno tra i caratteri ' ' e '-'
      addi $t0, $t0, -1                         # altrimenti ripristino $t0 e continuo il ciclo
    j de_push_loop

    de_pop_loop:
      beq $t9, $zero, de_pop_loop_exit
      lb $t3, 0($sp)                            # $t3 = cifra stack
      addi $sp, $sp, 1
      addi $t9, $t9, -1

      move $a2, $t8
      addi $t8, $t8, 1

      # il codice seguente restituisce il risultato di 10^($a2) nel registro $v0
      li $a3, 10
      li $v0, 10

      pow_loop:
        addi $a2, $a2, -1
        beq $a2, $zero, pow_exit
        blt $a2, $zero, pow_zero
        mult  $v0, $a3
        mflo  $v0
        j pow_loop
      pow_zero:
        li $v0, 1
      pow_exit:
        li $a3, 0

      addi $t3, $t3, -48                        # ottengo il valore numerico della cifra
      mult $t3, $v0
      mflo $t3                                  # cifra = cifra * 10 ^ $t8; $t8 e' l'indice posizionale della cifra
      add $t7, $t7, $t3                         # totale = totale + cifra
    j de_pop_loop

    de_pop_loop_exit:
      add $t3, $s7, $t7                         # $t3 = &output_buffer + indice
      sb $t1, 0($t3)

      slt $t4, $t7, $t6                         # controllo se l'indice e' minore del massimo
      bne $t4, $zero, decipher_e_next
      move $t6, $t7
    decipher_e_next:
      li $t7, 0
      li $t8, 0
      li $t9, 0                                 # ripristino i registri temporanei $t7, $t8, $t9

      beq $t2, 0x2D, de_push_loop               # se il prossimo carattere e' '-', passo al prossimo indice
      addi $t0, $t0, 1                          # altrimenti il prossimo carattere e' ' ', pertanto ritorno
      beq $t2, 0x20, decipher_e_loop            # al ciclo iniziale
  decipher_e_exit:
    la $v0, output_buffer
    addi $t6, $t6, 1
    move $s1, $t6
  j decipher_next


###############################################################################################################################


error_io:
  li $v0, 4
  la $a0, error_io_msg
  syscall
  j exit

error_key:
  li $v0, 4
  la $a0, error_key_msg
  syscall
  j exit
