# TP1 - Calculatrice RISC-V RV64I
# Auteur : Kalkoye Soumana Dit Fodo Myriam
# Code permanent : KALM78350609 (groupe 050)
#
# Ce programme implémente une calculatrice simple qui lit des caractères
# un par un et effectue des opérations arithmétiques (+, -, *, /, %) entre entiers.
# Les résultats sont stockés en mémoire et affichés à la fin avec ‘q’.
# Le programme gère les erreurs suivantes :
#   E0 - caractère invalide,
#   E1 - résultat négatif (non autorisé),
#   E2 - division ou modulo par zéro.


# Point d'entrée du programme : initialisation des registres principaux
main:
    li s0, 0x10000000   # adresse base pour stockage
    mv s1, s0           # pointeur courant
    li s2, 0            # compteur de résultats
    li s3, 0            # indicateur d'erreur division
    li s4, 0            # mode ignore (sauf E2)
    j debut_nouveau_calcul

# Prépare les registres pour un nouveau calcul
debut_nouveau_calcul:
    li t0, 0            # réinitialiser résultat
    li s3, 0            # reset flag erreur
    li s4, 0            # reset mode ignore
    j lire_caractere

# Lecture d'un caractère d'entrée
lire_caractere:
    li a7, 12
    ecall
    mv t1, a0
    beqz t1, terminer_programme

# Vérifier si on est en mode erreur E2
    bnez s4, mode_erreur_e2
    j analyser_caractere

# En mode erreur E2, on ignore tout sauf / et %
mode_erreur_e2:
    li t2, 47           # '/'
    beq t1, t2, traiter_operateur
    li t2, 37           # '%'
    beq t1, t2, traiter_operateur
    li t2, 61           # '='
    beq t1, t2, sauvegarder_resultat
    li t2, 113          # 'q'
    beq t1, t2, terminer_programme
    j lire_caractere

# Déterminer la nature du caractère lu (chiffre, opérateur, espace, etc.)
analyser_caractere:
    li t2, 48           # ASCII '0'
    li t3, 57           # ASCII '9'
    blt t1, t2, tester_operateur
    ble t1, t3, construire_nombre
    j tester_operateur

# Convertir un chiffre ASCII en entier et construire un nombre
construire_nombre:
    sub t1, t1, t2      # convertir ASCII en valeur
    li t4, 10
    mv t3, t0
    li t0, 0
    beqz t3, ajouter_chiffre
    j multiplier_par_10
    
# Multiplie l’ancien nombre par 10 (construction décimale)
multiplier_par_10:         
    slli t0, t3, 3           
    add t0, t0, t3           
    add t0, t0, t3          
    j ajouter_chiffre


ajouter_chiffre:
    add t0, t0, t1
    j lire_caractere

# Tester les opérateurs et caractères spéciaux
tester_operateur:
    # Ignorer espaces et caractères de contrôle
    li t2, 32           # espace
    beq t1, t2, lire_caractere
    li t2, 9            # tab
    beq t1, t2, lire_caractere
    li t2, 10           # newline
    beq t1, t2, lire_caractere
    li t2, 13           # carriage return
    beq t1, t2, lire_caractere

# Caractères spéciaux : '=' pour afficher, 'q' pour quitter
    li t2, 61           # '='
    beq t1, t2, sauvegarder_resultat
    li t2, 113          # 'q'
    beq t1, t2, terminer_programme

# Vérifie si c’est un opérateur arithmétique (+ - * / % x)
    li t2, 43           # '+'
    beq t1, t2, traiter_operateur
    li t2, 45           # '-'
    beq t1, t2, traiter_operateur
    li t2, 42           # '*'
    beq t1, t2, traiter_operateur
    li t2, 120          # 'x'
    beq t1, t2, traiter_operateur
    li t2, 47           # '/'
    beq t1, t2, traiter_operateur
    li t2, 37           # '%'
    beq t1, t2, traiter_operateur

    j erreur_caractere_invalide # Si aucun cas reconnu → erreur E0

# Traitement d'un opérateur valide
traiter_operateur:
    bnez s4, lire_deuxieme_operande
    mv t5, t0           
    li t0, 0            
    mv t6, t1           
    j lire_deuxieme_operande

# Lecture du second opérande
lire_deuxieme_operande:
    li a7, 12
    ecall
    mv t1, a0
    beqz t1, terminer_programme

    bnez s4, mode_erreur_e2

# Ignorer espaces
    li t2, 32
    beq t1, t2, lire_deuxieme_operande
    li t2, 9
    beq t1, t2, lire_deuxieme_operande
    li t2, 10
    beq t1, t2, lire_deuxieme_operande
    li t2, 13
    beq t1, t2, lire_deuxieme_operande

# Tester si chiffre
    li t2, 48
    li t3, 57
    blt t1, t2, executer_operation
    bgt t1, t3, executer_operation

# Construire le nombre
    sub t1, t1, t2
    li t4, 10
    mv t3, t0
    li t0, 0
    beqz t3, finir_construction
    j boucle_multiplication

boucle_multiplication:
    beqz t4, finir_construction
    add t0, t0, t3
    addi t4, t4, -1
    j boucle_multiplication

finir_construction:
    add t0, t0, t1
    j lire_deuxieme_operande

# Exécution de l'opération arithmétique
executer_operation:
    li t2, 43           
    beq t6, t2, operation_addition
    li t2, 45           
    beq t6, t2, operation_soustraction
    li t2, 42           
    beq t6, t2, operation_multiplication
    li t2, 120          
    beq t6, t2, operation_multiplication
    li t2, 47           
    beq t6, t2, operation_division
    li t2, 37           
    beq t6, t2, operation_modulo
    j verifier_suite

operation_addition:
    bnez s3, verifier_suite
    add t0, t5, t0
    j verifier_suite

operation_soustraction:
    bnez s3, verifier_suite
    sub t0, t5, t0
    bltz t0, erreur_negatif
    j verifier_suite

operation_multiplication:
    bnez s3, verifier_suite
    mv t4, t0
    li t0, 0
    beqz t4, verifier_suite
    j boucle_mult

boucle_mult:
    beqz t4, verifier_suite
    add t0, t0, t5
    addi t4, t4, -1
    j boucle_mult

operation_division:
    mv t4, t0
    beqz t4, division_par_zero
    bnez s4, verifier_suite
    mv t0, t5
    li t2, 0
    j boucle_division
    
boucle_division:
    blt t0, t4, fin_division
    sub t0, t0, t4
    addi t2, t2, 1
    j boucle_division

fin_division:
    mv t0, t2
    j verifier_suite

division_par_zero:
    li s3, 1
    li s4, 1
    li t0, -1
    sw t0, 0(s1)
    addi s1, s1, 4
    addi s2, s2, 1
    j verifier_suite

operation_modulo:
    mv t4, t0
    beqz t4, modulo_par_zero
    bnez s4, verifier_suite
    mv t0, t5
    j boucle_modulo

boucle_modulo:
    blt t0, t4, verifier_suite
    sub t0, t0, t4
    j boucle_modulo

modulo_par_zero:
    li s3, 1
    li s4, 1
    li t0, -1
    sw t0, 0(s1)
    addi s1, s1, 4
    addi s2, s2, 1
    j verifier_suite

# Vérifier le caractère suivant
verifier_suite:
    li t2, 61           # '='
    beq t1, t2, sauvegarder_resultat
    li t2, 113          # 'q'
    beq t1, t2, terminer_programme

# Tester si autre opérateur
    li t2, 43
    beq t1, t2, continuer_calcul
    li t2, 45
    beq t1, t2, continuer_calcul
    li t2, 42
    beq t1, t2, continuer_calcul
    li t2, 120
    beq t1, t2, continuer_calcul
    li t2, 47
    beq t1, t2, continuer_calcul
    li t2, 37
    beq t1, t2, continuer_calcul
    j erreur_caractere_invalide

continuer_calcul:
    mv t5, t0
    li t0, 0
    mv t6, t1
    j lire_deuxieme_operande

# Sauvegarde du résultat
sauvegarder_resultat:
    li s4, 0
    li t2, -1
    beq t0, t2, stocker_e2
    sw t0, 0(s1)
    addi s1, s1, 4
    addi s2, s2, 1
    j debut_nouveau_calcul

stocker_e2:
    li s4, 0
    sw t0, 0(s1)
    addi s1, s1, 4
    j debut_nouveau_calcul
  

# Gestion erreur caractère invalide
erreur_caractere_invalide:
    mv s1, s0
    j boucle_affichage_e0

boucle_affichage_e0:
    beqz s2, afficher_e0
    lw a0, 0(s1)
    li a7, 1
    ecall
    li a0, 10
    li a7, 11
    ecall
    addi s1, s1, 4
    addi s2, s2, -1
    j boucle_affichage_e0

afficher_e0:
    li a0, 69           # 'E'
    li a7, 11
    ecall
    li a0, 48           # '0'
    li a7, 11
    ecall
    li a0, 10
    li a7, 11
    ecall
    li a7, 10
    ecall

# Gestion erreur résultat négatif
erreur_negatif:
    mv s1, s0
    j boucle_affichage_e1

boucle_affichage_e1:
    beqz s2, afficher_e1
    lw a0, 0(s1)
    li a7, 1
    ecall
    li a0, 10
    li a7, 11
    ecall
    addi s1, s1, 4
    addi s2, s2, -1
    j boucle_affichage_e1

afficher_e1:
    li a0, 69           # 'E'
    li a7, 11
    ecall
    li a0, 49           # '1'
    li a7, 11
    ecall
    li a0, 10
    li a7, 11
    ecall
    li a7, 10
    ecall

# Terminer le programme et afficher tous les résultats
terminer_programme:
    mv s1, s0
    li a0, 10
    li a7, 11
    ecall
    j affichage_final

affichage_final:
    beqz s2, afficher_courant
    lw a0, 0(s1)
    li t2, -1
    beq a0, t2, afficher_erreur_e2
    li a7, 1
    ecall
    j nouvelle_ligne

afficher_erreur_e2:
    li a0, 69           # 'E'
    li a7, 11
    ecall
    li a0, 50           # '2'
    li a7, 11
    ecall

nouvelle_ligne:
    li a0, 10
    li a7, 11
    ecall
    addi s1, s1, 4
    addi s2, s2, -1
    j affichage_final

afficher_courant:
    beqz t0, sortie_finale
    mv a0, t0
    li a7, 1
    ecall
    li a0, 10
    li a7, 11
    ecall

sortie_finale:
    li a7, 10
    ecall